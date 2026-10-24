---
title: Creating the project, and a newer Node
version: 1
---

**Nuxt has its own project generator, `create-nuxt`, and it is run the way `create-vue` was in lesson
1**, through `npm create` with the version fixed. Stop the planner's dev server if it is running, and
from `~/vue`:

```
ana@dev:~/vue$ npm create nuxt@4.0.1 -- planner-nuxt --template minimal --packageManager npm --no-gitInit --no-install

> npx
> create-nuxt planner-nuxt --template minimal --packageManager npm --no-gitInit --no-install

┌  Welcome to Nuxt!
◇ Creating project in planner-nuxt
● Downloading minimal template...
◆ Downloaded minimal template
● Skipping install dependencies step.
◇ Created your project from the minimal template
Next steps:,› cd planner-nuxt,› npm install,› npm run dev
│
└  ✨ Happy building!
```

`--template minimal` is the smallest starting point Nuxt offers, `--no-gitInit` leaves version
control to you, and `--no-install` stops it from installing, because the next step installs with the
versions pinned. Without the options it asks the same questions one by one. The template is fetched
from Nuxt's repository the moment you run the command, so it is whatever Nuxt publishes that day;
every file of it this lesson keeps is shown whole below. Here is what it made:

```
ana@dev:~/vue/planner-nuxt$ find . -type f | sort
./.gitignore
./README.md
./app/app.vue
./nuxt.config.ts
./package.json
./public/favicon.ico
./public/robots.txt
./tsconfig.json
ana@dev:~/vue/planner-nuxt$ cat package.json
{
  "name": "planner-nuxt",
  "type": "module",
  "private": true,
  "scripts": {
    "build": "nuxt build",
    "dev": "nuxt dev",
    "generate": "nuxt generate",
    "preview": "nuxt preview",
    "postinstall": "nuxt prepare"
  },
  "dependencies": {
    "nuxt": "^4.6.2",
    "vue": "^3.5.44",
    "vue-router": "^5.4.0"
  }
}
```

Eight files, and no `node_modules` yet. The versions are ranges, `^4.6.2`, as `create-vue`'s were.

## Installing, and a warning to read

Pin them exactly, as in lesson 1:

