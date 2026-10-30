---
title: A minified JavaScript trace, and its source map
version: 1
---

**A React Native release ships its JavaScript as one minified bundle, and a crash in it points at
line 1 and a column.** The **source map** produced beside the bundle says, for each position in the
bundle, which file, line and column of your source it came from. Here the bundler is **esbuild**,
which does the same job as React Native's Metro for this purpose, and the reader is the `source-map`
library that crash reporters use themselves.

Install both into `~/planner`, pinned:

```sh
npm install -E esbuild@0.28.2 source-map@0.8.0
```

## A small bug, built for release

Save this as `week.ts`:

```typescript
// week.ts: the planner's week total, with the bug of lesson 12
type Session = { course: string; minutes: number };
const byCourse: Record<string, Session[]> = { spanish: [{ course: "spanish", minutes: 30 }] };

export function totalFor(course: string): number {
  return byCourse[course].reduce((n, s) => n + s.minutes, 0);
}

console.log("spanish", totalFor("spanish"));
console.log("guitar", totalFor(process.argv[2] ?? "guitar"));
```

Bundle it the way a release does, minified, with a source map, and run it:

```
ana@dev:~/planner$ npx esbuild week.ts --bundle --minify --sourcemap --platform=node --format=esm --log-level=warning --outfile=dist/bundle.js
ana@dev:~/planner$ ls dist; cat dist/bundle.js
bundle.js
bundle.js.map
var r={spanish:[{course:"spanish",minutes:30}]};function s(n){return r[n].reduce((e,o)=>e+o.minutes,0)}console.log("spanish",s("spanish"));console.log("guitar",s(process.argv[2]??"guitar"));export{s as totalFor};
//# sourceMappingURL=bundle.js.map
ana@dev:~/planner$ node dist/bundle.js 2> trace.txt; cat trace.txt
spanish 30
file:///home/ana/planner/dist/bundle.js:1
var r={spanish:[{course:"spanish",minutes:30}]};function s(n){return r[n].reduce((e,o)=>e+o.minutes,0)}console.log("spanish",s("spanish"));console.log("guitar",s(process.argv[2]??"guitar"));export{s as totalFor};
                                                                          ^

TypeError: Cannot read properties of undefined (reading 'reduce')
    at s (file:///home/ana/planner/dist/bundle.js:1:75)
    at file:///home/ana/planner/dist/bundle.js:1:161
    at ModuleJob.run (node:internal/modules/esm/module_job:343:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:665:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:117:5)

Node.js v22.22.0
```

The trace is correct and useless: function `s`, line 1, column 75. Nothing in it says `totalFor`
or `week.ts`.

## Reading it back

Save this as `symbolicate.ts`. It reads a trace on its standard input and a source map named on the
command line, and rewrites each frame that points into the bundle:

```schooling-example
{"language": "typescript", "file": "symbolicate.ts", "parts": [{"code": "// symbolicate.ts: rewrite the frames of a minified trace through the bundle's source map\nimport { SourceMapConsumer } from \"source-map\";\nimport { readFileSync } from \"node:fs\";\n\nconst map = JSON.parse(readFileSync(process.argv[2], \"utf8\"));\nconst trace = readFileSync(0, \"utf8\");", "note": "The source map, named on the command line, and the trace, read from standard input, so a trace can be piped straight in."}, {"code": "const FRAME = /^(\\s*at )(?:(\\S+) \\()?(.*bundle\\.js):(\\d+):(\\d+)\\)?$/;", "note": "A frame that points into the bundle: an optional function name, then the file, the line and the column."}, {"code": "await SourceMapConsumer.with(map, null, (consumer) => {\n  for (const line of trace.trimEnd().split(\"\\n\")) {\n    const m = line.match(FRAME);\n    if (!m) {\n      console.log(line);\n      continue;\n    }", "note": "Every line that is not such a frame is printed as it came: the message, and Node's own frames."}, {"code": "    const p = consumer.originalPositionFor({ line: Number(m[4]), column: Number(m[5]) - 1 });\n    console.log(`${m[1]}${p.source}:${p.line}:${p.column + 1}  (bundle ${m[2] ?? \"top level\"} ${m[4]}:${m[5]})`);\n  }\n});", "note": "The map's columns count from 0 and a trace's from 1, hence the two corrections. The minified name is kept in brackets."}]}
```

```
ana@dev:~/planner$ node symbolicate.ts dist/bundle.js.map < trace.txt
file:///home/ana/planner/dist/bundle.js:1
var r={spanish:[{course:"spanish",minutes:30}]};function s(n){return r[n].reduce((e,o)=>e+o.minutes,0)}console.log("spanish",s("spanish"));console.log("guitar",s(process.argv[2]??"guitar"));export{s as totalFor};
                                                                          ^

TypeError: Cannot read properties of undefined (reading 'reduce')
    at ../week.ts:6:27  (bundle s 1:75)
    at ../week.ts:10:23  (bundle top level 1:161)
    at ModuleJob.run (node:internal/modules/esm/module_job:343:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:665:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:117:5)

Node.js v22.22.0
```

Now the first frame is `week.ts`, line 6, the `reduce` on a course that is not there, and the second
is line 10, the call with `guitar`. The minified names stay beside them, because they are what the
crash reporter grouped by. Node's own frames, the ones in `node:internal`, are left alone: they were
never minified.

## What a crash reporter does with it

Exactly this, on its server: the source map is uploaded with the release, and every report from that
release is rewritten before anybody reads it. On your own computer, Node can do it at run time with
`node --enable-source-maps`; on a phone, Hermes runs the bundle without the map, which stays on your
build machine, and the server is where the two meet.
