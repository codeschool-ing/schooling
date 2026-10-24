---
title: The files Vite reads, and which one wins
version: 1
---

**Vite reads variables from `.env` files at the root of the project, chooses which ones by the build's
mode, and lets a variable already set in the shell beat all of them.** Typing `VITE_TITLE=…` before every
build works, and nobody does it for long. The files are how a project keeps a setting per environment
without anybody remembering it.

## Four names

| file | read when | committed |
|---|---|---|
| `.env` | always | yes |
| `.env.local` | always | **no**: the template's `.gitignore` has `*.local` |
| `.env.<mode>` | only when the build runs in that mode | yes |
| `.env.<mode>.local` | only in that mode | **no** |

**The mode is a word the build is run with.** `npm run dev` runs in `development`, `npm run build` in
`production`, and `--mode staging` in whatever you name. When two files set the same variable, the one
for the mode beats the general one, and a `.local` file beats the one without. A variable that is already
in the environment when Vite starts beats every file.

## A staging mode

Give the planner a staging build with a heading that says so:

```
ana@dev:~/planner$ echo 'VITE_TITLE=Study planner (staging)' > .env.staging
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner
ana@dev:~/planner$ npm run build -- --mode staging > /dev/null
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner (staging)
```

The plain build did not read `.env.staging`, so its heading is the default. The staging build read it.
A value with spaces needs no quotes in the file: Vite takes everything after the `=` to the end of the
line.

## Which one wins

A `.local` file is for one machine: a value you want while developing, or one you should not commit.
Put one beside the staging file, and then set the same variable in the shell as well:

```
ana@dev:~/planner$ echo 'VITE_TITLE=Study planner (Ana)' > .env.staging.local
ana@dev:~/planner$ npm run build -- --mode staging > /dev/null
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner (Ana)
ana@dev:~/planner$ VITE_TITLE='Study planner (shell)' npm run build -- --mode staging > /dev/null
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner (shell)
```

`.env.staging.local` beat `.env.staging`, and the shell beat both. **That last rule is what a host
relies on**: the values typed into its dashboard reach the build as ordinary environment variables, so
they win over anything committed.

`git status` shows the other half of the table:

```
ana@dev:~/planner$ git status --short
?? .env.staging
```

`.env.staging` is waiting to be committed, and `.env.staging.local` is not listed at all: `*.local` in
`.gitignore` hides it. Commit the first and delete the second, which was only for this demonstration:

```
ana@dev:~/planner$ rm .env.staging.local
ana@dev:~/planner$ git add .env.staging
ana@dev:~/planner$ git commit -qm "A staging mode"
```

## And in development

`npm run dev` runs in `development` mode, so it reads `.env`, `.env.local`, `.env.development` and
`.env.development.local`, and never `.env.staging`. It reads them when the server starts, and it watches
them. With the server running in one terminal, write a file for development from a second one:

```
ana@dev:~/planner$ echo 'VITE_TITLE=Study planner (dev)' > .env.development.local
```

The first terminal shows Vite noticing, and restarting itself to pick the change up:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 275 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
7:40:38 PM [vite] .env.development.local changed, restarting server...
7:40:38 PM [vite] server restarted.
```

**That restart is the dev server's alone.** A build reads the files once, and a deployed site keeps the
value it was built with until the next build, whatever the files say by then.

Delete `.env.development.local` once you have seen it restart; no later lesson uses it.
