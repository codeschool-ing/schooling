---
title: A clean checkout, and the file you forgot
version: 1
---

**The one failure your own computer can never show you is a file it has and the repository does not.**
You add a file, import it, the page works, the build works, the tests pass, and you commit everything
except that file. On your computer it is still there, so every check you run passes. On any other
machine it does not exist.

That is the strongest argument for CI, and it costs nothing to see on your own computer: clone the
repository into a new folder, which is what a CI machine does, and run the checks there.

## A file, forgotten

The planner shows a session's length as `75 min`, which reads better as `1 h 15 min`. A small function
does it:

```typescript
// src/format.ts
export function duration(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return h === 0 ? `${m} min` : m === 0 ? `${h} h` : `${h} h ${m} min`;
}
```

and `view.ts` uses it, with two edits. Everything passes on this computer, and the commit leaves
`format.ts` behind, as a hurried `git commit` of the files you edited does:

```
ana@dev:~/planner$ sed -i '2i import { duration } from "./format";' src/view.ts
ana@dev:~/planner$ sed -i 's/${s.minutes} min /${duration(s.minutes)} /' src/view.ts
ana@dev:~/planner$ npx tsc && npm test 2>&1 | tail -4
      Tests  5 passed (5)
   Start at  19:52:12
   Duration  229ms (import 37%, transform 27%, worker 18%, tests 18%, environment 1%)

ana@dev:~/planner$ git status --short
 M src/view.ts
?? src/format.ts
ana@dev:~/planner$ git commit -qam "Show durations in hours and minutes"
```

`git status` printed the warning in plain sight, `?? src/format.ts`, and it is exactly the line people
stop reading after the hundredth time.

## The same checks, on a clean copy

Clone the repository into a folder of its own and run the pipeline there, step by step, as a CI machine
would:

```
ana@dev:~$ rm -rf ~/ci && git clone -q ~/planner ~/ci && cd ~/ci
ana@dev:~/ci$ npm ci 2>&1 | tail -1
found 0 vulnerabilities
ana@dev:~/ci$ npx tsc
src/view.ts(2,26): error TS2307: Cannot find module './format' or its corresponding type declarations.
```

The install worked, from the lockfile. **The type check failed on the import of `./format`**, because in
this copy there is no such file, and the pipeline would stop here with a red result on the pull request.
Commit the file and run the clean copy again:

```
ana@dev:~/planner$ git add src/format.ts
ana@dev:~/planner$ git commit -qm "Add the duration formatter"
ana@dev:~/planner$ cd ~/ci && git pull -q
ana@dev:~/ci$ npx tsc && npm test 2>&1 | tail -4
      Tests  5 passed (5)
   Start at  19:52:18
   Duration  292ms (transform 76%, import 13%, tests 6%, worker 4%)

ana@dev:~/ci$ npx vite build 2>&1 | tail -1
✓ built in 151ms
```

Green. This is the habit CI enforces and the reason for the word *clean*: the only checks that count are
the ones run on what was committed. Delete `~/ci` when you are done; it is a copy and nothing else uses
it.
