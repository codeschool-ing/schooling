---
title: When the setup fails
version: 1
---

**Each failure below was produced on purpose on the machine this course was recorded on, and each
message says what is wrong once you know which line to read.** Node.js prints a lot when it stops: a
few lines of its own source, a stack of its internal functions, and its version. The line that
matters is the one that starts with an error's name, `Error:` or `TypeError` or `SyntaxError`, and
the `code:` near the bottom names the kind. Read the section once now, and come back to it when
something does not work.

## `Cannot find module` and a path in your home

```
ana@dev:~$ node week.ts
node:internal/modules/cjs/loader:1386
  throw err;
  ^

Error: Cannot find module '/home/ana/week.ts'
    at Function._resolveFilename (node:internal/modules/cjs/loader:1383:15)
    at defaultResolveImpl (node:internal/modules/cjs/loader:1025:19)
    at resolveForCJSWithHooks (node:internal/modules/cjs/loader:1030:22)
    at Function._load (node:internal/modules/cjs/loader:1192:37)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49 {
  code: 'MODULE_NOT_FOUND',
  requireStack: []
}

Node.js v22.22.0
```

The path is the clue: Node.js looked for `/home/ana/week.ts`, in the home folder, and the file is in
`~/planner`. **`node` runs a file relative to the folder the terminal is in**, and this terminal was
still in `~`. `cd ~/planner` and run it again. The prompt says where you are before every command,
which is why the transcripts in this course show it.

## `Unknown file extension ".ts"`

```
ana@dev:~/planner$ ~/old-node/bin/node --version
v22.17.0
ana@dev:~/planner$ ~/old-node/bin/node week.ts
node:internal/modules/esm/get_format:219
  throw new ERR_UNKNOWN_FILE_EXTENSION(ext, filepath);
        ^

TypeError [ERR_UNKNOWN_FILE_EXTENSION]: Unknown file extension ".ts" for /home/ana/planner/week.ts
    at Object.getFileProtocolModuleFormat [as file:] (node:internal/modules/esm/get_format:219:9)
    at defaultGetFormat (node:internal/modules/esm/get_format:245:36)
    at defaultLoad (node:internal/modules/esm/load:120:22)
    at async ModuleLoader.loadAndTranslate (node:internal/modules/esm/loader:580:32)
    at async ModuleJob._link (node:internal/modules/esm/module_job:154:19) {
  code: 'ERR_UNKNOWN_FILE_EXTENSION'
}

Node.js v22.17.0
```

This is an older Node.js, 22.17.0, meeting the same file. Before 22.18, `node` did not run TypeScript
unless you asked it to with a flag, so it saw `.ts` and stopped. **If you see this, the `node` your
terminal found is not the one you installed.** `command -v node` prints the path of the one it
found; with the installation above it is `/home/ana/.local/bin/node`, with your own name in place
of `ana`. Anything else is a second copy, from your system's packages or an installer, that comes
earlier in your `PATH`. Remove it, or open a new terminal if you have only just installed.

## `Cannot find module` and a path with no extension

```
ana@dev:~/planner$ node week.ts
node:internal/modules/esm/resolve:274
    throw new ERR_MODULE_NOT_FOUND(
          ^

Error [ERR_MODULE_NOT_FOUND]: Cannot find module '/home/ana/planner/planner' imported from /home/ana/planner/week.ts
    at finalizeResolution (node:internal/modules/esm/resolve:274:11)
    at moduleResolve (node:internal/modules/esm/resolve:859:10)
    at defaultResolve (node:internal/modules/esm/resolve:983:11)
    at #cachedDefaultResolve (node:internal/modules/esm/loader:731:20)
    at ModuleLoader.resolve (node:internal/modules/esm/loader:708:38)
    at ModuleLoader.getModuleJobForImport (node:internal/modules/esm/loader:310:38)
    at ModuleJob._link (node:internal/modules/esm/module_job:182:49) {
  code: 'ERR_MODULE_NOT_FOUND',
  url: 'file:///home/ana/planner/planner'
}

Node.js v22.22.0
```

Here `week.ts` imported `"./planner"` instead of `"./planner.ts"`. **When Node.js runs modules, it
does not guess the end of a file name**: the import names the file exactly, extension included. A
build tool would have filled the extension in, and the `frontend` track's projects work that way;
running TypeScript directly does not. Put the `.ts` back.

## `TypeScript enum is not supported in strip-only mode`

```
ana@dev:~/planner$ node week.ts
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

file:///home/ana/planner/planner.ts:2
// planner.ts: the study planner's data, and the sums every screen needs
export enum Level { Beginner, Advanced }
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
export type Course = { id: string; title: string };

SyntaxError [ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX]: TypeScript enum is not supported in strip-only mode
    at parseTypeScript (node:internal/modules/typescript:63:40)
    at processTypeScriptCode (node:internal/modules/typescript:133:42)
    at stripTypeScriptModuleTypes (node:internal/modules/typescript:163:10)
    at ModuleLoader.<anonymous> (node:internal/modules/esm/translators:605:16)
    at #translate (node:internal/modules/esm/loader:546:20)
    at afterLoad (node:internal/modules/esm/loader:596:29)
    at ModuleLoader.loadAndTranslate (node:internal/modules/esm/loader:601:12)
    at #createModuleJob (node:internal/modules/esm/loader:624:36)
    at #getJobFromResolveResult (node:internal/modules/esm/loader:343:34)
    at ModuleLoader.getModuleJobForImport (node:internal/modules/esm/loader:311:41) {
  code: 'ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX'
}

Node.js v22.22.0
```

`node` runs TypeScript by **deleting the types**, and that only works for syntax that is nothing but
a type. An `enum` is more than that: it makes an object that exists when the program runs, so
deleting it would break the program, and Node.js refuses instead. The caret line under the source
points at the exact place. This course writes a fixed set of values as a union of strings,
`type Level = "beginner" | "advanced"`, which strips cleanly. Two other constructs are refused for the
same reason, a `namespace` that holds code and a constructor parameter marked `private`, and none of
the course's programs uses them.

## A warning about `MODULE_TYPELESS_PACKAGE_JSON`

```
ana@dev:~/planner$ node week.ts
{ monday: '2026-10-19', planned: 180, done: 120 }
(node:4) [MODULE_TYPELESS_PACKAGE_JSON] Warning: Module type of file:///home/ana/planner/week.ts is not specified and it doesn't parse as CommonJS.
Reparsing as ES module because module syntax was detected. This incurs a performance overhead.
To eliminate this warning, add "type": "module" to /home/ana/planner/package.json.
(Use `node --trace-warnings ...` to show where the warning was created)
```

**This one ran, and printed the right answer**, followed by a warning. `package.json` had lost its
`"type": "module"`, so Node.js first read the file as the older CommonJS kind, failed, and read it
again as a module. The warning says exactly what to add and where. A program that works with a
warning is worth fixing anyway: the next warning in a long output is easier to see when there are no
old ones beside it. Put the line back, and the warning goes:

```
ana@dev:~/planner$ node week.ts
{ monday: '2026-10-19', planned: 180, done: 120 }
```

## When nothing here matches

Copy the line that starts with the error's name into a search engine, with the word `node` in front
of it. A message like these was written to be searched for, and the first result is very often the
Node.js documentation page for that `code`. Before that, compare your file with the lesson's line by
line: a missing quote or bracket gives a `SyntaxError` whose caret points at the line after the real
mistake.
