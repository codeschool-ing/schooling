---
title: A second project, with a server in it
version: 1
---

**Everything the planner has done so far happens in the browser.** Vite sends JavaScript, the browser
runs React, and React asks the API for data once it is running. A **Server Component** turns part of
that around: the component runs on a server, fetches what it needs there, and sends the browser the
result. React defines what a Server Component is; to have one, you need a framework that runs React on
a server, and the one most projects use for that is **Next.js**.

Next.js gets a project of its own, next to `~/planner`, so the Vite planner stays as it is. From your
home folder:

```
ana@dev:~$ npx create-next-app@16.4.3 planner-next --ts --app --empty --no-tailwind --no-eslint --no-biome --no-react-compiler --no-src-dir --no-rspack --no-agents-md --import-alias "@/*" --use-npm --disable-git --no-agent-feedback
npm warn exec The following package was not found and will be installed: create-next-app@16.4.3

Using defaults for unprovided options:

  --cache-components      Cache Components (use --no-cache-components for No Cache Components)

Creating a new Next.js app in /home/ana/planner-next.

Using npm.

Initializing project with template: app-empty 


Installing dependencies:
- next
- react
- react-dom

Installing devDependencies:
- @types/node
- @types/react
- @types/react-dom
- typescript


added 30 packages, and audited 31 packages in 8s

6 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities

Generating route types...
✓ Types generated successfully

Skipping git initialization.

Success! Created planner-next at /home/ana/planner-next
```

The flags answer every question `create-next-app` would otherwise ask: TypeScript, the **App Router**
(the `app/` folder, which is where Server Components live), and an empty template with no Tailwind, no
linter and no extra files, so that `app/` starts with two small files and nothing else. One
option was left to its default, and it says so: **Cache Components**, which this lesson meets in its
second section. What came out:

```
ana@dev:~/planner-next$ cat package.json next.config.ts && ls app
{
  "name": "planner-next",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "16.4.3",
    "react": "19.3.0",
    "react-dom": "19.3.0"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "typescript": "^5"
  }
}
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  cacheComponents: true,
  partialPrefetching: true,
};

export default nextConfig;
layout.tsx
page.tsx
```

Two things to fix before anything else:

- **Versions.** `next`, `react` and `react-dom` are exact, but the four development packages are
  ranges, such as `^5`. A range is a different install on a different day. Pin them to the versions the
  planner uses, with `save-exact` set for this project as lesson 1 set it for the other:

```
ana@dev:~/planner-next$ printf 'save-exact=true\n' > .npmrc && npm install --save-dev @types/node@22.20.5 @types/react@19.3.0 @types/react-dom@19.3.0 typescript@6.0.3

added 3 packages, changed 2 packages, and audited 34 packages in 2s

8 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner-next$ grep -A 5 devDependencies package.json
  "devDependencies": {
    "@types/node": "22.20.5",
    "@types/react": "19.3.0",
    "@types/react-dom": "19.3.0",
    "typescript": "6.0.3"
  }
```

- **Telemetry.** Next.js sends anonymous usage data to its makers unless you tell it not to, and it says
  so the first time it runs on a machine. `npx next telemetry disable` turns it off for your user. The
  transcripts in this course were recorded with it off, which is why that first notice is not in them.

Start the development server, in a terminal of its own like Vite's. It listens on port 3000, so it does
not collide with the Vite planner on 5173 or the API on 3001:

```

> planner-next@0.1.0 dev
> next dev

▲ Next.js 16.4.3 (Turbopack)
- Local:         http://localhost:3000
- Network:       http://192.0.2.2:3000
✓ Ready in 362ms
✓ Running next.config.ts took 35ms
- Cache Components enabled
- Partial Prefetching enabled
```

**Turbopack** is Next.js's bundler, which plays the part Vite plays in the other project. The last two
lines repeat what `next.config.ts` enabled. Then the page:

```
ana@dev:~/planner-next$ look http://localhost:3000/
[HMR] connected
- main: Hello world!
- alert
```

`[HMR] connected` is the development server's hot reload, the same thing Vite does. The empty `alert`
at the end is Next.js's own: it uses that region to announce the new page to a screen reader after a
navigation that does not reload the page, which a normal link does by itself.
