---
title: Merging field by field, against the version both started from
version: 1
---

**To merge two edits you need three versions, not two: the one both devices started from, and
each device's copy.** With only the two copies, the phone sees `minutes 30, done false` and the
server's `minutes 20, done true`, and cannot tell who changed what. Did the phone set 30, or did the
tablet set 20? Was `done` ticked, or unticked? The version both started from, the **base**, answers
every one of those questions, because a field that still has its base value is a field that side
did not touch.

So a device that edits offline keeps two copies of each row it changes: the row as the server last
sent it, and the row as the person has edited it since. Git does the same with a common ancestor,
and calls this a **three-way merge**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l14-merge\" aria-label=\"A three-way merge of session s3, field by field. Columns: base, the version both devices started from; the phone's copy; the tablet's copy; the merge. minutes: base 20, phone 30, tablet 20, merged 30, taken from the phone. done: base false, phone false, tablet true, merged true, taken from the tablet. course: guitar on all three, kept. Below, the other case: minutes base 20, phone 30, tablet 25: both changed it, so it is a conflict and both values are kept for the person.\"><text x=\"150\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">base</text><text x=\"250\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">phone</text><text x=\"350\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tablet</text><text x=\"450\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">merged</text><text x=\"20\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutes</text><rect x=\"110\" y=\"42\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20</text><rect x=\"210\" y=\"42\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30</text><rect x=\"310\" y=\"42\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20</text><rect x=\"410\" y=\"42\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30</text><text x=\"505\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">only the phone changed it</text><text x=\"20\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">done</text><rect x=\"110\" y=\"82\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">false</text><rect x=\"210\" y=\"82\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">false</text><rect x=\"310\" y=\"82\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">true</text><rect x=\"410\" y=\"82\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">true</text><text x=\"505\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">only the tablet changed it</text><text x=\"20\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">course</text><rect x=\"110\" y=\"122\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">guitar</text><rect x=\"210\" y=\"122\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">guitar</text><rect x=\"310\" y=\"122\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">guitar</text><rect x=\"410\" y=\"122\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">guitar</text><text x=\"505\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">nobody changed it</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">the other case: the same field on both sides</text><text x=\"20\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutes</text><rect x=\"110\" y=\"204\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20</text><rect x=\"210\" y=\"204\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30</text><rect x=\"310\" y=\"204\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">25</text><rect x=\"410\" y=\"204\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"500.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">conflict: keep both</text><text x=\"600\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">both changed it, differently</text></svg>", "caption": "A field still at its base value is a field that side did not touch. Only a field both sides changed, to different values, is a real conflict."}
```

## The rule

Field by field, there are four cases. Both sides agree: keep it. Only one side differs from the
base: that side changed it, take its value. Both differ from the base and from each other: **that
field is a real conflict**, and nothing in the data says which value is right. Save this as
`merge3.ts` in `~/planner/versions`:

```typescript
// merge3.ts: merge two edits of one record against the version both started from.
export type Fields = Record<string, unknown>;

