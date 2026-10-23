---
title: A project, at exact versions
version: 1
---

**`ng new` writes a whole project in one command: the configuration, the first component, a test,
and the list of packages it needs.** Then it runs npm to install them. On the day this course was
recorded, the second half failed, and the failure is worth seeing, because it is the kind you will
meet again on a real project.

## Asking for one

The CLI is not installed anywhere yet, so `npx` fetches it for this one command. The version is in
the name, `@21.2.28`, for the reason lesson 1 gave:

```
ana@dev:~$ npx @angular/cli@21.2.28 new planner --style=css --ssr=false --zoneless --ai-config=none
npm warn exec The following package was not found and will be installed: @angular/cli@21.2.28
CREATE planner/.prettierrc (161 bytes)
CREATE planner/README.md (1461 bytes)
CREATE planner/.editorconfig (314 bytes)
CREATE planner/.gitignore (622 bytes)
CREATE planner/angular.json (1906 bytes)
CREATE planner/package.json (784 bytes)
CREATE planner/tsconfig.json (957 bytes)
CREATE planner/tsconfig.app.json (429 bytes)
CREATE planner/tsconfig.spec.json (441 bytes)
CREATE planner/.vscode/extensions.json (130 bytes)
CREATE planner/.vscode/launch.json (470 bytes)
CREATE planner/.vscode/mcp.json (179 bytes)
CREATE planner/.vscode/tasks.json (978 bytes)
CREATE planner/src/main.ts (222 bytes)
CREATE planner/src/index.html (293 bytes)
CREATE planner/src/styles.css (80 bytes)
CREATE planner/src/app/app.css (0 bytes)
CREATE planner/src/app/app.spec.ts (674 bytes)
CREATE planner/src/app/app.ts (289 bytes)
CREATE planner/src/app/app.html (20144 bytes)
CREATE planner/src/app/app.config.ts (313 bytes)
CREATE planner/src/app/app.routes.ts (77 bytes)
CREATE planner/public/favicon.ico (15086 bytes)
- Installing packages (npm)...
npm error Cannot read properties of null (reading 'edgesOut')
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T23_32_54_625Z-debug-0.log
✖ Package install failed, see above.
The Schematic workflow failed. See above.
```

The four options answer the questions `ng new` would otherwise ask at the terminal: plain CSS for
styles, no server-side rendering yet (lesson 23 adds it), no zone.js (lesson 7 explains what that
was), and no instruction files for AI coding assistants. In a terminal, `npx` first asks
`Ok to proceed? (y)` before downloading the CLI; the recording ran without a terminal, which is why
the transcript shows a warning in its place.

Every `CREATE` line is a file written. Then `Installing packages (npm)...`, and npm stopped with a
message that names none of your packages.

## What broke, and what does not need fixing

`Cannot read properties of null (reading 'edgesOut')` is not a problem with the project. It is a
JavaScript error inside npm itself, in the part that works out **peer dependencies**: packages that
another package expects you to have installed beside it, rather than bringing them along. Vitest,
the test runner, declares a dozen optional peers, one of them declares its own, and npm 10.9.4, the
version that came with Node 22.22.0, trips over the chain. npm 11 does not, and Node 22.22.0 does not
ship npm 11, so this course works around it rather than installing a second npm.

The workaround is one setting: **`legacy-peer-deps`** tells npm not to install peer dependencies on
its own, which skips the step that crashes. It has a cost, and it is small here: npm will no longer
add a peer you forgot. Every package this project uses is listed in its `package.json` already, so
there is nothing to forget. The files `ng new` wrote are all there; go into the folder and save the
setting in a file called `.npmrc`, which npm reads in every command run inside the project:

```ini
# .npmrc
legacy-peer-deps=true
save-exact=true
```

`save-exact` is the second line for the reason lesson 1's TypeScript folder used `--save-exact`: a
package added later is written as `1.2.3` and not `^1.2.3`.

## Exact versions

`ng new` wrote `"@angular/core": "^21.2.0"`, and the `^` means *21.2.0 or anything newer before 22*.
Two people installing a week apart get different code. The brief for this whole track is the
opposite: every version exact, so that your transcripts match these. Replace `package.json` with
this one, which names the versions the course was recorded with:

