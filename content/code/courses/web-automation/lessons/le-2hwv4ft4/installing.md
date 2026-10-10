---
title: Installing it, and the half that downloads separately
version: 1
---

**Cypress installs in two halves, and only the first comes from npm.** The `cypress` package in
`node_modules` is a small command-line program. The part that does the work is the Cypress
application: a build of Electron, the browser Cypress ships inside itself, with the runner and the
server in it. The package fetches that from Cypress's own download server after npm has finished,
and keeps it in a cache folder in your home directory, outside the project, shared by every
project that uses the same version.

## The project, with all three tools

`package.json` gains Cypress beside Playwright and the Selenium of lesson 8, each pinned to an
exact version so that what you install is what these lessons describe. Nothing else in the project
changes. Save it as `package.json`:

```json
{
  "name": "quitanda",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node app/server.js",
    "test": "playwright test"
  },
  "devDependencies": {
    "@playwright/test": "1.56.0",
    "cypress": "16.1.1",
    "selenium-webdriver": "4.51.0"
  }
}
```

On your own computer, the command is the ordinary one, and it is the download at the end of it
that matters:

```sh
npm install
```

The transcripts come from a machine that cannot reach Cypress's download server, so they were
recorded with the download switched off. `CYPRESS_INSTALL_BINARY=0` is the switch, and it is a
real one: a build server that only runs Playwright uses it to keep the download out of every run.

```
%%CAP npm-install%%
```

The package is there. Ask it what is installed and it says so, half by half:

```
%%CAP cypress-version%%
```

**`not installed` on the second line is the state a failed download leaves behind**, and it is
easy to miss, because `npm install` itself finished without a complaint. What you see on your own
machine, after a download that worked, is the binary's version on that line instead; it was not
run here, so it is not shown.

## Checking it, and what a missing binary says

`npx cypress verify` starts the binary once, without running a test, to prove it can. It is the
quickest way to find out whether the download worked, and with no binary it says this:

```
%%CAP cypress-verify%%
```

Read it from the line that names the problem: **no version of Cypress is installed** in a folder
named after the version, `16.1.1`. That folder is the cache. Upgrade the package and the path
changes with it, and the binary you downloaded for the old version no longer counts, the same
trap lesson 1 showed for Playwright's browsers.

The fix it suggests, `npx cypress install`, fetches the binary again. Here is that command on a
machine that cannot reach the download server at all. On a build server, where the variable `CI`
is set, Cypress prints its progress as plain lines rather than a spinner, which is the form shown:

```
%%CAP cypress-install-fails%%
```

`ENOTFOUND` means the name `download.cypress.io` could not be looked up: no network, or a network
that does not let the name through. **Behind a company proxy**, the package reads `HTTP_PROXY`
from the environment before downloading. Where the server is blocked altogether,
`CYPRESS_DOWNLOAD_MIRROR` points it at a copy somebody keeps inside the network, and
`CYPRESS_INSTALL_BINARY` can name a zip file of the binary that was fetched another way. Each of
these names appears in the package's own code; none of them was exercised here.

## Telling Cypress where things are

Cypress reads `cypress.config.js` at the project's root. Three settings are all this lesson
needs: the shop's address, so a test can write `cy.visit('/')`; where the spec files are, so
Cypress never wanders into the Playwright tests in `tests/`; and that this project has no support
file, the file Cypress otherwise loads before every spec for shared commands. Because
`package.json` says `"type": "module"`, the file uses `import` and `export`, like the rest of the
project. Save it as `cypress.config.js`:

```javascript
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.js',
    // No support file: this course writes no custom commands.
    supportFile: false,
  },
});
```

**Cypress does not start the shop for you.** Playwright's configuration has a `webServer` that
does; Cypress expects the application to be running already, at `baseUrl`. So a Cypress session
on your machine takes two terminals: `npm start` in one, and the Cypress command in the other.