export function merge3(base: Fields, mine: Fields, theirs: Fields) {
  const merged: Fields = {};
  const conflicts: string[] = [];
  for (const k of Object.keys(base)) {
    if (mine[k] === theirs[k]) merged[k] = mine[k]; // both agree
    else if (mine[k] === base[k]) merged[k] = theirs[k]; // only they changed it
    else if (theirs[k] === base[k]) merged[k] = mine[k]; // only I changed it
    else {
      merged[k] = theirs[k]; // both changed it: a real conflict
      conflicts.push(k);
    }
  }
  return { merged, conflicts };
}
```

The phone's sync uses it when the server answers 409. It sends its edit with the version it read;
on a refusal it merges its base, its copy and the server's current row, and if no field conflicts
it sends the merge with the server's version. Save it as `sync.ts`:

```schooling-example
{"language": "typescript", "file": "sync.ts", "parts": [{"code": "// sync.ts: the phone sends its edit of s3; on a 409 it merges with the server's row and tries again.\nimport { merge3, type Fields } from \"./merge3.ts\";\n\nconst fields = [\"course\", \"date\", \"minutes\", \"done\"];\nconst pick = (row: Fields) => Object.fromEntries(fields.map((k) => [k, row[k]]));\n", "note": "The fields that make up a session, and a helper that keeps only those from a row the server sent, which also carries `id` and `version`."}, {"code": "// What the phone last received from the server, and the edit made on top of it, offline.\nlet base: Fields = { course: \"guitar\", date: \"2026-10-21\", minutes: 20, done: false };\nlet version = 1;\nlet mine: Fields = { ...base };\nfor (const arg of process.argv.slice(2)) {\n  const [k, v] = arg.split(\"=\");\n  mine[k] = k === \"minutes\" ? Number(v) : v === \"true\";\n}\n", "note": "The two copies the device keeps: `base`, as the server last sent it at version 1, and `mine`, the person's edit on top of it. The arguments say what was edited, as `minutes=30`."}, {"code": "for (let attempt = 1; attempt <= 3; attempt++) {\n  const res = await fetch(\"http://localhost:8014/sessions/s3\", {\n    method: \"PUT\",\n    body: JSON.stringify({ ...mine, version }),\n  });\n  const reply = await res.json();\n  console.log(`PUT with version ${version}: ${res.status}`);\n  if (res.ok) {\n    console.log(\"saved  \", JSON.stringify(reply));\n    break;\n  }", "note": "Send the edit with the version it was made from. A 200 means nobody wrote in between, and the reply is the saved row."}, {"code": "  const theirs = pick(reply.current);\n  const { merged, conflicts } = merge3(base, mine, theirs);\n  if (conflicts.length) {\n    console.log(`conflict on ${conflicts.join(\", \")}: both versions kept for the person`);\n    console.log(`  mine   ${JSON.stringify(pick(mine))}`);\n    console.log(`  theirs ${JSON.stringify(theirs)}`);\n    break;\n  }", "note": "A 409 carries the server's current row. Merge it against the base; if a field changed on both sides, stop and keep both copies."}, {"code": "  console.log(\"merged \", JSON.stringify(merged));\n  [base, mine, version] = [theirs, merged, reply.current.version];\n}", "note": "Otherwise the merge becomes the new edit, the server's row becomes the new base, and the next attempt names the server's version."}]}
```

## The two cases

First the morning of lesson 13: the tablet ticks the session, then the phone sends its 30 minutes.
The server has just been restarted, so `s3` is back at version 1:

```
ana@dev:~/planner/versions$ curl -s -X PUT http://localhost:8014/sessions/s3 -d '{"course":"guitar","date":"2026-10-21","minutes":20,"done":true,"version":1}' -w '%{http_code}\n'
{"id":"s3","course":"guitar","date":"2026-10-21","minutes":20,"done":true,"version":2}
200
ana@dev:~/planner/versions$ node sync.ts minutes=30
PUT with version 1: 409
merged  {"course":"guitar","date":"2026-10-21","minutes":30,"done":true}
PUT with version 2: 200
saved   {"id":"s3","course":"guitar","date":"2026-10-21","minutes":30,"done":true,"version":3}
```

**Both edits survived.** The first `PUT` was refused, the merge took `minutes` from the phone and
`done` from the tablet, and the second `PUT`, carrying version 2, was accepted as version 3. Nobody
was asked anything, because there was nothing to ask: the two devices changed different fields.

Then the case the merge cannot settle. The tablet changes the same session to 25 minutes, and the
phone, offline, to 30:

```
ana@dev:~/planner/versions$ curl -s -X PUT http://localhost:8014/sessions/s3 -d '{"course":"guitar","date":"2026-10-21","minutes":25,"done":false,"version":1}' -w '%{http_code}\n'
{"id":"s3","course":"guitar","date":"2026-10-21","minutes":25,"done":false,"version":2}
200
ana@dev:~/planner/versions$ node sync.ts minutes=30
PUT with version 1: 409
conflict on minutes: both versions kept for the person
  mine   {"course":"guitar","date":"2026-10-21","minutes":30,"done":false}
  theirs {"course":"guitar","date":"2026-10-21","minutes":25,"done":false}
```

`minutes` changed on both sides, to different values, so the program stops and keeps both copies.
The server still holds 25, and the phone's 30 is not lost: it is in `mine`, waiting for somebody to
choose. **That is the one case a merge should hand to a person**, and it is much rarer than the
conflicts last write wins was quietly settling, because most concurrent edits touch different
fields.
