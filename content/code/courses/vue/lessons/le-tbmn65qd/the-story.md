---
title: Where Vite came from
version: 1
---

**Every page of the planner has reached the browser through Vite, from `npm run dev` in lesson 1 to the
build in lesson 16, and this lesson looks at it directly.** Evan You, who wrote Vue, wrote Vite in 2020,
and the name is the French word for *quick*. The planner has used Vite 8 all along:

```
ana@dev:~/vue/planner$ npx vite --version
vite/8.3.5 linux-x64 node-v22.22.0
```

## The problem it was written for

Before Vite, a Vue project was made by Vue CLI, which ran webpack. Webpack is a **bundler**: it reads
every file the application imports, follows each import to the next file, and joins the lot into one
or a few large files the browser can load. That was necessary, because browsers could not load modules
on their own for most of the 2010s, and it had a cost that grew with the project. The development
server bundled the whole application before it served the first page, and bundled again after every
saved file. On a large project, starting took a minute and a change took seconds to show.

By 2020 every browser in use could load ES modules natively, `<script type="module">` and `import`
included. Vite's idea was to **stop bundling during development**: serve each file as its own module,
when the browser asks for it, converted just enough for the browser to run it. Starting the server no
longer depends on the size of the application, because nothing is done until a page asks for a file,
and a change converts one file again rather than the bundle. For the build, where the browser should
fetch a few files instead of dozens, Vite still bundles. Vue CLI is in maintenance now, and `create-vue`,
the tool of lesson 1, makes Vite projects.

## Now used by everyone

The lesson's title is the measurable part. `create-vite` is Vite's own project generator, and its list
of templates is a list of the frameworks that build with it:

```
ana@dev:~/vue$ npm create vite@9.3.1 -- --help

> npx
> cva --help

Usage: create-vite [OPTION]... [DIRECTORY]

Create a new Vite project in JavaScript or TypeScript.
When running in TTY, the CLI will start in interactive mode.

Options:
  -t, --template NAME                   use a specific template
  -i, --immediate / --no-immediate      install dependencies and start dev
  --eslint / --no-eslint                use ESLint instead of Oxlint (only for React templates)
  --overwrite                           remove existing files if target directory is not empty
  --interactive / --no-interactive      force interactive / non-interactive mode
  -h, --help                            display this help message

Available templates:
vanilla-ts          vanilla
vue-ts              vue
react-ts            react
react-compiler-ts   react-compiler
preact-ts           preact
lit-ts              lit
svelte-ts           svelte
solid-ts            solid
qwik-ts             qwik
```

Vue is one line of nine. React, Preact, Lit, Svelte, Solid and Qwik are there too, each in JavaScript
and in TypeScript. Beyond that list, Nuxt is built on Vite (lesson 18), so is SvelteKit, and the
Angular CLI has used Vite as its development server since Angular 17. Vitest, the test runner of
lesson 21, is Vite running tests. A student who moves from this course to any of those keeps most of
what this lesson says.

## What Vite is made of

Vite is a development server, a build command and a plugin system around them, and the heavy work in
both is done by a bundler written in Rust, **Rolldown**. The planner has it already, installed by Vite:

```
ana@dev:~/vue/planner$ npm ls rolldown
planner@0.0.0 /home/ana/vue/planner
├─┬ vite@8.3.5
│ └── rolldown@1.2.15
└─┬ vue-router@5.4.0
  └─┬ unplugin@3.4.0
    └── rolldown@1.2.15 deduped
```

Earlier versions of Vite used two tools, esbuild for development and Rollup for the build, and a
project could behave a little differently in each. Vite 8 uses Rolldown for both. Rolldown keeps
Rollup's plugin interface, so most plugins written for Rollup over the years work with it, and the
planner's own plugin, at the end of this lesson, is written in that interface.
