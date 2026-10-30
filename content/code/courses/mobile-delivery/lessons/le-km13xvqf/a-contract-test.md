---
title: A contract test
version: 1
---

**A contract test writes down what each supported version reads, and fails the server's build when
a response stops providing it.** The server's own tests check that it does what its developers meant
today. This one checks that it still does what an app compiled a year ago expects, which nobody on
the server team is thinking about when they rename a field.

## One file per version

Each version in the support window gets a file listing, for each endpoint it calls, the fields it
reads and what it expects of them: a type, or the list of values it knows how to draw. Make a folder
for them with `mkdir ~/planner/contracts`.

Save this in `~/planner/contracts` as `1.3.1.json`:

```json
{
  "GET /sessions": {
    "id": "string",
    "course": "string",
    "minutes": "number",
    "day": "string",
    "status": ["done", "planned"]
  }
}
```

1.5.2 reads the same fields and learnt one more status, `"skipped"`, when skipping a session became a
feature. Save this in `~/planner/contracts` as `1.5.2.json`:

```json
{
  "GET /sessions": {
    "id": "string",
    "course": "string",
    "minutes": "number",
    "day": "string",
    "status": ["done", "planned", "skipped"]
  }
}
```

In a real project these files are written from the app's code, by whoever changes how the app reads
a response, in the same pull request. Kotlin, Swift and React Native teams do the same thing with
different tools; Pact is a common one that records the contract from the client's own tests. The
idea is the same in all of them, and it fits in one script.

## The test

Save this as `contract.ts`. It takes the module that builds the server's responses, asks it for the
sessions, and checks every session against every version's file:

```schooling-example
{"language": "typescript", "file": "contract.ts", "parts": [{"code": "// contract.ts: every supported version's contract, checked against what the server would send\nimport { readdirSync, readFileSync } from \"node:fs\";\n\nconst { sessions } = await import(`./${process.argv[2]}`);\nconst body: Record<string, unknown>[] = sessions();", "note": "The module named on the command line builds the response. The test calls it directly, so no server has to run."}, {"code": "function problems(item: Record<string, unknown>, fields: Record<string, string | string[]>): string[] {\n  const found: string[] = [];\n  for (const [field, want] of Object.entries(fields)) {\n    const value = item[field];\n    if (value === undefined) found.push(`${field} is missing`);\n    else if (Array.isArray(want)) { if (!want.includes(value as string)) found.push(`${field} \"${value}\" is not one of ${want.join(\", \")}`); }\n    else if (typeof value !== want) found.push(`${field} is a ${typeof value}, not a ${want}`);\n  }\n  return found;\n}", "note": "Three ways to break a promise: the field is gone, it holds a value the version cannot draw, or it changed type. A field the file does not list is never checked, which is what lets the server add one."}, {"code": "let failed = 0;\nfor (const file of readdirSync(\"contracts\").sort()) {\n  const version = file.replace(/\\.json$/, \"\");\n  const fields = JSON.parse(readFileSync(`contracts/${file}`, \"utf8\"))[\"GET /sessions\"];\n  const broken = body.flatMap((item) => problems(item, fields).map((p) => `${item.id}: ${p}`));\n  console.log(`${version}  GET /sessions  ${broken.length ? \"BROKEN\" : \"ok\"}`);\n  for (const b of broken) console.log(`  ${b}`);\n  failed += broken.length;\n}\nprocess.exitCode = failed ? 1 : 0;", "note": "One line per version, every broken promise under it, and an exit status the pipeline can stop on."}]}
```

## Two changes to the server

The server's response for the week is built by a function, so the test can call it without starting
anything. Here are two proposals for the next server release.

The first adds `seconds` beside `minutes`, the expand step of the last section. Save this as
`api-additive.ts`:

```typescript
// api-additive.ts: adds seconds beside minutes; every old field stays as it was
export function sessions() {
  return [
    { id: "s-101", course: "statistics", minutes: 25, seconds: 1500, day: "2026-10-12", status: "done" },
    { id: "s-102", course: "python", minutes: 40, seconds: 2400, day: "2026-10-13", status: "planned" },
  ];
}
```

The second renames `minutes` to `durationMinutes`, because the name is clearer, and returns a skipped
session now that 1.5.2 can draw one. Save this as `api-rename.ts`:

```typescript
// api-rename.ts: a clearer name for minutes, and the new skipped status
export function sessions() {
  return [
    { id: "s-101", course: "statistics", durationMinutes: 25, day: "2026-10-12", status: "done" },
    { id: "s-102", course: "python", durationMinutes: 40, day: "2026-10-13", status: "planned" },
    { id: "s-103", course: "python", durationMinutes: 30, day: "2026-10-14", status: "skipped" },
  ];
}
```

Run the test against both:

```
ana@dev:~/planner$ node contract.ts api-additive.ts; echo "exit status $?"
1.3.1  GET /sessions  ok
1.5.2  GET /sessions  ok
exit status 0
ana@dev:~/planner$ node contract.ts api-rename.ts; echo "exit status $?"
1.3.1  GET /sessions  BROKEN
  s-101: minutes is missing
  s-102: minutes is missing
  s-103: minutes is missing
  s-103: status "skipped" is not one of done, planned
1.5.2  GET /sessions  BROKEN
  s-101: minutes is missing
  s-102: minutes is missing
  s-103: minutes is missing
exit status 1
```

**The additive change passes for both versions, and the exit status is 0. The rename fails both,
and 1.3.1 fails twice over.** Every session lost `minutes`, which both versions add up for the week,
and the skipped session carries a status 1.3.1 was never taught to draw, which a server developer
working on 1.5.2's feature had every reason to think was fine. The exit status of 1 is what makes it a
test: run it in the server's pipeline, lesson 10, and the rename never reaches production.

## What the test does not cover

- **Behaviour.** A field can keep its name and type and change its meaning: `minutes` rounded
  differently, `day` in UTC instead of the person's zone. The contract records shape; meaning needs
  the fixtures to carry values, and a person to think.
- **Requests.** This test checks responses. What each version *sends* is the other half: a new
  required field in a request breaks every old version the same way, and gets a file of its own in
  the same folder.
- **Versions nobody wrote down.** A version with no file is not protected. When a version leaves the
  support window, delete its file in the same pull request that stops supporting it, and the folder
  stays a true list.
