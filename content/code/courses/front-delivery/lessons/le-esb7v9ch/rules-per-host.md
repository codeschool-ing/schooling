---
title: The planner's rules, for each host
version: 1
---

**The planner needs two rules wherever it is served: old `/courses/` addresses redirect to `/course/`,
and every other path is answered with `index.html`.** Each host takes them in its own file and syntax,
and one takes neither. **None of these files was run on its host for this course**; the first one is what
`host.mjs` ran in the last two sections, and the others follow each host's documentation.

## Netlify

`public/_redirects` exactly as it stands, copied into `dist/` by the build:

```
# public/_redirects
/courses/* /course/:splat 301
/* /index.html 200
```

Netlify applies a rule only when no file matches the path, so `/*` never swallows a real script. The same
two rules can live in `netlify.toml` instead, as `[[redirects]]` tables, if you prefer one file for all of
Netlify's settings.

## Cloudflare Pages

The same `_redirects` format, with two differences that matter here. A site with **no top-level
`404.html`** is treated as a single-page app by default: Cloudflare's documentation says any path that is
not a file is answered with the root page. So the planner needs only the first line there. And its
documentation says redirects are followed **whether or not a file matches**, which is the opposite of
Netlify's rule. A broad `/*` line is the kind of rule that difference turns into a problem, which is
another reason to leave the second line out on Cloudflare.

## Vercel

`vercel.json` at the root of the repository, in Vercel's own syntax. `:id` is a named parameter, and
`permanent: true` asks for a permanent redirect:

```json
{
  "redirects": [{ "source": "/courses/:id", "destination": "/course/:id", "permanent": true }],
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

Vercel checks the files of the deployment before it applies rewrites, so the catch-all leaves the real
scripts alone, as Netlify's does.

## GitHub Pages

No rules file, so no redirect for the old addresses and no rewrite. The workflow from lesson 1 gains one
step after the build, the `404.html` copy from the last section:

```yaml
      - name: Serve the app for unknown paths
        run: cp dist/index.html dist/404.html
```

The old `/courses/` links can only be redirected by the app itself, in the browser: a few lines in
`main.ts` that notice the old shape and call `history.replaceState` with the new one. That works for
people and does nothing for search engines, which see the 404.

## Choosing, again

| | old addresses | deep links |
|---|---|---|
| Netlify | a 301 | a rewrite, status 200 |
| Cloudflare Pages | a 301 | the default single-page behaviour, status 200 |
| Vercel | a 308 | a rewrite, status 200 |
| GitHub Pages | only in the app's own code | `404.html`, status 404 |

This is lesson 1's last section from the other side: **the files are portable, the rules are not**, and an
app with real paths is the kind of app whose rules matter most.
