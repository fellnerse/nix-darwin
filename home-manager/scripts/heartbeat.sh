# Scheduled agent check (replaces herdr-mobile's heartbeats). Runs agy (Antigravity CLI) headless;
# stays silent on HEARTBEAT_OK, otherwise opens the conversation as a herdr-app tab
# and emails the answer. Configured via HB_NAME, HB_CWD, HB_PROMPT_FILE, HB_MAIL_FROM, HB_MAIL_TO.

# agy and herdr-core live outside nix; gh/git for the PRs the agent opens
export PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:$PATH"

state="$HOME/.local/state/heartbeat/$HB_NAME"
json="$state/last.json"
out="$state/last.txt"
mkdir -p "$state"
cd "$HB_CWD"

for attempt in 1 2 3; do
  rc=0
  agy --dangerously-skip-permissions --print-timeout 1h --output-format json \
    -p "$(<"$HB_PROMPT_FILE")" >"$json" 2>"$state/last.err" || rc=$?
  if [ "$rc" -eq 0 ] && [ "$(jq -r .status "$json" 2>/dev/null)" != SUCCESS ]; then rc=1; fi
  # retry only Google being overloaded (429), not a used-up quota (that one says when it resets)
  if [ "$rc" -eq 0 ] || [ "$attempt" -eq 3 ] || ! grep -qw '429' "$json" "$state/last.err" ||
    grep -qiE 'quota will reset|exhausted your capacity|QUOTA_EXHAUSTED' "$json" "$state/last.err"; then break; fi
  sleep 10m
done
conv=$(jq -r '.conversation_id // empty' "$json" 2>/dev/null || true)

if [ "$rc" -eq 0 ]; then
  jq -r .response "$json" >"$out"
  # a line that is only the sentinel; the model may add whitespace around it
  if grep -qx '[[:space:]]*HEARTBEAT_OK[[:space:]]*' "$out"; then
    echo "HEARTBEAT_OK"
    exit 0
  fi
else
  { echo "Heartbeat $HB_NAME failed (agy exit $rc, attempt $attempt)"; echo; tail -n 40 "$state/last.err" "$json"; } >"$out"
fi
cat "$out"

layout() { # herdr-app's sidebar/tab layout doc; with a JSON arg {value, version}: write it
  if [ $# -eq 0 ]; then
    jq -cn '{jsonrpc: "2.0", id: 1, method: "doc.get", params: {name: "herdr-app"}}'
  else
    jq -c '{jsonrpc: "2.0", id: 1, method: "doc.set", params: ({name: "herdr-app"} + .)}' <<<"$1"
  fi | herdr-core connect
}

tab=""
if [ -n "$conv" ]; then
  # join the herdr-app space for this folder if there is one
  space=$(layout | jq -r --arg f "$HB_CWD" 'first(.result.value.spaces[]? | select(.folder == $f) | .id) // empty')
  labels=()
  [ -n "$space" ] && labels=(--label "herdr.space=$space")
  addr=$(herdr-core run --json --bg --no-parent --keep --name "hb-$HB_NAME-$(date +%m%d-%H%M)" \
    --cwd "$HB_CWD" "${labels[@]}" agy --conversation "$conv" | jq -r .address)
  tab="🩺 heartbeat $(date '+%m-%d %H:%M')"
  # the app adds the tab on its own shortly after; then name it. Version-checked, so retry on a race.
  for _ in $(seq 15); do
    sleep 1
    req=$(layout | jq -c --arg t "$addr" --arg n "$tab" '.result | select(
        any(.value.spaces[]?.tabs[]?; any(.. | .terminal? // empty; . == $t))) |
      {version, value: (.value | .spaces[].tabs[] |= (if any(.. | .terminal? // empty; . == $t) then .name = $n else . end))}')
    if [ -n "$req" ] && layout "$req" | jq -e '.result' >/dev/null; then break; fi
  done
  echo "opened herdr-app tab '$tab' ($addr)"
fi

key_file="$HOME/.config/heartbeat/resend-api-key"
if [ ! -r "$key_file" ]; then
  echo "no $key_file, skipping email"
  exit 0
fi
subject=$(grep -m1 -v '^[[:space:]]*$' "$out" | tr -d '"' | cut -c1-120)
body="$(<"$out")${tab:+$'\n\n'herdr-app tab: $tab}"
jq -n --arg from "$HB_MAIL_FROM" --arg to "$HB_MAIL_TO" --arg subject "[heartbeat] $subject" --arg text "$body" \
  '{from: $from, to: [$to], subject: $subject, text: $text}' |
  curl -fsS https://api.resend.com/emails -H 'Content-Type: application/json' \
    -H @<(printf 'Authorization: Bearer %s\n' "$(<"$key_file")") -d @- >/dev/null # header via fd, so the key never shows in ps
echo "emailed $HB_MAIL_TO"
