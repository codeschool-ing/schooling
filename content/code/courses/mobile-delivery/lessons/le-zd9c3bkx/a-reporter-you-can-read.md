---
title: A crash reporter you can read
version: 1
---

**A crash reporter fits in forty lines, and writing one is the fastest way to know what the real ones
send.** This one runs in Node instead of on a phone, but it has the same four parts as the last
section: it starts first, keeps breadcrumbs, writes a report when the process dies, and sends what
is on disk the next time it starts.

## The reporter

Save this as `reporter.ts` in `~/planner`:

```schooling-example
{"language": "typescript", "file": "reporter.ts", "parts": [{"code": "// reporter.ts: a crash reporter in the shape every mobile one has: save on crash, send on next launch\nimport { randomUUID } from \"node:crypto\";\nimport { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from \"node:fs\";\nimport { platform, release } from \"node:os\";\n\ntype Options = { version: string; build: number; endpoint: string };\nconst DIR = \"crashes\";\nconst crumbs: string[] = [];", "note": "Reports wait in a folder named `crashes`. The breadcrumbs live in memory, because they only matter if the app dies with them."}, {"code": "function installId(): string {\n  if (!existsSync(\"install-id\")) writeFileSync(\"install-id\", randomUUID());\n  return readFileSync(\"install-id\", \"utf8\");\n}", "note": "A random identifier, made once and kept in a file: it counts installations without naming anybody."}, {"code": "export function breadcrumb(text: string) {\n  crumbs.push(text);\n  if (crumbs.length > 20) crumbs.shift();\n}", "note": "The last twenty things the app said it did. Older ones fall off."}, {"code": "async function sendPending(endpoint: string) {\n  if (!existsSync(DIR)) return;\n  for (const name of readdirSync(DIR).sort()) {\n    const body = readFileSync(`${DIR}/${name}`, \"utf8\");\n    try {\n      const res = await fetch(endpoint, { method: \"POST\", headers: { \"content-type\": \"application/json\" }, body });\n      if (res.ok) rmSync(`${DIR}/${name}`);\n    } catch {\n      // No network: the report stays on disk and goes with the next launch.\n    }\n  }\n}", "note": "Every report on disk is sent, and deleted only once the server has accepted it. Without a network, it waits for the launch after."}, {"code": "export async function start(o: Options) {\n  await sendPending(o.endpoint);\n  process.on(\"uncaughtException\", (err) => {\n    const report = {\n      version: o.version, build: o.build, os: `${platform()} ${release()}`,\n      install: installId(), at: new Date().toISOString(), breadcrumbs: crumbs,\n      error: { type: err.name, message: err.message, stack: err.stack?.split(\"\\n\").slice(1, 4).map((l) => l.trim()) },\n    };\n    mkdirSync(DIR, { recursive: true });\n    writeFileSync(`${DIR}/${Date.now()}.json`, JSON.stringify(report, null, 2));\n    process.exit(1);\n  });\n}", "note": "At start: send what the last crash left, then wait for the next one. On a crash: write the report, synchronously, and exit. Nothing is sent from a dying process."}]}
```

## An app to crash, and a server to receive

The "app" is the planner's Statistics screen with a bug: it looks up a course that is not in the
list. Save this as `app.ts`:

```typescript
// app.ts: the planner, launched like an app, with the crash reporter started first
import { breadcrumb, start } from "./reporter.ts";

await start({ version: "1.5.0", build: 1050003, endpoint: "http://127.0.0.1:4312/crashes" });
const screen = process.argv[2] ?? "week";
breadcrumb(`open ${screen}`);

const courses: Record<string, { sessions: number[] }> = { spanish: { sessions: [30, 30] } };
if (screen === "statistics") {
  breadcrumb("tap Statistics for guitar");
  console.log(courses["guitar"].sessions.length);
}
console.log(`the planner showed ${screen}`);
```

And the server, which writes one line per report it receives. Save this as `collector.ts`, and start
it in a second terminal with `node collector.ts`:

```typescript
// collector.ts: the server a crash reporter sends to, reduced to printing what arrives
import { createServer } from "node:http";
import { appendFileSync } from "node:fs";

createServer((req, res) => {
  if (req.method !== "POST") return res.writeHead(404).end();
  let body = "";
  req.on("data", (chunk) => (body += chunk));
  req.on("end", () => {
    const r = JSON.parse(body);
    appendFileSync("collected.log", `${r.version} (${r.build}) ${r.error.type}: ${r.error.message} | ${r.breadcrumbs.join(" > ")}\n`);
    res.writeHead(201).end();
  });
}).listen(4312, "127.0.0.1");
```

## The crash, the report, and the next launch

```
ana@dev:~/planner$ node app.ts statistics; echo "exit status $?"
exit status 1
ana@dev:~/planner$ cat crashes/*.json
{
  "version": "1.5.0",
  "build": 1050003,
  "os": "linux 6.18.44-fc-v185",
  "install": "883eb634-dd16-40b2-8b0a-23164a6fd7c2",
  "at": "2026-10-30T18:50:39.606Z",
  "breadcrumbs": [
    "open statistics",
    "tap Statistics for guitar"
  ],
  "error": {
    "type": "TypeError",
    "message": "Cannot read properties of undefined (reading 'sessions')",
    "stack": [
      "at file:///home/ana/planner/app.ts:11:33"
    ]
  }
}
ana@dev:~/planner$ node app.ts week
the planner showed week
ana@dev:~/planner$ ls crashes; cat collected.log
1.5.0 (1050003) TypeError: Cannot read properties of undefined (reading 'sessions') | open statistics > tap Statistics for guitar
```

Read it in order. **The app printed nothing and exited with 1**: that is what a person sees, an app
that is gone. The report waited on disk. **The next launch sent it before showing anything**, the
week screen appeared, and the `crashes` folder was empty again.

## Reading the report as somebody deciding what to send

Every field there was chosen, and each one is a line in lesson 5's inventory:

- `install` is a **random identifier** made on the first crash and kept in a file. It counts people
  without naming them, and it changes if the app is reinstalled, which is the point.
- `os` came from the machine. On a phone it is the model and the system version, which is what
  lesson 8's rule needs to group crashes by device.
- `breadcrumbs` are **whatever the app wrote into them**. "tap Statistics for guitar" is harmless;
  a breadcrumb with the text a person typed into a search box is collecting it. Breadcrumbs are
  where personal data leaks into crash reports, more than anywhere else.
- The `stack` names a file path on the computer that built the code. On a phone it is a function in
  a minified or compiled build, and lesson 13 is how it becomes readable again.
