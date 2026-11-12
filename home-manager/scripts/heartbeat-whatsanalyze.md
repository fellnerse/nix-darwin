Run /live-web-stats-check, including its memory steps: read the earlier findings first, save new ones at the end.

Act on what you find:
- A confirmed bug with a clear root cause and a small fix: fix it. Never in /root/projects/whatsanalyze itself - cut a worktree at /root/.herdr/worktrees/whatsanalyze/<branch> off origin/dev, commit, push, and open a PR against dev. Do not merge it. Put the PR number in the finding's memory.
- Noise, or a cluster whose cause is still unclear: memory only, no code.
- Before fixing, check the memory and open PRs, so a bug that already has a PR is not fixed twice.

Then answer:
- If all checks pass and there is nothing new, output ONLY:
  HEARTBEAT_OK
- Otherwise, start with ONE headline line saying what you found and what you did about it, e.g.
  "New crash in WordCloud.vue on chart unmount - fixed in PR #463"
  That line becomes the email subject, so lead with the finding, never with "Audit complete" or "Summary:".
  Then the details: what broke, where (URL/file), root cause, and the PR you opened, if any.
