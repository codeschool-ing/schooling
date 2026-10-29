---
title: The check that refused the form
version: 1
---

**Any web page can contain a form that posts to the planner.** A page on another site, opened in the
same browser, can hold `<form method="POST" action="http://localhost:3000/courses/guitar?/add">` with
hidden fields and a script that submits it the moment the page loads. The browser sends it, and an action
that trusted every `POST` would save a session the student never asked for. On a site where the person
is logged in, the same trick changes a password or moves money. Browsers now hold back most cookies on
such a request, which blunts it, but not all, and not in every browser. The attack is called **cross-site request forgery**, CSRF.

**SvelteKit refuses a form posted from another site.** A browser that sends a form says where the page
that sent it came from, in a header called `Origin`. In a build, SvelteKit compares that with its own
origin, the scheme, host and port the server believes it is answering on, and if they differ, it answers
403 without running the action. The dev server does not check, which is why the form worked there.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A page on another site, elsewhere.example, holds a hidden form that posts to the planner at localhost 3000. The browser sends the POST with an Origin header saying https://elsewhere.example. The planner&#x27;s server compares it with its own origin, http://localhost:3000, finds they differ, and answers 403 without running the action. A form on the planner&#x27;s own page sends the planner&#x27;s origin and is let through.\"><rect x=\"20\" y=\"30\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"130\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">elsewhere.example</text><text x=\"130\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a hidden form, sent on load</text><rect x=\"20\" y=\"140\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">localhost:3000</text><text x=\"130\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the planner's own form</text><rect x=\"480\" y=\"85\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the planner's server</text><text x=\"590\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Origin === http://localhost:3000 ?</text><line x1=\"240\" y1=\"65\" x2=\"478\" y2=\"108\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"478.0,108.0 470.2,109.8 471.3,103.6\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">Origin: https://elsewhere.example</text><line x1=\"240\" y1=\"175\" x2=\"478\" y2=\"132\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"478.0,132.0 471.3,136.4 470.2,130.2\" fill=\"var(--phosphor)\"></polygon><text x=\"360\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">Origin: http://localhost:3000</text><text x=\"590\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">no: 403, the action never runs</text><text x=\"590\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">yes: the action runs</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the browser writes the Origin header itself; a page cannot set it</text></svg>", "caption": "A form from another site carries that site's origin, and a built SvelteKit server refuses it."}
```

The built server refused the planner's own form because it believes the wrong thing about itself. It
was asked for `http://localhost:3000`, but `adapter-node` cannot tell from a request whether the
connection was encrypted, so it assumes `https`, which is right for the usual deployment: the Node
server sits behind a proxy that holds the certificate and talks to visitors over HTTPS. On this
computer there is no proxy, the origin the browser sends is `http://localhost:3000`, and the two do not
match.

## Telling the server where it lives

**`paths.origin`** in the configuration says what the origin is, instead of letting the server work it
out. Read it from an environment variable, so that each place the planner is built for can give its
own. Replace `vite.config.js`:

```schooling-example
{"language": "javascript", "file": "vite.config.js", "parts": [
 {"code": "import adapter from '@sveltejs/adapter-node';\nimport { sveltekit } from '@sveltejs/kit/vite';\nimport { defineConfig } from 'vite';\n\nexport default defineConfig({\n\tplugins: [\n\t\tsveltekit({\n\t\t\tcompilerOptions: {\n\t\t\t\t// Force runes mode for the project, except for libraries. Can be removed in svelte 6.\n\t\t\t\trunes: ({ filename }) =>\n\t\t\t\t\tfilename.split(/[/\\\\]/).includes('node_modules') ? undefined : true\n\t\t\t},\n\n\t\t\t// adapter-node builds a Node server: `npm run build`, then `node build`.\n\t\t\tadapter: adapter(),"},
 {"code": "\t\t\t// The address the planner is served at, given when it is built:\n\t\t\t//   ORIGIN=http://localhost:3000 npm run build\n\t\t\tpaths: { origin: process.env.ORIGIN }\n\t\t})\n\t]\n});", "note": "`vite.config.js` runs when the build starts, so the variable is read then, and the value is built in. When it is not set, the server works the origin out from each request, as before."}
]}
```

Stop the server with Ctrl-C, build again with the origin given, and start it again:

```
ana@dev:~/planner$ ORIGIN=http://localhost:3000 npm run build > /dev/null 2>&1; echo $?
0
```

```
ana@dev:~/planner$ look http://localhost:3000/courses/guitar --fill 'Date=2026-10-22' --click 'Add session' --wait 500 | head -6
-- fill Date=2026-10-22
-- click Add session
-- wait 500
at /courses/guitar?week=2026-10-19
title: Guitar · Study planner
- main:
```

The form works. A form from somewhere else still does not, and neither does a request that does not say
where it came from, which is what a script outside any browser looks like:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Accept: text/html' -H 'Origin: https://elsewhere.example' -d 'date=2026-10-23&minutes=30' 'http://localhost:3000/courses/guitar?/add'
403
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Accept: text/html' -d 'date=2026-10-23&minutes=30' 'http://localhost:3000/courses/guitar?/add'
403
```

**The check is worth keeping exactly as it is.** SvelteKit has an option, `csrf.trustedOrigins`, for
listing other sites that may post forms, which an application with a separate payment provider or
login page sometimes needs. Listing `'*'` there turns the protection off, and the advice for a 403 like
the one above is never to reach for it: the cause is a server that does not know its own address, and
the cure is to tell it.
