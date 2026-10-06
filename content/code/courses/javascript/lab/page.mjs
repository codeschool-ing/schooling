// page: open one of ana's pages in a real browser and print what its console
// said. It is how this course shows the browser in a terminal transcript.
//
//   page FILE.html [options]
//
// The browser is Chromium, headless, driven by Playwright. The page is served
// from ~/js at http://127.0.0.1:8080 by serve.mjs (with its /api/), so it has
// a real origin, as a page on the web would.
//
// WHAT IS THE LAB'S AND NOT THE BROWSER'S: the format of every line. A
// console.log prints its text as it is; console.warn and console.error are
// prefixed [warn] and [error]; an exception nobody caught is printed as
// "Uncaught" and its message, as DevTools prints it; and an action this tool
// performed is printed as "-- " and the action, so the transcript says what
// happened to the page and in which order.
//
// Options, applied in order after the page has loaded:
//   --do 'click SEL' | 'fill SEL TEXT' | 'press KEY' | 'focus SEL'
//        | 'wait MS' | 'reload' | 'newtab' | 'eval CODE'
//   --dom SEL        at the end, print SEL's outerHTML
//   --wait MS        how long to let timers run after the last action (300)
//   --geo LAT,LON    the position the browser reports, and permission for it
//   --grant PERM     grant a permission (notifications, geolocation)
//   --fresh          forget everything the profile stored (localStorage)
//   --break F:LINE   pause at a line, print the stack and the local scope
//   --step KIND      after a pause, step over|into|out and print again
//   --network        list every request the page made
//   --profile        record a CPU profile and print where the time went
import { chromium } from "playwright";
import { createServer } from "./serve.mjs";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const args = process.argv.slice(2);
const file = args.shift();
if (!file) { console.error("usage: page FILE.html [options]"); process.exit(2); }
const opt = { do: [], wait: 300, grant: [], step: [] };
while (args.length) {
  const a = args.shift();
  if (a === "--do") opt.do.push(args.shift());
  else if (a === "--dom") opt.dom = args.shift();
  else if (a === "--wait") opt.wait = Number(args.shift());
  else if (a === "--geo") opt.geo = args.shift().split(",").map(Number);
  else if (a === "--grant") opt.grant.push(args.shift());
  else if (a === "--fresh") opt.fresh = true;
  else if (a === "--break") opt.break = args.shift();
  else if (a === "--step") opt.step.push(args.shift());
  else if (a === "--network") opt.network = true;
  else if (a === "--profile") opt.profile = true;
  else { console.error(`page: unknown option ${a}`); process.exit(2); }
}

const root = process.cwd();
const server = createServer(root);
await new Promise((ok) => server.listen(8080, "127.0.0.1", ok));

const profileDir = path.join(os.homedir(), ".page-profile");
if (opt.fresh) fs.rmSync(profileDir, { recursive: true, force: true });
const context = await chromium.launchPersistentContext(profileDir, {
  headless: true,
  executablePath: process.env.PAGE_CHROMIUM || undefined,
  locale: "en-GB",
  timezoneId: process.env.TZ || "America/Sao_Paulo",
  ...(opt.geo ? { geolocation: { latitude: opt.geo[0], longitude: opt.geo[1] } } : {}),
});
const origin = "http://127.0.0.1:8080";
if (opt.geo) await context.grantPermissions(["geolocation"], { origin });
if (opt.grant.length) await context.grantPermissions(opt.grant, { origin });

const say = (s) => process.stdout.write(s + "\n");
function watch(page) {
  page.on("console", (m) => {
    const t = m.type();
    const text = m.text();
    if (t === "error") say(`[error] ${text}`);
    else if (t === "warning") say(`[warn] ${text}`);
    else say(text);
  });
  page.on("pageerror", (e) => say(`Uncaught ${String(e.message).startsWith(e.name) ? e.message : `${e.name}: ${e.message}`}`));
}

let page = context.pages()[0] || (await context.newPage());
watch(page);
const started = new Map();
if (opt.network) {
  page.on("request", (r) => started.set(r, Date.now()));
  page.on("requestfailed", (r) => say(`net  ${r.method()} ${r.url().replace(origin, "")}  failed: ${r.failure()?.errorText}`));
  page.on("response", async (r) => {
    const q = r.request();
    let size = "?";
    try { size = (await r.body()).length; } catch {}
    say(`net  ${q.method()} ${r.url().replace(origin, "")}  ${r.status()}  ${q.resourceType()}  ${size} B`);
  });
}

let cdp;
if (opt.break || opt.profile) cdp = await context.newCDPSession(page);

async function scopeOf(frame) {
  const out = [];
  for (const s of frame.scopeChain) {
    if (s.type === "global") continue;
    const { result } = await cdp.send("Runtime.getProperties", { objectId: s.object.objectId, ownProperties: true });
    const vars = result.map((p) => `${p.name} = ${p.value ? (p.value.description ?? JSON.stringify(p.value.value)) : "?"}`);
    out.push(`  ${s.type} scope: ${vars.join(", ") || "(empty)"}`);
  }
  return out;
}

if (opt.break) {
  const [bf, bl] = opt.break.split(":");
  await cdp.send("Debugger.enable");
  await cdp.send("Debugger.setBreakpointByUrl", { lineNumber: Number(bl) - 1, urlRegex: `${bf.replace(/[.]/g, "\\.")}$` });
  const steps = [...opt.step];
  cdp.on("Debugger.paused", async (ev) => {
    const top = ev.callFrames[0];
    say(`paused at ${path.basename(top.url)}:${top.location.lineNumber + 1}`);
    say("  call stack: " + ev.callFrames.map((f) => `${f.functionName || "(anonymous)"} ${path.basename(f.url)}:${f.location.lineNumber + 1}`).join("  <  "));
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

await page.goto(`${origin}/${file}`);
for (const action of opt.do) {
  say(`-- ${action}`);
  const [verb, ...rest] = action.split(" ");
  const sel = rest[0];
  const text = rest.slice(1).join(" ");
  if (verb === "click") await page.click(sel);
  else if (verb === "fill") await page.fill(sel, text);
  else if (verb === "press") await page.keyboard.press(sel);
  else if (verb === "focus") await page.focus(sel);
  else if (verb === "wait") await page.waitForTimeout(Number(sel));
  else if (verb === "reload") await page.reload();
  else if (verb === "newtab") { page = await context.newPage(); watch(page); await page.goto(`${origin}/${file}`); }
  else if (verb === "eval") { const r = await page.evaluate(rest.join(" ")); if (r !== undefined) say(String(r)); }
  else { say(`page: unknown action ${verb}`); }
}
await page.waitForTimeout(opt.wait);

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
  const total = [...self.values()].reduce((a, b) => a + b, 0);
  say("self time   function");
  for (const [k, us] of [...self].sort((a, b) => b[1] - a[1]).slice(0, 6))
    say(`${(us / 1000).toFixed(1).padStart(7)} ms  ${k}`);
  say(`${(total / 1000).toFixed(1).padStart(7)} ms  in total`);
}

if (opt.dom) {
  const html = await page.$eval(opt.dom, (e) => e.outerHTML).catch(() => `(no element matches ${opt.dom})`);
  say(html);
}
await context.close();
server.close();
