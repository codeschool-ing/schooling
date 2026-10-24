---
title: The package.json of a library
version: 1
---

**An app's `package.json` describes how to run it; a library's describes what it is to other code: its
name, its version, its entry points and which files it ships.** The planner's says `"private": true`,
which stops it ever being published by accident. The library's is meant to be published, so it carries
the fields a registry and a consumer read:

```schooling-example
{"language": "json", "file": "package.json", "parts": [
 {"code": "{\n  \"name\": \"@planner/ui\",\n  \"version\": \"0.1.0\",\n  \"description\": \"The study planner's design tokens and components.\",\n  \"type\": \"module\",", "note": "A **scoped** name: `@planner` is the scope, and a scope can be pointed at a registry of its own, which the section on publishing uses. `0.1.0` is a first version that promises little, as the section on versions explains. `type: module` says the JavaScript is ES modules."},
 {"code": "  \"exports\": {\n    \".\": {\n      \"types\": \"./dist/index.d.ts\",\n      \"default\": \"./dist/index.js\"\n    },\n    \"./tokens.css\": \"./dist/tokens.css\"\n  },", "note": "The entry points, and the only ones. `import { sessionRow } from \"@planner/ui\"` reaches `dist/index.js`, with its types from `index.d.ts`; `@import \"@planner/ui/tokens.css\"` reaches the stylesheet. Any other path inside the package is refused to a consumer, which keeps the private files private."},
 {"code": "  \"files\": [\"dist\"],\n  \"sideEffects\": [\"*.css\"],", "note": "`files` is what goes into the published package: the built folder, and nothing of the source, the scripts or the tests. `sideEffects` tells a bundler that importing a CSS file does something even when nothing is used from it, and that the JavaScript does not, so unused components can be dropped from a consumer's bundle."},
 {"code": "  \"scripts\": {\n    \"build\": \"node tokens.mjs && vite build && tsc && cp src/tokens.css dist/\"\n  }\n}", "note": "One build, in four steps: the tokens as CSS, the components bundled by Vite, the type declarations by `tsc`, and the stylesheet copied beside them."}
]}
```

## Why exports, and not main

Older packages say `"main": "index.js"` and let consumers import any file inside them by path. That makes
**every file a public interface**: a consumer who imported `@planner/ui/dist/components.js` breaks the day
the file is renamed, and the library's author had no way of knowing anybody did. `exports` turns that
around. What it lists is public; everything else is an error to import. A library with an `exports` map
can reorganise its files freely, because nobody could depend on them.

## A scope is a name, and an address

`@planner/ui` reads like an organisation and a package, and on the public npm registry that is what a
scope is: a namespace somebody owns. For an internal package it also matters for a practical reason: npm
can be told that one scope lives at one registry, and every other package at another. The section on
publishing uses exactly that, so the planner fetches `@planner/ui` from a private registry and everything
else from npm, without either knowing about the other.
