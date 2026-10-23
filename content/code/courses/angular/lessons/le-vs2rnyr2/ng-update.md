---
title: Updating, and what an update to 22 would ask
version: 1
---

**`ng update` does two jobs: it moves Angular's packages to a new version together, and it runs the
migrations that version ships to rewrite your code.** Asked with no arguments, it only looks:

```
ana@dev:~/planner$ npx ng update
Using package manager: npm
Collecting installed dependencies...
Found 15 dependencies.
    We analyzed your package.json, there are some packages to update:
    
      Name                       Version                  Command to update
     ------------------------------------------------------------------------
      @angular/cli               21.2.28 -> 22.2.4        ng update @angular/cli
      @angular/core              21.2.25 -> 22.2.3        ng update @angular/core
    
    There might be additional packages which don't provide 'ng update' capabilities that are outdated.
    You can update the additional packages by running the update command of your package manager.
```

It found Angular 22 on the registry and lists the two commands that would move to it. Two
packages, not ten: `ng update @angular/core` moves every framework package with it, and
`@angular/cli` brings `@angular/build`. The last two lines are honest about the rest: Vitest,
TypeScript and the others are updated with npm, and `npm outdated` lists them.

## The calendar

Lesson 1 quoted when each major was released. The registry keeps the publication time of every
version of every package, and this is where those dates came from:

```
ana@dev:~/planner$ npm view @angular/core time --json | grep -E '"2[0-2]\.0\.0"'
  "20.0.0": "2025-05-28T13:53:18.215Z",
  "21.0.0": "2025-11-19T18:07:38.390Z",
  "22.0.0": "2026-06-03T13:04:10.790Z",
```

May or June, then November, every year: the pattern is regular enough that a team can put the
update in its plan before the release exists.

## The update this course does not make

Ask for 22, and the first answer is about your files, not about Angular:

```
ana@dev:~/planner$ npx ng update @angular/core@22 @angular/cli@22 2>&1 | tail -5
Error: Repository is not clean. Please commit or stash any changes before updating.
```

`ng update` refuses to run on a repository with uncommitted changes, because the migrations are
about to edit your code and the only clean way to see what they did is a diff against a commit.
`git status` lists what this lesson changed since the first commit; commit it, and ask again:

```
ana@dev:~/planner$ git status --short
 M src/app/app.html
 M src/app/app.spec.ts
?? public/courses.json
?? src/app/week-summary/
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "The CLI: serve, generate, build, test"
ana@dev:~/planner$ npx ng update @angular/core@22 @angular/cli@22 2>&1 | tail -5
Node.js version v22.22.0 detected.
The Angular CLI requires a minimum Node.js version of v22.22.3 or v24.15.0 or v26.0.0.

Please update your Node.js version or visit https://nodejs.org/ for additional instructions.
```

This time it gets as far as installing a temporary copy of the new CLI to run the migrations with,
and that copy checks the Node it is running on.

So the first step of a move to 22 is not in this project at all: it is a newer Node, 22.22.3 or
later, for every course on the `frontend` track at once, decided where the track's Node is
decided. Nothing was changed: the temporary CLI refused before it wrote anything.

When the day comes, the update itself is one command per package, run on a clean tree so the
migrations' edits are the only thing in the next diff:

```sh
npx ng update @angular/core@22 @angular/cli@22
git diff
```

Read the diff before you commit it. A migration that rewrote fifty files has done exactly what it
said, and you are the one who will be asked why the code changed.

## Staying on 21

Angular 21 is in long-term support until May 2027. Within a major, the patches keep coming,
security fixes among them, and naming the major takes the newest of it:

```
ana@dev:~/planner$ npx ng update @angular/core@21 @angular/cli@21
Using package manager: npm
Collecting installed dependencies...
Found 15 dependencies.
Fetching dependency metadata from registry...
Package '@angular/core' is already up to date.
Package '@angular/cli' is already up to date.
```

Nothing to do on the day of the recording: the versions in `package.json` were the newest 21 there
was. When a patch does arrive, the same command writes the new numbers into `package.json` and the
lockfile; read the diff, and run `ng test` before you commit them.
