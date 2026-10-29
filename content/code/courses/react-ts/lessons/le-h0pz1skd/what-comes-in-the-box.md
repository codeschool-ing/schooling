---
title: What comes in the box
version: 1
---

**Lesson 1 said the difference between React and Angular is not size but who decides.** Size is still a
number worth looking at, and the four builds can measure it on equal terms. Vite and Angular each print
an estimate of their own, so one command compresses every JavaScript file each build wrote, the same
way for all four:

```
ana@dev:~$ for d in sessions-react/dist sessions-vue/dist sessions-svelte/dist sessions-angular/dist/sessions-angular/browser; do printf "%-45s %6s bytes\n" "$d" "$(cat $d/assets/*.js $d/*.js 2>/dev/null | gzip -9 | wc -c)"; done
sessions-react/dist                            67948 bytes
sessions-vue/dist                              24687 bytes
sessions-svelte/dist                           13095 bytes
sessions-angular/dist/sessions-angular/browser  60798 bytes
```

```schooling-figure
{"svg": "<svg data-fig=\"sizes\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The JavaScript each production build wrote, compressed with gzip -9: Svelte 13,095 bytes, Vue 24,687, Angular 60,798 and React 67,948, for the same component.\"><text x=\"96\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Svelte</text><rect x=\"108\" y=\"30\" width=\"91\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"209\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">13,095 bytes</text><text x=\"96\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Vue</text><rect x=\"108\" y=\"76\" width=\"171\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"289\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">24,687 bytes</text><text x=\"96\" y=\"138\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Angular</text><rect x=\"108\" y=\"122\" width=\"421\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"539\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">60,798 bytes</text><text x=\"96\" y=\"184\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">React</text><rect x=\"108\" y=\"168\" width=\"470\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"588\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">67,948 bytes</text></svg>", "caption": "For one small component, the size is the framework's own, not your code's."}
```

For one component, almost all of that is the framework itself, which every app pays once whatever it
grows into. **Svelte is smallest because most of it ran at build time**, and the code it left behind is
what this one component uses. Vue carries a run time that compares templates. React carries `react-dom`,
which compares and draws whatever the components return. Angular's figure includes its router, which the
generated `app.config.ts` still sets up although no page uses it. On a real application these gaps
shrink, because your own code grows and the framework does not.

**What comes with each one is the bigger difference**, and it is the one lesson 1 began with:

- **Angular** is one box from one team. Its router, its forms, its HTTP client, its way of handing
  services to the components that need them, its build and its test command all ship as `@angular/…`
  packages released together, and the documentation teaches one way to do each thing.
- **Vue** is a smaller core with official companions: Vue Router for addresses, Pinia for shared state,
  and Nuxt as the full framework around them, all maintained by the people behind Vue.
- **Svelte** has SvelteKit, from its own team: routing, loading data and rendering on the server.
- **React** has React, and this course added the rest piece by piece: React Router in lesson 17, React
  Query in lesson 11, React Hook Form and Zod in lesson 10, Zustand in lesson 9, and Next.js in lesson
  18 as the framework that closes most of those questions at once. Each came from a different team.

**So which one?** The question this course was written to let you answer is not which is best but what
each one asks of you. React asks you to choose your pieces and to understand a model where everything
re-runs. In return the choices are yours, the pieces are swappable, and it is the option with the most
code written for it and the most libraries. Angular asks you to learn more at the start
and to accept its way; in return two Angular projects look alike, which large teams value. Vue and
Svelte sit between, with signals and templates, a smaller core than Angular's and official answers for
the common questions.

Having written the same component in all four, you have the part that carries over: state, values
derived from it, a list with keys, an event that changes the state, a build and a check of the types.
Each of the four spells it differently, and every one of them has it.