```
ana@dev:~/vue/planner-nuxt$ npm install --save-exact nuxt@4.6.2 vue@3.5.44 vue-router@5.4.0
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: 'nuxt@4.6.2',
npm warn EBADENGINE   required: { node: '^22.22.3 || ^24.15.0 || >=26.0.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@nuxt/nitro-server@4.6.2',
npm warn EBADENGINE   required: { node: '^22.22.3 || ^24.15.0 || >=26.0.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@nuxt/vite-builder@4.6.2',
npm warn EBADENGINE   required: { node: '^22.22.3 || ^24.15.0 || >=26.0.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@nuxt/vite-server@4.6.2',
npm warn EBADENGINE   required: { node: '^22.22.3 || ^24.15.0 || >=26.0.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: 'cssnano@9.9.0',
npm warn EBADENGINE   required: { node: '^22.22.3 || ^24.15.0 || >=26.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: 'postcss-calc@11.2.3',
npm warn EBADENGINE   required: { node: '^22.22.3 || ^24.15 || >=26.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me

added 550 packages, and audited 552 packages in 16s

132 packages are looking for funding
  run `npm fund` for details

7 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

**The install worked, and six packages said they do not support the Node that ran it.** `EBADENGINE`
is npm reading each package's `engines` field, the Node versions its authors test on, and comparing it
with yours:

```
ana@dev:~/vue/planner-nuxt$ node --version
v22.22.0
ana@dev:~/vue/planner-nuxt$ npm view nuxt@4.6.2 engines.node
^22.22.3 || ^24.15.0 || >=26.0.0
```

`^22.22.3` means 22.22.3 or any later 22. The javascript course installed 22.22.0 in January, and Nuxt
4.6 needs at least three patch releases more. npm only warns, so everything may well run, and may
also fail in some corner nobody tested; the honest reading of the warning is *update Node*. It is
cheap here, because Node lives in one folder of yours, `~/.local/node`, and the links in
`~/.local/bin` point into it. The newest 22 on the day this was recorded is 22.23.4, a security
release. Download it, check it against the checksums Node publishes, and put it in place of the old
one:

```
ana@dev:~$ curl -fsSLO https://nodejs.org/dist/v22.23.4/node-v22.23.4-linux-x64.tar.xz
ana@dev:~$ curl -fsSL https://nodejs.org/dist/v22.23.4/SHASUMS256.txt | grep ' node-v22.23.4-linux-x64.tar.xz$' | sha256sum -c
node-v22.23.4-linux-x64.tar.xz: OK
ana@dev:~$ rm -rf ~/.local/node && mkdir ~/.local/node
ana@dev:~$ tar -xJf node-v22.23.4-linux-x64.tar.xz -C ~/.local/node --strip-components=1
ana@dev:~$ rm node-v22.23.4-linux-x64.tar.xz
ana@dev:~$ node --version
v22.23.4
ana@dev:~$ npm --version
10.9.9
```

**`OK` is the line to look for**: the file you downloaded has the SHA-256 that nodejs.org lists for
it, so it is the file Node released. On macOS the file is `node-v22.23.4-darwin-arm64.tar.gz` (or
`-darwin-x64` on an Intel Mac) and the command is `shasum -a 256 -c`; on Windows, the installer from
nodejs.org replaces the old version for you. Every lesson from here runs on 22.23.4, the Vite planner
included, whose own `engines` accepts it. Install again, so that npm records the new Node:

```
ana@dev:~/vue/planner-nuxt$ npm install

> postinstall
> nuxt prepare

◆ Types generated in .nuxt.

added 3 packages, and audited 555 packages in 2s

133 packages are looking for funding
  run `npm fund` for details

7 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

No warnings now. `nuxt prepare`, the `postinstall` script, wrote the generated types into `.nuxt`;
the auto-imports section looks inside.

## Seven high severity vulnerabilities

That line is in both installs, and it deserves the minute it takes to read:

```
ana@dev:~/vue/planner-nuxt$ npm audit
# npm audit report

node-forge  *
Severity: high
node-forge RSA PKCS#1 v1.5 signature verification accepts extra nested DigestAlgorithm elements - https://github.com/advisories/GHSA-86w9-cpqp-85rv
fix available via `npm audit fix --force`
Will install nuxt@4.1.3, which is a breaking change
node_modules/node-forge
  listhen  >=0.3.0
  Depends on vulnerable versions of node-forge
  node_modules/listhen
    nitropack  >=0.5.4
    Depends on vulnerable versions of listhen
    node_modules/nitropack
      @nuxt/nitro-server  >=3.20.0
      Depends on vulnerable versions of nitropack
      Depends on vulnerable versions of nuxt
      node_modules/@nuxt/nitro-server
        nuxt  3.20.0 - 3.21.11 || >=4.2.0
        Depends on vulnerable versions of @nuxt/nitro-server
        Depends on vulnerable versions of @nuxt/vite-builder
        Depends on vulnerable versions of @nuxt/vite-server
        node_modules/nuxt
          @nuxt/vite-builder  3.20.0 - 3.21.11 || >=4.2.0
          Depends on vulnerable versions of nuxt
          node_modules/@nuxt/vite-builder
          @nuxt/vite-server  >=4.6.0
          Depends on vulnerable versions of nuxt
          node_modules/@nuxt/vite-server

7 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force
```

