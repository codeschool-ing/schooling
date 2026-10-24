---
title: A stack from production
version: 1
---

**The build that people run is minified: every function renamed to a letter or two, and the whole
planner on a few long lines.** A stack trace from it is accurate and useless, until something turns it
back. To see one, the planner needs an error in its own code, in a production build, so this section
ships a bug on purpose and takes it out again at the end.

Commit the monitor and the collector first, so the bug has something clean to be undone to:

```
ana@dev:~/planner$ git add -A && git commit -qm "Report errors to a collector"
```

The bug: `render` throws when the address ends in `?bug`. It is one line, and it is the kind of line that
reaches production when a check meant for debugging is left in:

```
ana@dev:~/planner$ sed -i 's/^function render(): void {/&\n  if (location.search === "?bug") throw new Error("A bug, on purpose");/' src/main.ts
```

## A build like the real one

A deploy with a server would set the variables when it builds, and the release would be the commit being
deployed. `git rev-parse --short HEAD` prints that commit's short hash:

```
ana@dev:~/planner$ VITE_GRAPHQL_URL=/graphql VITE_ERRORS_URL=/errors VITE_RELEASE=$(git rev-parse --short HEAD) npm run build 2>&1 | grep assets/
dist/assets/index-BU4yu1tj.css    2.11 kB │ gzip:  0.64 kB
dist/assets/index-BzxC4LxE.js     5.70 kB │ gzip:  2.47 kB │ map:    13.51 kB
dist/assets/apollo-C4i3kjo7.js  192.68 kB │ gzip: 56.59 kB │ map: 1,088.02 kB
```

Each JavaScript file now has a **map** beside it; the section after this one is about them. Serve the
build with `vite preview` on port 4173, with the GraphQL server and the collector still running, and open
`http://localhost:4173/course/git?bug`. The page stays empty, and the collector's terminal prints one more
line, with the commit as the release. Read the report back out of the file, its release, source and path,
then the stack the browser recorded:

```
ana@dev:~/planner$ tail -1 api/errors.jsonl | node -e 'process.stdin.on("data", (d) => { const r = JSON.parse(d); console.log(r.release, r.source, r.path); console.log(r.stack); })'
7ce2a66 error /course/git
Error: A bug, on purpose
    at A (http://localhost:4173/assets/index-BzxC4LxE.js:1:5016)
    at http://localhost:4173/assets/index-BzxC4LxE.js:1:5661
    at Object.next (http://localhost:4173/assets/apollo-C4i3kjo7.js:85:261)
    at e.next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:3846)
    at t._next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:3448)
    at t.next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:3072)
    at Object.next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:46412)
    at e.next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:3846)
    at t._next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:3448)
    at t.next (http://localhost:4173/assets/apollo-C4i3kjo7.js:49:3072)
```

The release is the commit, and the source is `error`: nothing in the planner caught this, so the window's
listener did.

`A`, at line 1, column 5016, of `index-…js`, called from an anonymous function in the same file, called
from eight frames in the Apollo chunk, where the browser stopped at ten frames, its default. That is all true, and it does not say which line of `main.ts`
to open. A minified build has only a few lines, so the line number alone says almost nothing; the column
says where, in a file nobody wrote.
