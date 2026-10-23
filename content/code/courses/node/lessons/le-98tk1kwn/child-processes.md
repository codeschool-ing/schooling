---
title: Starting other programs
version: 1
---

**A Node program can start any other program on the machine**, wait for it, and read what it printed:
a `git` command, an image converter, a script in another language. `node:child_process` has four
functions for it, and the difference between them is how the output comes back and whether a shell
stands in between.

| function | the output | a shell in between? | for |
|---|---|---|---|
| `execFile` | all of it, when the program ends | no | a command whose output is short |
| `exec` | all of it, when the program ends | **yes** | almost nothing, as below |
| `spawn` | a stream, while it runs | no, by default | long or endless output, and input |
| `fork` | messages, both ways | no | another Node program, the next section |

## execFile

```schooling-example
{"language": "javascript", "file": "run.js", "parts": [
 {"code": "// run.js: starting a program, and the two ways it can go wrong.\nimport { execFile } from \"node:child_process\";\nimport { promisify } from \"node:util\";\n\nconst execFileP = promisify(execFile);", "note": "**`promisify` turns the callback function into one that returns a promise**, so it can be awaited. The promise gives `{ stdout, stderr }`."},
 {"code": "const { stdout } = await execFileP(\"du\", [\"-sh\", \"../links/node_modules\"]);\nconsole.log(\"du said:\", stdout.trim());", "note": "**The program, then its arguments as a list.** Each argument reaches `du` exactly as written, whatever characters it holds."},
 {"code": "try {\n  await execFileP(\"ls\", [\"no-such-file\"]);\n} catch (err) {\n  console.log(\"it failed:\", err.code, err.stderr.trim());\n}", "note": "**A program that exits with a code other than 0 rejects the promise.** `err.code` is that exit code and `err.stderr` is what it printed on the way out."},
 {"code": "try {\n  await execFileP(\"no-such-program\");\n} catch (err) {\n  console.log(\"it never started:\", err.code);\n}", "note": "**A program that is not there** rejects with `ENOENT`, the same code lesson 8's missing files had: the system looked for a file to run and found none."}
]}
```

```
ana@dev:~/server/procs$ node run.js
du said: 14M	../links/node_modules
it failed: 2 ls: cannot access 'no-such-file': No such file or directory
it never started: ENOENT
```

## Why not exec

**`exec` hands the whole command to a shell as one string**, and the shell reads it the way it reads
what you type: spaces split it, `;` ends a command and starts another, `$( )` runs something. That
is convenient for a command you wrote yourself and a trap for one that has anything from outside in
it, such as a file name somebody uploaded:

```javascript
// shell.js: the same file name, given to a shell and given to a program.
import { exec, execFile } from "node:child_process";
import { writeFileSync } from "node:fs";

const name = "notes.txt; echo the shell ran this too";
writeFileSync(name, "three words here\n");

exec(`wc -w ${name}`, (err, stdout) => console.log("exec:    ", JSON.stringify(stdout)));
execFile("wc", ["-w", name], (err, stdout) => console.log("execFile:", JSON.stringify(stdout)));
```

```
ana@dev:~/server/procs$ node shell.js
exec:     "the shell ran this too\n"
execFile: "3 notes.txt; echo the shell ran this too\n"
```

**`execFile` counted the three words in the file with that odd name. `exec` ran two commands**: `wc`
on a file called `notes.txt`, which does not exist, and then the `echo` the name carried. Here the
second command is harmless, and the point is that it was the file name, not the program, that decided
what ran. **The rule is `execFile` or `spawn` with a list of arguments**, and a shell only when the
command is a fixed string with nothing from outside in it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The same file name given two ways. exec hands one string to a shell, which splits it at the semicolon into two commands, wc and echo. execFile hands wc a list of arguments, so the whole name, semicolon included, arrives as one argument and no shell reads it.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">exec(`wc -w ${name}`)</text><rect x=\"20\" y=\"45\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Node</text><line x1=\"140\" y1=\"65\" x2=\"198\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,65.0 190.6,68.1 190.6,61.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"200\" y=\"45\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">/bin/sh</text><line x1=\"320\" y1=\"58\" x2=\"400\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"400.0,50.0 393.0,53.8 392.4,47.6\" fill=\"var(--paper-dim)\"></polygon><line x1=\"320\" y1=\"72\" x2=\"400\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"400.0,88.0 392.2,89.6 393.4,83.5\" fill=\"var(--paper-dim)\"></polygon><rect x=\"402\" y=\"35\" width=\"300\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">wc -w notes.txt</text><rect x=\"402\" y=\"75\" width=\"300\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">echo the shell ran this too</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">execFile(\"wc\", [\"-w\", name])</text><rect x=\"20\" y=\"155\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Node</text><line x1=\"140\" y1=\"175\" x2=\"400\" y2=\"175\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"400.0,175.0 392.6,178.1 392.6,171.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"270\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no shell in between</text><rect x=\"402\" y=\"155\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">wc -w</text><text x=\"552\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">\"notes.txt; echo the shell ran this too\"</text></svg>", "caption": "A shell reads a string as commands; a list of arguments is only ever arguments."}
```

## spawn

**`spawn` gives the output as a stream while the program runs**, so a program that prints a great
deal, or never stops, is read the way lesson 8 read a large file, a line at a time:

```javascript
// stream.js: spawn, for a program whose output is long or never ends.
import { spawn } from "node:child_process";
import { createInterface } from "node:readline";

const child = spawn("find", ["/usr/share", "-name", "*.gz"]);
let lines = 0;
for await (const line of createInterface({ input: child.stdout })) lines++;
const code = await new Promise((resolve) => child.on("close", resolve));
console.log(`find printed ${lines} lines and exited with ${code}`);
```

```
ana@dev:~/server/procs$ node stream.js
find printed 1681 lines and exited with 0
```

`execFile` would have collected the same lines into one string, and it has a limit, `maxBuffer`, one
megabyte by default, past which it kills the program and reports an error. A stream has no such
limit, because nothing is collected.
