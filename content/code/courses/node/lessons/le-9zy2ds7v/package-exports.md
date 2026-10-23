---
title: What a package lets you import
version: 1
---

**A package's `package.json` can list exactly which files may be imported, under which names, and
which file each kind of importer gets.** That list is the `exports` field. Without it, any file in the
package is reachable by its path; with it, only what it names is, and everything else is refused.

To see it work without installing anything, make a small package by hand in `node_modules`, the way
npm would have unpacked it:

```
ana@dev:~/server/modules/pkg$ mkdir -p node_modules/tidy/dist node_modules/tidy/src
```

and give it this `package.json`, in `node_modules/tidy/`:

```json
{
  "name": "tidy",
  "version": "1.0.0",
  "exports": {
    ".": {
      "import": "./dist/tidy.mjs",
      "require": "./dist/tidy.cjs"
    },
    "./words": "./dist/words.mjs"
  }
}
```

Two names are exported. **`"."` is the package itself**, `tidy`, and it is given as **conditions**:
an `import` gets the ES module build and a `require` gets the CommonJS build. **`"./words"`** is a
*subpath*, `tidy/words`, mapped to one file. The three files it names are one line each, and `src` gets a
fourth that the list does not name. Write them, then ask for each:

```
ana@dev:~/server/modules/pkg$ echo 'exports.kind = "CommonJS build";' > node_modules/tidy/dist/tidy.cjs
ana@dev:~/server/modules/pkg$ echo 'export const kind = "ES module build";' > node_modules/tidy/dist/tidy.mjs
ana@dev:~/server/modules/pkg$ echo 'export const words = (s) => s.split(/\s+/).length;' > node_modules/tidy/dist/words.mjs
ana@dev:~/server/modules/pkg$ echo 'module.exports = "private";' > node_modules/tidy/src/internal.js
ana@dev:~/server/modules/pkg$ node -p 'require("tidy").kind'
CommonJS build
ana@dev:~/server/modules/pkg$ node --input-type=module -e 'import { kind } from "tidy"; console.log(kind)'
ES module build
ana@dev:~/server/modules/pkg$ node --input-type=module -e 'import { words } from "tidy/words"; console.log(words("three words here"))'
3
ana@dev:~/server/modules/pkg$ node -p 'require("tidy/src/internal.js")' 2>&1 | grep -E '^Error|code:'
Error [ERR_PACKAGE_PATH_NOT_EXPORTED]: Package subpath './src/internal.js' is not defined by "exports" in /home/ana/server/modules/pkg/node_modules/tidy/package.json
  code: 'ERR_PACKAGE_PATH_NOT_EXPORTED'
```

**The same name gave two different files to two kinds of importer**, which is how one package
supports both module systems. And `src/internal.js` exists on disk and is still refused:
`ERR_PACKAGE_PATH_NOT_EXPORTED`. That refusal is the point. Whatever a package keeps out of
`exports` is its own business, free to change in any release without breaking you, because you could
never import it.

Two things follow when you use a package:

- **an import that worked by reaching into a package's folder can stop working when the package adds
  `exports`**, and the fix is to import what it exports, not to work round the refusal;
- **the conditions decide which build you run.** The two builds of one package are two modules with
  two states, the problem the previous section warned about; a package that offers both is careful to
  keep its state in one of them.

## imports, for your own project

The mirror field, `imports`, gives names to files **inside your own project**, and its names must
start with `#`. In a project's `package.json`:

```json
{
  "imports": {
    "#config": "./src/config.js"
  }
}
```

`import config from "#config"` then works from any file in the project, at any depth, instead of
`"../../config.js"` counted by hand. It is optional, and this course writes plain relative paths;
you will meet `#` names in larger projects and now know what they are.