```schooling-example
{"language": "json", "file": "package.json", "parts": [
 {"code": "{\n  \"name\": \"planner\",\n  \"version\": \"0.0.0\",\n  \"scripts\": {\n    \"ng\": \"ng\",\n    \"start\": \"ng serve\",\n    \"build\": \"ng build\",\n    \"watch\": \"ng build --watch --configuration development\",\n    \"test\": \"ng test\"\n  },", "note": "The project's name, and five shortcuts. `npm start` runs `ng serve`, `npm test` runs `ng test`; this course types `npx ng ...` instead, which runs the same local CLI and shows what it runs."},
 {"code": "  \"private\": true,\n  \"packageManager\": \"npm@10.9.4\",", "note": "`private` stops this from being published to npm by accident. `packageManager` records which package manager and version the project expects."},
 {"code": "  \"dependencies\": {\n    \"@angular/common\": \"21.2.25\",\n    \"@angular/compiler\": \"21.2.25\",\n    \"@angular/core\": \"21.2.25\",\n    \"@angular/forms\": \"21.2.25\",\n    \"@angular/platform-browser\": \"21.2.25\",\n    \"@angular/router\": \"21.2.25\",\n    \"rxjs\": \"7.8.2\",\n    \"tslib\": \"2.8.1\"\n  },", "note": "What the application needs when it runs in the browser: the framework's packages, all at 21.2.25, and the two libraries Angular itself is built on."},
 {"code": "  \"devDependencies\": {\n    \"@angular/build\": \"21.2.28\",\n    \"@angular/cli\": \"21.2.28\",\n    \"@angular/compiler-cli\": \"21.2.25\",\n    \"jsdom\": \"28.1.0\",\n    \"prettier\": \"3.9.10\",\n    \"typescript\": \"5.9.3\",\n    \"vitest\": \"4.1.12\"\n  }\n}", "note": "What only building and testing need: the CLI and its build system at 21.2.28, the compiler, TypeScript, the test runner Vitest with jsdom, a browser imitation it runs tests in, and Prettier, which formats code."}
]}
```

The framework's packages and the CLI's have different numbers on purpose: they are released by the
same team on the same calendar, but each package's patch number moves when that package changes.

```
ana@dev:~/planner$ npm install

added 470 packages, and audited 471 packages in 13s

found 0 vulnerabilities
ana@dev:~/planner$ npm ls --depth=0
planner@0.0.0 /home/ana/planner
├── @angular/build@21.2.28
├── @angular/cli@21.2.28
├── @angular/common@21.2.25
├── @angular/compiler-cli@21.2.25
├── @angular/compiler@21.2.25
├── @angular/core@21.2.25
├── @angular/forms@21.2.25
├── @angular/platform-browser@21.2.25
├── @angular/router@21.2.25
├── jsdom@28.1.0
├── prettier@3.9.10
├── rxjs@7.8.2
├── tslib@2.8.1
├── typescript@5.9.3
└── vitest@4.1.12

ana@dev:~/planner$ du -sh node_modules
318M	node_modules
```

**`package-lock.json` is the file to keep.** `npm install` wrote it beside `package.json`, with the
exact version of every one of those packages, the ones you named and the ones they brought in. Run
`npm ci` on another machine and it rebuilds `node_modules` from the lockfile and nothing else, which
is how a second computer, or a build server, gets the same code you have. `du` says what that costs
in disk, and the figure is the one lesson 1's table rounded.

## A repository

`ng new` makes the folder a git repository when it finishes cleanly. This one stopped half way, so
do it yourself, under the name and address you gave git in the `git` course:

```
ana@dev:~/planner$ git init -q
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "A new Angular project"
ana@dev:~/planner$ git show --stat --oneline | tail -1
 25 files changed, 9394 insertions(+)
ana@dev:~/planner$ wc -l package-lock.json
8603 package-lock.json
```

`.gitignore`, which `ng new` wrote, already leaves out `node_modules` and the build output, so the
commit holds what the CLI generated, what you wrote, and the lockfile: 25 files, and 8,603 of
those 9,394 lines are `package-lock.json`.
