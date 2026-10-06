---
title: An install runs code
version: 1
---

**A package can carry a script that the manager runs during installation, with your user's
permissions.** The `scripts` field that held `start` in section 02 also accepts
`preinstall`, `install` and `postinstall`, and those run when somebody installs the package.

They exist for good reasons. A package wrapping a library written in C compiles it for your
machine, and a package that needs a binary downloads the one for your system. But an install script
is a program from the internet that runs before you have read a line of it. In the attacks on the
npm ecosystem that made the news, an install script was usually where the code ran.
`secure-pipeline`, lesson 12, follows where a software supply chain breaks.

## Seeing one run

The lab's `shelf-banner` has a `postinstall` that does something harmless and visible: it writes a
file into the project that installed it.

```
ana@dev:~/js/scripts$ npm install shelf-banner

added 1 package in 564ms
ana@dev:~/js/scripts$ ls
banner-was-here.txt
node_modules
package-lock.json
package.json
ana@dev:~/js/scripts$ cat banner-was-here.txt
written by shelf-banner's postinstall, running as ana
```

**npm printed nothing about it.** By default npm hides the output of dependencies' install scripts,
so the only sign the script ran is the file it left behind. On a real package that file could have
been anywhere ana's user may write.

## Turning them off

`--ignore-scripts` installs the files and runs no package script:

```
ana@dev:~/js/scripts$ rm -rf node_modules banner-was-here.txt
ana@dev:~/js/scripts$ npm ci --ignore-scripts

added 1 package in 277ms
ana@dev:~/js/scripts$ ls
node_modules
package-lock.json
package.json
```

No file this time. The same switch can live in `.npmrc` as `ignore-scripts=true`, so every install
in the project gets it. The cost is that a package which really needs to compile something stops
working. When that happens, run its build on purpose, as a step somebody chose, with `npm rebuild
NAME`.

pnpm 10 runs no dependency's build scripts unless the project names it, and says what it skipped:

```
ana@dev:~/js/pnpm$ pnpm add shelf-banner
Progress: resolved 0, reused 1, downloaded 0, added 0
Packages: +1
+
Progress: resolved 3, reused 2, downloaded 1, added 1, done

dependencies:
+ shelf-banner 1.0.0

╭ Warning ─────────────────────────────────────────────────────────────────────╮
│                                                                              │
│   Ignored build scripts: shelf-banner@1.0.0.                                 │
│   Run "pnpm approve-builds" to pick which dependencies should be allowed     │
│   to run scripts.                                                            │
│                                                                              │
╰──────────────────────────────────────────────────────────────────────────────╯
Done in 638ms using pnpm v10.28.0
ana@dev:~/js/pnpm$ ls
node_modules
package.json
phantom.js
pnpm-lock.yaml
shelf.js
```

`pnpm approve-builds` asks which packages may run their scripts and writes the answer into
`package.json`, so the choice is reviewed like any other change. It is interactive, so it was not
run here.

Yarn 4 runs them by default, and `enableScripts: false` in `.yarnrc.yml` stops them:

```
ana@dev:~/js/yarn$ yarn add shelf-banner | cut -b5-
YN0000: · Yarn 4.10.3
YN0000: ┌ Resolution step
YN0085: │ + shelf-banner@npm:1.0.0
YN0000: └ Completed
YN0000: ┌ Fetch step
YN0013: │ A package was added to the project (+ 1.32 KiB).
YN0000: └ Completed
YN0000: ┌ Link step
YN0000: │ ESM support for PnP uses the experimental loader API and is therefore experimental
YN0007: │ shelf-banner@npm:1.0.0 must be built because it never has been before or the last one failed
YN0000: └ Completed
YN0000: · Done with warnings in 0s 326ms
ana@dev:~/js/yarn$ ls
banner-was-here.txt
package.json
phantom.js
shelf.js
yarn.lock
ana@dev:~/js/yarn$ rm banner-was-here.txt
ana@dev:~/js/yarn$ echo "enableScripts: false" >> .yarnrc.yml
ana@dev:~/js/yarn$ rm -rf .yarn/install-state.gz && yarn install | cut -b5- | grep YN0004
YN0004: │ shelf-banner@npm:1.0.0 lists build scripts, but all build scripts have been disabled.
ana@dev:~/js/yarn$ ls
package.json
phantom.js
shelf.js
yarn.lock
```

## What else protects you

- **the lockfile and `npm ci`**: a version cannot change under you between review and deploy, and
  the integrity hash catches a file that changed under the same version;
- **fewer dependencies**: each one is code and people you trust. A ten-line function is often
  cheaper to write than to depend on;
- **`npm audit`**: it sends the installed versions to the registry and lists known
  vulnerabilities with the version that fixes each. The lab's registry has no advisory database, so
  it was not run here. `secure-pipeline`, lesson 5, runs this kind of check in a pipeline, and
  `secure-code`, lesson 17, decides when to update and when to pin.
