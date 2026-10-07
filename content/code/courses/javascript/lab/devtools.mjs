// devtools.mjs: what page.mjs needs to pause, step and measure a page. It
// asks Chromium through the Chrome DevTools Protocol, the same channel the
// developer tools panel uses. page.mjs loads it when it sits beside it.
//
//   --break F:LINE   pause at a line, print the stack and the local scope
//   --break debugger pause only at `debugger;` statements in the page
//   --break uncaught pause where an exception nobody catches is thrown
//   --if COND        only pause there when COND is true (a conditional breakpoint)
//   --step KIND      after a pause, step over|into|out and print again
//   --profile        record a CPU profile and print where the busy time went,
//                    by function: its own time, not the time of what it called
//   --waterfall      at the end, every request on a time line from the first
//                    one, rounded to 100 ms: when it started and how long it
//                    took, drawn as a bar of # (one per 100 ms)
import path from "node:path";

// A value as the Scope pane draws it: an object with its first properties,
// an array with its length, an element by its tag.
function shown(v) {
  if (!v) return "(uninitialised)";
  if (v.type === "undefined") return "undefined";
  if (v.type === "string") return JSON.stringify(v.value);
  if (v.type !== "object" || v.subtype === "null") return v.description ?? String(v.value);
  const pv = v.preview;
  if (!pv || v.subtype === "node") return v.description;
  const item = (p) => (p.type === "string" ? JSON.stringify(p.value) : p.type === "object" ? "{…}" : p.value);
  const more = pv.overflow ? ", …" : "";
  if (v.subtype === "array") return `${v.description} [${pv.properties.map(item).join(", ")}${more}]`;
  return `{${pv.properties.map((p) => `${p.name}: ${item(p)}`).join(", ")}${more}}`;
}

export async function attach({ context, page, opt, say, origin }) {
  const timeline = [];
  if (opt.waterfall) {
    const t = new Map();
    page.on("request", (r) => t.set(r, { start: Date.now(), r }));
    const end = (r) => { const e = t.get(r); if (e) { e.end = Date.now(); timeline.push(e); } };
    page.on("requestfinished", end);
    page.on("requestfailed", end);
  }

  let cdp;
  if (opt.break || opt.profile) cdp = await context.newCDPSession(page);

  async function scopeOf(frame) {
    const out = [];
    for (const s of frame.scopeChain) {
      if (s.type === "global") continue;
      const { result } = await cdp.send("Runtime.getProperties", { objectId: s.object.objectId, ownProperties: true, generatePreview: true });
      const vars = result.map((p) => `${p.name} = ${shown(p.value)}`);
      out.push(`  ${s.type} scope: ${vars.join(", ") || "(empty)"}`);
    }
    return out;
  }

  if (opt.break) {
    const [bf, bl] = opt.break.split(":");
    const urls = new Map();
    cdp.on("Debugger.scriptParsed", (ev) => urls.set(ev.scriptId, ev.url));
    await cdp.send("Debugger.enable");
    if (opt.break === "uncaught") await cdp.send("Debugger.setPauseOnExceptions", { state: "uncaught" });
    else if (opt.break !== "debugger")
      await cdp.send("Debugger.setBreakpointByUrl", { lineNumber: Number(bl) - 1, urlRegex: `${bf.replace(/[.]/g, "\\.")}$`, condition: opt.if ?? "" });
    const steps = [...opt.step];
    cdp.on("Debugger.paused", async (ev) => {
      const top = ev.callFrames[0];
      const at = (f) => `${path.basename(urls.get(f.location.scriptId) ?? "")}:${f.location.lineNumber + 1}`;
      say(`paused at ${at(top)}${ev.reason === "exception" || ev.reason === "promiseRejection" ? `, on ${ev.data?.description?.split("\n")[0]}` : ""}`);
      say("  call stack: " + ev.callFrames.map((f) => `${f.functionName || "(anonymous)"} ${at(f)}`).join("  <  "));
      for (const l of await scopeOf(top)) say(l);
      const next = steps.shift();
      if (next) { say(`-- step ${next}`); await cdp.send(`Debugger.step${next[0].toUpperCase()}${next.slice(1)}`); }
      else await cdp.send("Debugger.resume");
    });
  }

  if (opt.profile) {
    await cdp.send("Profiler.enable");
    await cdp.send("Profiler.setSamplingInterval", { interval: 100 });
    await cdp.send("Profiler.start");
  }

  async function finish() {
    if (opt.profile) {
      const { profile } = await cdp.send("Profiler.stop");
      const self = new Map();
      const byId = new Map(profile.nodes.map((n) => [n.id, n]));
      const dt = profile.timeDeltas;
      profile.samples.forEach((id, i) => {
        const n = byId.get(id);
        const name = n.callFrame.functionName || `(${n.callFrame.url ? "anonymous" : n.callFrame.functionName || "program"})`;
        const where = n.callFrame.url ? `${path.basename(n.callFrame.url)}:${n.callFrame.lineNumber + 1}` : "";
        const k = `${name}  ${where}`.trim();
        self.set(k, (self.get(k) || 0) + (dt[i] || 0));
      });
      // Time the page spent waiting for something to do is not time anything
      // cost, so the shares are of the time the browser was busy.
      self.delete("(idle)");
      const busy = [...self.values()].reduce((a, b) => a + b, 0);
      say("share  self time  function");
      for (const [k, us] of [...self].sort((a, b) => b[1] - a[1]).slice(0, 5))
        say(`${String(Math.round((100 * us) / busy)).padStart(4)}%  ${(us / 1000).toFixed(0).padStart(6)} ms  ${k}`);
      say(`       ${(busy / 1000).toFixed(0).padStart(6)} ms  busy in total`);
    }
    if (opt.waterfall) {
      const first = Math.min(...timeline.map((e) => e.start));
      const tenth = (ms) => Math.round(ms / 100);
      say("start  took    request");
      for (const e of timeline.sort((a, b) => a.start - b.start)) {
        const s0 = tenth(e.start - first), d = tenth(e.end - e.start);
        const what = `${e.r.method()} ${e.r.url().replace(origin, "")}`;
        say(`${String(s0 * 100).padStart(5)}  ${String(d * 100).padStart(4)}  ${what.padEnd(28)} ${" ".repeat(s0)}${"#".repeat(Math.max(d, 1))}`);
      }
    }
  }
  return { finish };
}
