---
title: An adapter, and a server you can run
version: 1
---

**An adapter turns the build into something a particular kind of host can run.** SvelteKit's build is the
same for every host; the adapter is the last step, and it decides the shape of what comes out: a Node
server, a folder of static files, functions in the format a cloud platform expects. Lesson 1 ended on
`adapter-auto` saying it "could not detect a supported production environment", which is the right
answer on a laptop: it recognises cloud platforms, and a laptop is not one.

The planner reads and writes a file on the computer it runs on, so it needs one long-lived server with a
disk, and the adapter for that is **`adapter-node`**. Stop the dev server with Ctrl-C, since this lesson
uses that terminal for the built server, and swap the adapters, installing one and removing the other.
`.npmrc` has `save-exact=true` since lesson 1, so the version is written down exactly:

```
ana@dev:~/planner$ npm install --save-dev @sveltejs/adapter-node@6.0.0

added 1 package, removed 2 packages, changed 1 package, and audited 51 packages in 3s

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npm uninstall @sveltejs/adapter-auto

removed 1 package, and audited 50 packages in 469ms

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

The adapter is chosen in `vite.config.js`. The comments `sv` wrote about `adapter-auto` stop being true,
so they go. Replace the file:

```schooling-example
{"language": "javascript", "file": "vite.config.js", "parts": [
 {"code": "import adapter from '@sveltejs/adapter-node';\nimport { sveltekit } from '@sveltejs/kit/vite';\nimport { defineConfig } from 'vite';\n\nexport default defineConfig({\n\tplugins: [\n\t\tsveltekit({\n\t\t\tcompilerOptions: {\n\t\t\t\t// Force runes mode for the project, except for libraries. Can be removed in svelte 6.\n\t\t\t\trunes: ({ filename }) =>\n\t\t\t\t\tfilename.split(/[/\\\\]/).includes('node_modules') ? undefined : true\n\t\t\t},"},
 {"code": "\t\t\t// adapter-node builds a Node server: `npm run build`, then `node build`.\n\t\t\tadapter: adapter()\n\t\t})\n\t]\n});", "note": "The only change that matters: `adapter` is now `adapter-node`, imported on the first line."}
]}
```

Build it:

```
ana@dev:~/planner$ npm run build 2>&1 | tail -5

> Using @sveltejs/adapter-node
Copying assets
Compressing and hashing assets
✔ done
```

**`build` is a Node program.** `node build` runs `build/index.js`, which starts a server on port 3000 and
answers every request the way the dev server did, from code compiled once: no Vite, no compiling on
demand, no updates as you save. Start it in the second terminal:

```
ana@dev:~/planner$ node build
Listening on http://0.0.0.0:3000
```

and ask it for the week:

```
ana@dev:~/planner$ curl -s http://localhost:3000/ | grep -o '<title>.*</title>'
<title>225 min this week · Study planner</title>
```

It reads `data/planner.json` relative to the folder it was started in, as the dev server did, so `node
build` belongs in the project folder. A deployment copies `build`, `package.json` and the data folder
together and starts the server from where they are.

## A form that fails

Add a session on the built server, with JavaScript on:

```
ana@dev:~/planner$ look http://localhost:3000/courses/guitar --fill 'Date=2026-10-22' --click 'Add session'
-- fill Date=2026-10-22
-- click Add session
at /courses/guitar
title: 403 · Study planner
- main:
  - heading "Something went wrong" [level=1]
  - paragraph: Cross-site POST form submissions are forbidden
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

**A 403, and a sentence about cross-site forms.** The same form worked a minute ago on the dev server.
The next section is about why the built server refused it, and why it is right to.
