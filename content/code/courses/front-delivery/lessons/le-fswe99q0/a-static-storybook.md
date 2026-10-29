---
title: A static Storybook, deployed like the planner
version: 1
---

**`npm run build-storybook` writes the whole workshop as a folder of static files, so it deploys exactly
the way lesson 1 deployed the planner.** It is a second site, built from the same repository, with its own
build command and its own output folder.

```
ana@dev:~/planner$ npm run build-storybook > /dev/null 2>&1 && ls storybook-static
_redirects
assets
courses.json
favicon-wrapper.svg
favicon.svg
iframe.html
index.html
index.json
nunito-sans-bold-italic.woff2
nunito-sans-bold.woff2
nunito-sans-italic.woff2
nunito-sans-regular.woff2
project.json
sb-addons
sb-common-assets
sb-manager
vite-inject-mocker-entry.js
```

`index.html` is Storybook's interface, `iframe.html` the frame a story is drawn in, `index.json` the list
of stories, and `assets` the bundled code. `courses.json` and `_redirects` came along because Storybook
copies the project's `public/` folder too; the `/*` rewrite in that `_redirects` would send a deep link
inside Storybook to its `index.html`, which is harmless here because Storybook's own addresses are query
strings rather than paths.

Serve it with the planner's host, on a port of its own:

```
ana@dev:~/planner$ node host.mjs storybook-static 6007
serving storybook-static on http://127.0.0.1:6007
```

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' 'http://127.0.0.1:6007/iframe.html?id=planner-session-row--done&viewMode=story'
200
```

## Publishing it

On any host from lesson 1, a Storybook is a second project from the same repository: build command
`npm run build-storybook`, output folder `storybook-static`. With previews turned on, every pull request
then gets a preview of the workshop beside the preview of the app, which is where a reviewer sees a
component change in every state at once instead of in the one screen they happened to click.

**Chromatic**, a service from Storybook's maintainers, does the same publishing and adds visual review:
it photographs every story on every push and asks a person to approve each change. It was not run for this
course; it needs an account, and the next section builds the same kind of check on your own computer.

## A design system's site

For a team, this folder is the design system's documentation site, and it deserves the same care as the
product: a stable address, HTTPS, a link from the repository's README. A workshop that only exists as
somebody's `npm run storybook` is gone when that person leaves.