**It is one advisory, counted seven times**: `node-forge`, and the six packages between it and `nuxt`,
each listed because it depends on the one below it. The advisory is about checking RSA signatures. The
package that uses `node-forge` here is `listhen`, the part of Nitro that opens the dev server's port,
and it uses it to *make* a certificate when you ask the dev server for HTTPS, which the planner never
does; nothing in the planner checks a signature with it. So the exposure is close to nothing, for now.
What not to do is the command it suggests: `npm audit fix --force` would install Nuxt **4.1.3**, back
past a fix 4.6.2 carries for an advisory about Nuxt's own route rules, one that covers every Nuxt up to
4.6.1, to remove a warning about a code path you do not use. The right move is to wait for Nitro to
update `node-forge` and to run `npm audit` again when you update Nuxt.

## The configuration, and the first page

The template's two files of substance:

```
ana@dev:~/vue/planner-nuxt$ cat nuxt.config.ts app/app.vue
// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true }
})
<template>
  <div>
    <NuxtRouteAnnouncer />
    <NuxtWelcome />
  </div>
</template>
```

`nuxt.config.ts` is to Nuxt what `vite.config.js` was to Vite, and Nuxt passes a `vite` option of it on
to Vite. `compatibilityDate` keeps the defaults of Nuxt and Nitro as they were on that date, so an
update that changes one does not change your project under you. Give it the planner's title, a language
for the page, as lesson 1 gave `index.html`, and turn the developer tools off, as lesson 1 removed
Vue's:

```typescript
// nuxt.config.ts: the study planner, made by Nuxt.
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  // Off, as lesson 1 left Vue's: a button and requests of their own in every page.
  devtools: { enabled: false },
  app: {
    head: { htmlAttrs: { lang: 'en' }, title: 'Study planner' },
  },
})
```

There is no `index.html` to edit any more: Nuxt writes the page's HTML itself, and `app.head` is how
you put something in its `<head>`. Start the dev server:

```
ana@dev:~/vue/planner-nuxt$ npm run dev

> dev
> nuxt dev

● Starting Nuxt...
● Nuxt 4.6.2 (with Nitro 2.13.5, Vite 8.3.5 and Vue 3.5.44)

  ➜ Local:    http://localhost:3000/
  ➜ Network:  use --host to expose

● Setting up modules
● Preparing app
● Generating types
● Bundling app
✔ Vite client built in 53ms
✔ Vite server built in 26ms
● Building server
[nitro] ✔ Nuxt Nitro server built in 1357ms
◆ Ready in 2.76s  → http://localhost:3000/
  config 255ms · modules 68ms · app 333ms · types 313ms · bundle 247ms · server 1.54s
(node:9550) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use node --trace-warnings ... to show where the warning was created)
```

**Port `3000`, not `5173`**, and more steps than Vite's dev server takes, because Nuxt generates the
routes and the types, builds a server and starts it before it serves anything. The last two lines are
the recording computer's: it reaches the internet through a proxy, and Node says so. Yours will not
print them. The welcome page:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text body
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of body
Welcome to Nuxt!
4.6.2
Get started

Remove this welcome page by replacing <NuxtWelcome/> in app.vue with your own code.

Documentation

We highly recommend you take a look at the Nuxt documentation to level up.

Modules

Discover our list of modules to supercharge your Nuxt project.

Examples

Explore different way of using Nuxt features and get inspired.

Deploy

Learn how to deploy your Nuxt project on different providers.

Nuxt GitHub Repository
Nuxt Discord Server
Nuxt on X
Nuxt Bluesky
Nuxt Linkedin
```

Two things in that transcript are new. `look` gets `--text body`, because a Nuxt app is not mounted on
`#app`. And it has **no `--clock`**, and from here on none of this course's transcripts do: a Nuxt page
is drawn by the server too, and the server's clock cannot be set from the browser. On the recording
computer the server and the browser were both set to 21 October 2026, 10:00, for these transcripts, so
they match the ones before them; on your computer the planner will show the week you are in, and the
dates in your transcripts will be yours. The `<Suspense>` line is information, not a warning: Nuxt wraps
every page in the `<Suspense>` of lesson 15, and Vue says in development that it is experimental.
