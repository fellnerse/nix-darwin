// The flock: every agent is a sheep (sheep.js) standing in a field that shrinks
// as the subscription is spent, with the usage windows listed underneath.
// Deliberately small and built only on herdr.d.ts, so Herdr updates to the
// shipped `agents` mod never leave this one behind.

import { View, div, image, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { agents, run, theme, setAgentOrder, appHome } from "herdr";
import * as fs from "fs/promises";
import { sheepSvg, sheepKey, pastureOf } from "./sheep.js";

// The SheepIt gateway on the herdr box; it reads the subscription windows.
const QUOTA_URL = "https://herdr.tail401ae4.ts.net/api/queue/quota";
const RANK = { blocked: 4, done: 3, working: 2, idle: 1 };
const WINDOWS = { five_hour: "5h", seven_day: "week" };
const BAR = 96;
const RAIL = 160; // narrower than this the sidebar is a rail: sheep only

export default class Flock extends View {
  init(_props, cx) {
    this.written = new Set();
    this.quota = null;
    this.width = 268;
    const poll = (cx) => cx.spawn(async (cx) => {
      try {
        this.quota = await (await fetch(QUOTA_URL)).json();
        cx.notify();
      } catch {} // no reading, no field
    });
    poll(cx);
    cx.timer.every(60000, poll);
  }

  // The agent's sheep: a generated SVG in sheep-cache/, written once per look.
  // Until the file exists (first render of a new look) there is no picture.
  sheep(cx, t, a) {
    const spec = { status: a.status, seed: a.tab, pasture: pastureOf(this.quota, a.program?.key), edge: a.focused ? t.selected : t.chrome };
    const key = sheepKey(spec);
    if (!this.written.has(key)) {
      this.written.add(key);
      cx.spawn(async (cx) => {
        const dir = `${appHome()}/sheep-cache`;
        await fs.mkdir(dir, { recursive: true });
        await fs.writeFile(`${dir}/${key}.svg`, sheepSvg(spec));
        cx.notify();
      });
      return div().w(44).h(36).flex_none();
    }
    const img = image(`sheep-cache/${key}.svg`).w(44).h(36).flex_none();
    return a.status === "blocked" ? img.loop("opacity", { from: 0.55, to: 1, period: 1200 }) : img;
  }

  status(t, a) {
    if (a.status === "working") return svg("mods/workspace-chrome/spinner.svg").size(12).mx(1).flex_none().text_color(t.working).spin(900);
    if (a.status === "blocked") return div().flex_none().px(6).h(18).rounded(5).bg(t.blocked + "26").text_size(10.5).font_semibold().text_color(t.blocked).flex().items_center().child("Needs you");
    if (a.status === "idle") return div().size(7).mx(3).flex_none().rounded(4).border(1.5).border_color(t.idle);
    return div().size(7).mx(3).flex_none().rounded(4).bg(t.done);
  }

  // One line per subscription, a bar per window: what is left and when it comes back.
  usage(t) {
    const reset = (iso) => {
      const at = iso ? new Date(iso) : null;
      if (!at || isNaN(at)) return "";
      return (at - Date.now()) / 3600000 < 18
        ? at.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
        : `${at.getDate()}.${at.getMonth() + 1}.`;
    };
    const readings = (this.quota?.agents ?? []).filter((r) => r.ok && r.buckets?.length);
    return v_flex().flex_none().px(16).py(10).gap(8).border_t(1).border_color(t.border).text_size(11)
      .children(readings.map((r) => v_flex().gap(4)
        .child(div().text_color(t.dim).child(r.agent))
        .children(r.buckets.map((b) => {
          const used = b.expired ? 0 : Math.max(0, Math.min(100, b.utilization));
          const color = b.spent || used >= 100 ? t.blocked : b.warning ? t.working : "#4c9a5a";
          return h_flex().gap(8).items_center()
            .child(div().w(34).text_color(t.muted).child(WINDOWS[b.name] ?? b.name))
            .child(div().w(BAR).h(5).rounded(3).bg(t.raised).flex_none()
              .child(div().h(5).rounded(3).bg(color).w(Math.max(used > 0 ? 3 : 0, Math.round((BAR * used) / 100)))))
            .child(div().w(30).text_color(t.muted).text_right().child(`${Math.round(used)}%`))
            .child(div().flex_1().truncate().text_color(t.dim).text_right().child(reset(b.resets_at)));
        }))));
  }

  render(cx) {
    const t = theme();
    const rail = this.width < RAIL;
    // Most urgent first, then the one that changed most recently.
    const list = [...agents()].sort((x, y) => (RANK[y.status] ?? 0) - (RANK[x.status] ?? 0) || y.seq - x.seq);
    setAgentOrder(list.map((a) => a.address));

    const row = (a) => {
      const sheep = this.sheep(cx, t, a);
      const detail = /^\d+$/.test(a.tab_name ?? "") ? "" : a.tab_name;
      return h_flex()
        .id(`ag-${a.address}`)
        .px(rail ? 0 : 8)
        .h(40)
        .flex_none()
        .rounded(8)
        .items_center()
        .justify_center()
        .gap(9)
        .when(a.focused, (el) => el.bg(t.selected))
        .cursor_pointer()
        .hover((s) => s.bg(t.hover))
        .tooltip(`${a.space_name} · ${a.status}`)
        .on_click(() => run("pane.focus", { pane: a.pane }))
        .child(sheep)
        .when(!rail, (el) => el
          .child(h_flex().flex_1().min_w(0).gap(5).items_center()
            .child(div().min_w(0).max_w(detail ? 110 : 200).truncate().text_color(a.status === "idle" && !a.focused ? t.muted : t.foreground).child(a.space_name))
            .when(Boolean(detail), (el) => el.child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(`· ${detail}`))))
          .child(this.status(t, a)));
    };

    return v_flex()
      .id("flock")
      .size_full()
      .min_h(0)
      .bg(t.chrome)
      .border_t(1)
      .border_color(t.border)
      .text_size(13)
      .on_size_change((size, cx) => {
        const was = this.width < RAIL;
        this.width = size.width;
        if (was !== this.width < RAIL) cx.notify();
      })
      .when(!rail, (el) => el.child(
        h_flex().px(16).h(41).pt(14).pb(5).flex_none().items_center()
          .child(div().text_size(11.5).font_medium().text_color(t.dim).child("Flock"))))
      .when(list.length === 0 && !rail, (el) => el.child(
        div().px(12).text_size(12).text_color(t.dim).child("No sheep yet. Agents show up here when they report their status.")))
      .child(v_flex().id("ag-list").flex_1().min_h(0).px(rail ? 0 : 8).overflow_y_scrollbar().mode("always").children(list.map(row)))
      .when(!rail && Boolean(this.quota), (el) => el.child(this.usage(t)));
  }
}
