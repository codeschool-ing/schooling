---
title: The performance panel
version: 1
---

**Lighthouse says that the main thread was busy; the performance panel shows it busy.** It records
everything the browser did while you used a page, the network requests, the frames, and every task
on the main thread with what ran inside it, and draws it along time.

## Recording in the browser

In Chrome, or in any browser built on Chromium, open the developer tools and the **Performance** tab:

- **the record button** starts a recording; use the page as a person would, then stop it;
- **record and reload** reloads the page and records its load, which is what Lighthouse measures;
- **the settings** of the panel, the gear on its toolbar, slow the processor and the network down, as
  `--cpu` and `--slow` have done in this course.

What it draws, top to bottom:

- **Network**: every request as a bar along time, which is the waterfall of the section
  "Waterfalls";
- **Frames**: each frame the browser painted, and the gaps where it painted none;
- **Main**: the main thread's tasks, with what each one called stacked underneath it, the chart called a
  **flame chart**. A task of 50 milliseconds or more is a **long task** and
  is drawn with a red corner.

Click any block and the panel below says what it was: a script, a style calculation, a layout, a
paint, and how long it took. The panel also lists **insights** beside the recording, the same ones
Lighthouse reports, because since version 13 Lighthouse and the panel share them.

## The same recording from a program

**A recording is a file**, a *trace*, and the panel opens one: the Load profile button on its
toolbar, an arrow pointing up. So a trace can be recorded by a program, under conditions it repeats
exactly, and opened by a person. Playwright records traces in the same format.

`tools/trace.ts` records one while it loads a page and, optionally, clicks something, as
`tools/vitals.ts` does. It saves `trace.json` for the panel, and then reads the file itself and lists
the long tasks on the page's main thread, with the largest things inside each. Save it in `tools/`:

```schooling-example
{"language": "typescript", "file": "tools/trace.ts", "parts": [
 {"code": "// tools/trace.ts: record what the browser's main thread did while a page loaded\n// and was clicked, save it for the performance panel, and list the long tasks.\n//\n//   node tools/trace.ts URL [--cpu N] [--click SELECTOR]\n//\n// trace.json is the file the panel opens with its Load profile button.\nimport { chromium } from \"playwright\";\nimport { readFile } from \"node:fs/promises\";\n\nconst [url, ...rest] = process.argv.slice(2);\nconst option = (name: string) => (rest.includes(name) ? rest[rest.indexOf(name) + 1] : null);\nconst browser = await chromium.launch();\nconst page = await browser.newPage();\nconst cdp = await page.context().newCDPSession(page);\nif (option(\"--cpu\")) await cdp.send(\"Emulation.setCPUThrottlingRate\", { rate: Number(option(\"--cpu\")) });", "note": "What it is for and how to run it. The file it saves is what the panel opens."},
 {"code": "await browser.startTracing(page, { path: \"trace.json\", screenshots: true });\nawait page.goto(url, { waitUntil: \"networkidle\" });\nawait page.waitForTimeout(500);\nif (option(\"--click\")) {\n  await page.click(option(\"--click\")!);\n  await page.waitForTimeout(500);\n}\nawait browser.stopTracing();\nawait browser.close();", "note": "startTracing and stopTracing bracket the recording. screenshots adds the film strip the panel shows above the tracks."},
 {"code": "type Event = { name: string; ph: string; ts: number; dur?: number; pid: number; tid: number; args?: any };\nconst events: Event[] = JSON.parse(await readFile(\"trace.json\", \"utf8\")).traceEvents;\nconst main = events.find((e) => e.name === \"thread_name\" && e.args.name === \"CrRendererMain\"\n  && events.some((n) => n.name === \"navigationStart\" && n.pid === e.pid && n.tid === e.tid))!;\nconst start = events.find((e) => e.name === \"navigationStart\" && e.pid === main.pid && e.tid === main.tid)!.ts;\nconst mine = events.filter((e) => e.pid === main.pid && e.tid === main.tid && e.ph === \"X\" && e.dur);\nconst ms = (us: number) => Math.round(us / 1000);", "note": "A trace is one long list of events from every process and thread of the browser. Only the page's main thread matters here, and its clock starts at navigationStart."},
 {"code": "const names: Record<string, string> = {\n  ParseHTML: \"Parse HTML\", EvaluateScript: \"Evaluate script\", \"v8.evaluateModule\": \"Evaluate module\",\n  EventDispatch: \"Event\", FunctionCall: \"Function call\", TimerFire: \"Timer fired\",\n  UpdateLayoutTree: \"Recalculate style\", Layout: \"Layout\", Paint: \"Paint\", MinorGC: \"Minor GC\", MajorGC: \"Major GC\",\n};\nconst within = (e: Event, o: Event) => o.ts <= e.ts && o.ts + o.dur! >= e.ts + e.dur!;", "note": "The events the panel names inside a task, under the names it gives them. Times in a trace are microseconds."},
 {"code": "for (const task of mine.filter((e) => e.name === \"RunTask\" && e.dur! >= 50_000)) {\n  const named = mine.filter((e) => e.name in names && within(e, task));\n  const outer = named.filter((e) => !named.some((o) => o !== e && within(e, o) && o.dur! > e.dur!));\n  const parts = outer.filter((e) => e.dur! >= 5_000).sort((a, b) => b.dur! - a.dur!).map((e) =>\n    `${names[e.name]}${e.name === \"EventDispatch\" ? ` (${e.args.data.type})` : \"\"} ${ms(e.dur!)}`);\n  const other = task.dur! - outer.reduce((sum, e) => sum + e.dur!, 0);\n  console.log(`long task at ${ms(task.ts - start)} ms, ${ms(task.dur!)} ms: ${[...parts, `other ${ms(other)}`].join(\", \")}`);\n}", "note": "A task is long from 50 ms. Inside it, only the outermost named events count, because a function called by a click is part of the click; what no name covers is \"other\"."}
]}
```

The next section runs it.
