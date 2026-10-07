---
title: The lockfile
version: 2
---

**A range says what you accept. The lockfile says what was chosen.** Two people running
`npm install` a week apart, against the same `^1.1.0`, can get different versions, because a new
one may have been published in between. The lockfile is what makes them get the same one.

A second project, with the same `.npmrc`, installs `shelf-format`, a package that itself depends on
`shelf-slug`:

```
ana@dev:~/js/lock$ npm install shelf-format

added 2 packages in 615ms
ana@dev:~/js/lock$ npm ls --all
lock@1.0.0 /home/ana/js/lock
└─┬ shelf-format@1.0.0
  └── shelf-slug@1.2.0

```

Two packages were added for one request. `npm ls --all` shows why: `shelf-slug` is a dependency of
a dependency, a **transitive** dependency. Most of what sits in a real `node_modules` arrived this
way. A project with ten direct dependencies routinely has several hundred packages installed.

## package-lock.json

npm wrote `package-lock.json` beside `package.json`:

```
ana@dev:~/js/lock$ cat package-lock.json
{
  "name": "lock",
  "version": "1.0.0",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "lock",
      "version": "1.0.0",
      "dependencies": {
        "shelf-format": "^1.0.0"
      }
    },
    "node_modules/shelf-format": {
      "version": "1.0.0",
      "resolved": "http://127.0.0.1:4873/shelf-format/-/shelf-format-1.0.0.tgz",
      "integrity": "sha512-0Vcw5LvPhGg6uGZF6jMysJ3ZpK/Q9PJ3Ih7gpf7kUaLjtTDJkHnHVxqvg9urwC6CI+pRO7/X2KRo3JOAA+YSuA==",
      "license": "MIT",
      "dependencies": {
        "shelf-slug": "^1.1.0"
      }
    },
    "node_modules/shelf-slug": {
      "version": "1.2.0",
      "resolved": "http://127.0.0.1:4873/shelf-slug/-/shelf-slug-1.2.0.tgz",
      "integrity": "sha512-iios4bq90H+XUxwYltuRkxPOddIfhlfPiUifTJRj7/DrD9E4CEk3cc5KqI6G9RejgMyl/r8RPxtObpyoB2dflg==",
      "license": "MIT"
    }
  }
}
```

Every installed package has an entry with three things: the exact **version**, the address it was
**resolved** from, and an **integrity** hash of the downloaded file. The hash is what makes the
lockfile more than a list. The next install checks the file it downloads against it, and a file
that has changed since, even under the same name and version, is refused.

**Commit the lockfile.** It is what the build server and the next person to clone the project will
install from.

## npm ci

`npm install` reads `package.json`, may choose new versions inside the ranges, and updates the
lockfile. **`npm ci`** does neither. It deletes `node_modules`, installs exactly what the lockfile
names, and changes no file:

```
ana@dev:~/js/lock$ rm -rf node_modules
ana@dev:~/js/lock$ npm ci

added 2 packages in 331ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"package.json holds a range, ^1.1.0, which is what the project accepts. npm install resolves it to one version and writes that version, its address and its integrity hash into package-lock.json, then fills node_modules. npm ci reads only the lockfile, installs exactly what it names, and refuses when the lockfile and package.json disagree.\"><defs><marker id=\"lock-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"lock-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"180\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">package.json</text><text x=\"110.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&quot;shelf-slug&quot;: &quot;^1.1.0&quot;</text><rect x=\"270\" y=\"40\" width=\"200\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">package-lock.json</text><text x=\"370.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shelf-slug 1.2.0 + sha512</text><rect x=\"540\" y=\"40\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">node_modules/</text><text x=\"620.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shelf-slug 1.2.0</text><path d=\"M200 72 L266 72\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#lock-ah-phosphor)\"></path><path d=\"M470 72 L536 72\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#lock-ah-amber)\"></path><text x=\"233\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">install</text><text x=\"503\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ci</text><text x=\"110\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what you accept</text><text x=\"370\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what was chosen</text><text x=\"620\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what is there</text><rect x=\"170\" y=\"154\" width=\"380\" height=\"44\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">npm ci refuses if these two disagree,</text><text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">instead of choosing again</text></svg>", "caption": "The range says what you accept; the lockfile says what was chosen."}
```

That makes `npm ci` the command for anything automated: a build server, a deploy, a test run. If
the two files disagree, it stops instead of guessing. Here ana edits the range by hand and leaves
the lockfile behind:

```
ana@dev:~/js/lock$ npm pkg set dependencies.shelf-slug=^2.0.0
ana@dev:~/js/lock$ npm ci 2>&1 | head -n 6
npm error code EUSAGE
npm error
npm error `npm ci` can only install packages when your package.json and package-lock.json or npm-shrinkwrap.json are in sync. Please update your lock file with `npm install` before continuing.
npm error
npm error Invalid: lock file's shelf-slug@1.2.0 does not satisfy shelf-slug@2.0.0
npm error Missing: shelf-slug@1.2.0 from lock file
```

The fix is to run `npm install`, look at what changed in the lockfile, and commit both files
together. A lockfile change in a pull request deserves a reading, because it is the list of code
that will run on the next deploy.
