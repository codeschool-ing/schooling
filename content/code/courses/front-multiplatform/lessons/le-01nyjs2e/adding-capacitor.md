---
title: Adding Capacitor to the planner
version: 1
---

**Capacitor is two npm packages and one configuration file**, added to the project you already
have. Nothing about the planner moves: `src/`, `public/` and `npm run build` stay exactly as lesson 1
left them, and Capacitor sits beside them. Start from a clean tree, so that `git status` shows only
what Capacitor adds. Lesson 1 installed Playwright and saved `look.mjs` after its commit, so commit
those first:

```
ana@dev:~/planner$ git status --short
 M package-lock.json
 M package.json
?? look.mjs
ana@dev:~/planner$ git add look.mjs package.json package-lock.json
ana@dev:~/planner$ git commit -q -m "Look at the planner from the terminal"
```

## The two packages

**`@capacitor/core` is the part your app imports**, the JavaScript half of the bridge, so it is an
ordinary dependency. **`@capacitor/cli` is the `cap` command** you run at the terminal, and nothing
in the app imports it, so it goes in with `-D`. Both at the same version, the current one when this
course was recorded, and both pinned:

```
ana@dev:~/planner$ npm install -E @capacitor/core@8.5.3

added 2 packages, and audited 23 packages in 440ms

found 0 vulnerabilities
ana@dev:~/planner$ npm install -E -D @capacitor/cli@8.5.3
npm warn deprecated uuid@7.0.3: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).

added 95 packages, and audited 118 packages in 2s

3 moderate severity vulnerabilities

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

The deprecation line and the three moderate vulnerabilities are in packages the command-line tool
depends on, not in anything the app ships: a `-D` package runs on your computer and never reaches
the phone. `npm audit` lists them. **Do not run `npm audit fix --force`** on a project like this one:
it is allowed to move packages across major versions, and that is how two Capacitor packages end up
at versions that do not match.

## `cap init`

`npx cap init` asks for three things, and they can be given on the line:

```
ana@dev:~/planner$ npx cap init "Study planner" com.example.studyplanner --web-dir dist
✔ Creating capacitor.config.ts in /home/ana/planner in 1.61ms
[success] capacitor.config.ts created!

Next steps: 
https://capacitorjs.com/docs/getting-started#where-to-go-next
ana@dev:~/planner$ cat capacitor.config.ts
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.example.studyplanner',
  appName: 'Study planner',
  webDir: 'dist'
};

export default config;
```

- **`appName`** is what the phone shows under the icon, and it can be changed later.
- **`appId`** is the app's identity in both stores, written backwards like a domain:
  `com.example.studyplanner`. **Choose it once.** A store treats an app with another `appId` as a
  different app, with no reviews, no installs and no update path from the old one. Use a domain you
  control. `com.example` is reserved for examples, and Google Play refuses it at upload, which is fine
  for a course and wrong for anything you publish.
- **`webDir`** is the folder Capacitor copies into the native projects, and for Vite that is `dist`.
  A wrong one is the most common first failure: the app opens to a white screen, because the folder
  it copied holds no `index.html`.

The file is TypeScript because the `cap` command reads it with types: an option misspelt in it is
an error in your editor before it is a puzzle on a phone. It grows in lesson 4, when plugins take
their settings from it, and in the last section of this lesson.
