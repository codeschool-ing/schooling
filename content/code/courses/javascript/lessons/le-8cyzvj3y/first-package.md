---
title: A package and package.json
version: 2
---

**A package is a folder of code with a `package.json` that names it and gives it a version.** A
**registry** is a server that stores published packages and hands them out by name. The public one
is `registry.npmjs.org`; in this lesson it is the one you started in the previous section, on
your own computer, holding a few packages written for the lesson. A **package manager** is the program that talks to the registry,
downloads what you ask for and puts it where Node can find it.

## Pointing at a registry

Each project in this lesson lives in its own folder under `~/js`, and each has a `.npmrc`, the
settings file npm reads before anything else:

```ini
registry=http://127.0.0.1:4873/
audit=false
```

`registry` says where packages come from. `audit=false` stops npm from asking the registry for
security advisories on every install. Your registry has none to give, so the question would only
end in a warning. Without this file npm would go to the public registry, as it does in any folder
that has none.

## A first install

A project starts as a `package.json` with a name and a version. `"type": "module"` makes its `.js`
files ES modules, as lesson 9 explained, and `"private": true` means npm will refuse to publish it
by accident:

```json
{
  "name": "shelf",
  "version": "1.0.0",
  "type": "module",
  "private": true
}
```

```
ana@dev:~/js/first$ npm install shelf-slug@1

added 1 package in 488ms
ana@dev:~/js/first$ cat package.json
{
  "name": "shelf",
  "version": "1.0.0",
  "type": "module",
  "private": true,
  "dependencies": {
    "shelf-slug": "^1.2.0"
  }
}
ana@dev:~/js/first$ ls node_modules
shelf-slug
```

`npm install` did three things. It asked the registry which versions of `shelf-slug` exist and
picked one. It downloaded that version into **`node_modules`**, the folder Node looks in when an
import names a package. And it wrote the dependency into `package.json`.

`@1` asks for the newest `1.x`. Without it npm takes the newest of all, which here is `2.0.0`, and
the code below was written for `1.x`. The next section shows what happens when that line is
crossed.

What npm wrote is not `1.2.0` but **`^1.2.0`**, a range. The caret means "this version or any later
one that promises not to break it". The next section is about exactly that promise.

## Using it

An import that names a package rather than a path, with no `./` in front, is looked up in
`node_modules`:

```javascript
import { slug } from "shelf-slug";

console.log(slug("Grande Sertão: Veredas"));
```

```
ana@dev:~/js/first$ node slug.js
grande-sertao:-veredas
```

The accent is gone, which is what this version of the package does. The colon stays, because
nothing in it removes punctuation. A package does what its code does, not what its name suggests.

## Scripts

The `scripts` field of `package.json` names commands for the project, and `npm run NAME` runs one.
`start` and `test` are common enough that `npm start` and `npm test` work without `run`:

```
ana@dev:~/js/first$ npm pkg set scripts.start="node slug.js"
ana@dev:~/js/first$ npm start

> shelf@1.0.0 start
> node slug.js

grande-sertao:-veredas
```

npm printed the script before running it. Inside a script, the programs installed by your
dependencies are on the `PATH`, so a script can call a tool by name without `npx` or a path.
This is how most projects keep their build and test commands: in `package.json`, where a newcomer
finds them.

## Two kinds of dependency

`dependencies` are what the code needs to run. **`devDependencies`** are what you need only while
working on it: a test runner, a linter, a bundler. `npm install --save-dev NAME` puts a package in
the second list. When someone installs your published package, npm fetches its `dependencies` and
skips its `devDependencies`. Your registry has no test runner to show this with, so it is not run
here. The `node` course, in lesson 4, takes `package.json` and its scripts further on the
server side.
