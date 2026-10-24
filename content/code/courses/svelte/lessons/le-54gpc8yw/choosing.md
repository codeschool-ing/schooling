---
title: Choosing an adapter
version: 1
---

**`adapter-static` writes every page to a file at build time, and the result needs no server at all**,
only something that hands out files: GitHub Pages, an object store, any web server. It is the adapter
for a site whose every page can be prerendered. The planner is not one, and the clearest way to see
what that means is to ask it anyway. Install it:

```
ana@dev:~/planner$ npm install --save-dev @sveltejs/adapter-static@4.0.0

added 1 package, removed 1 package, and audited 51 packages in 2s

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

and, for a moment, use it instead. Replace `vite.config.js`:

```schooling-example
{"language": "javascript", "file": "vite.config.js", "parts": [
 {"code": "import adapter from '@sveltejs/adapter-static';\nimport { sveltekit } from '@sveltejs/kit/vite';\nimport { defineConfig } from 'vite';\n\nexport default defineConfig({\n\tplugins: [\n\t\tsveltekit({\n\t\t\tcompilerOptions: {\n\t\t\t\t// Force runes mode for the project, except for libraries. Can be removed in svelte 6.\n\t\t\t\trunes: ({ filename }) =>\n\t\t\t\t\tfilename.split(/[/\\\\]/).includes('node_modules') ? undefined : true\n\t\t\t},\n\n\t\t\t// A trial: adapter-static writes every page to a file, or refuses to build.\n\t\t\tadapter: adapter(),\n\n\t\t\t// The address the planner is served at, given when it is built:\n\t\t\t//   ORIGIN=http://localhost:3000 npm run build\n\t\t\tpaths: { origin: process.env.ORIGIN }\n\t\t})\n\t]\n});", "note": "A trial. The import and the comment above `adapter()` are the only changes."}
]}
```

```
ana@dev:~/planner$ npm run build 2>&1 | grep -A3 'adapter-static:'
@sveltejs/adapter-static: all routes must be fully prerenderable, but found the following routes that are dynamic:
  - src/routes/(planner)
  - src/routes/(planner)/courses/[id=slug]
```

**Two routes that are dynamic**, the week and the course pages, which is the previous section's answer
from a different direction. The rest of its message lists the ways out, and every one of them gives up
something the planner needs: a `fallback` page turns the planner into a single-page application that
renders in the browser, with no forms that work without JavaScript and no server to post them to.
Put `vite.config.js` back as "The check that refused the form" left it, with `adapter-node`, and
remove the trial:

```
ana@dev:~/planner$ npm uninstall @sveltejs/adapter-static

removed 2 packages, and audited 50 packages in 478ms

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

## The question that chooses

**Where does the data live, and what can the host keep between two requests?** The rest follows:

| adapter | what it produces | suits |
|---|---|---|
| `adapter-node` | one Node server, which runs until it is stopped | an application with a server, on a machine or a container you run, with a disk if it needs one: the planner |
| `adapter-static` | a folder of HTML, CSS and JavaScript | a site whose every page is the same for everybody: documentation, a blog, a portfolio |
| `adapter-vercel`, `adapter-netlify`, `adapter-cloudflare` | functions in the platform's own format, started for a request and stopped after it | an application whose data is in a database or a service, never in a file beside the code |
| `adapter-auto` | whichever of the last row it detects | starting a project before choosing |

The third row is where the planner as written would break quietly: a function in those platforms can
often write a file, and the file is gone when the function stops, or is never seen by the next copy of
it. The queue in `src/lib/server/planner.js` would be no help either, since each copy has its own. That
is not a defect of those platforms. It is the same lesson as lesson 14's note on databases, met at
deployment instead of in the code: a planner that more than one person uses keeps its sessions in a
database, and then any of the adapters above that can run a server will do.
