---
title: What comes in the box, and what it weighs
version: 1
---

**Angular is a framework in the full sense: the router, forms, HTTP, testing, server rendering and
the command-line tool that ties them together are its own, released together, at one version.** The
planner used all of them, and every one came from `@angular/` and moved with `ng update`. React is a
library for the view, and the rest is chosen: a router, a data-fetching library, a form library, a
framework such as Next.js for server rendering. Vue and Svelte sit between: each has an official
router and an official full framework, Nuxt and SvelteKit, but they are separate projects.

| | Angular | React | Vue | Svelte |
| --- | --- | --- | --- | --- |
| routing | `@angular/router` | chosen: React Router, or Next.js | Vue Router, official | SvelteKit, official |
| forms | `@angular/forms`, two kinds | chosen, or by hand | `v-model`, and a library for validation | `bind:`, and SvelteKit's form actions |
| HTTP | `HttpClient`, interceptors, `httpResource` | `fetch`, or a library such as React Query | `fetch`, or Nuxt's `useFetch` | `fetch`, in SvelteKit's `load` |
| server rendering | `@angular/ssr`, lesson 23 | Next.js | Nuxt | SvelteKit |
| dependency injection | built in, lesson 10 | none; context for passing values down | `provide` and `inject` | context |
| project tool | the Angular CLI | Vite, or the framework's | Vite, or Nuxt's | Vite, or SvelteKit's |

**The box has a cost, and part of it is in the page.** Build the four cards for production:

```
ana@dev:~/compare$ for p in react vue svelte; do (cd $p && npm run build > /dev/null); done; (cd angular && npx ng build > /dev/null)
```

and weigh each one's JavaScript, as it is and compressed the way a server sends it:

```
ana@dev:~/compare$ for f in react/dist/assets/*.js vue/dist/assets/*.js svelte/dist/assets/*.js angular/dist/angular/browser/main-*.js; do printf "%-48s %7d bytes, %6d gzipped\n" $f $(wc -c < $f) $(gzip -9c $f | wc -c); done
react/dist/assets/index-DwWj_paF.js               220160 bytes,  67959 gzipped
vue/dist/assets/index-DNFEJ_tG.js                  64641 bytes,  25078 gzipped
svelte/dist/assets/index-DUPjO2ko.js               33776 bytes,  13278 gzipped
angular/dist/angular/browser/main-XUCHBYB5.js     106457 bytes,  35520 gzipped
```

The same card, the same behaviour, and, compressed, a factor of five between the lightest and the
heaviest.
**Most of each number is the framework, not the card**: React's 68 kB compressed is React and
React DOM, whatever the page holds, and the card adds a few hundred bytes to it. Svelte is lightest
because it compiled most of its work into the card itself, and keeps only a small runtime; that
advantage shrinks as an application grows, since each component carries its own compiled update code.
Angular's is in the middle. The planner, with the router, forms, Material and everything else of
this course, weighed 344 kB before compression in lesson 23, the course's pages loaded separately.

So the number is a fixed cost paid once per visit, and for an application a person opens to work in
all day, it is rarely what decides. For a page somebody finds through a search on a slow phone,
once, it can be.

## Where the other three are taught

The other framework courses of this track end with this same lesson, from their own side, with the
same card:

- **`react-ts`**, 24 lessons. Its lesson 1 is *why React is a library where Angular is a framework,
  and what you assemble yourself*, the table above from the other end; its lesson 18 is Next.js.
- **`vue`**, 22 lessons. Its lesson 2 compares its reactivity with React's, its lesson 17 is Vite,
  and lessons 18 to 20 are Nuxt.
- **`svelte`**, 20 lessons. Its lesson 1 is the compiler as the framework, and its lesson 14, form
  actions that work with JavaScript off, is an idea none of the other three teaches.

And `front-performance`, after this point in the track, takes server rendering across all four in
its lesson 2:
Angular SSR beside Next.js, Nuxt and SvelteKit.
