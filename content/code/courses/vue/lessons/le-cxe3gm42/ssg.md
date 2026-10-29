---
title: Static generation, rendered once at build time
version: 1
---

**`nuxt generate` renders every page once, when you build, and writes each one to a file.** What it
produces needs no Node and no Nitro to serve it, only a host that sends files, the kind lesson 17's
`dist` was meant for, and the HTML of every page is already complete. That is *static site
generation*, SSG, and it is the cheapest and fastest way to serve a page that is the same for
everybody:

```
ana@dev:~/vue/planner-nuxt$ npx nuxt generate 2>&1 | tail -12
[nitro]   ├─ /courses/spanish/_payload.json?_b=1c26fe19-34f6-439f-a0d1-43933c07f768 (4ms) (skipped)
[nitro]   ├─ /courses/guitar/_payload.json?_b=1c26fe19-34f6-439f-a0d1-43933c07f768 (3ms) (skipped)
[nitro]   ├─ /courses/statistics (27ms)
[nitro]   ├─ /courses/statistics/_payload.json?_b=1c26fe19-34f6-439f-a0d1-43933c07f768 (1ms) (skipped)
[nitro]   ├─ /courses/spanish/_payload.json (5ms)
[nitro]   ├─ /courses/guitar/_payload.json (3ms)
[nitro]   ├─ /courses/statistics/_payload.json (2ms)
[nitro] ℹ Prerendered 10 routes in 1.832 seconds
[nitro] ✔ Generated public .output/public
[nitro] ✔ You can preview this build using npx serve .output/public
config 266ms · modules 50ms · app 456ms · types 410ms · client 1.05s · server 448ms · nitro 1.99s
◆ ✨ You can now deploy .output/public to any static hosting! (4.67s)
```

**Ten routes, found by following links.** Nuxt rendered `/`, read the `<NuxtLink>`s on it, rendered
the three course pages they lead to, and wrote a `_payload.json` beside each page: the data
`useFetch` received while rendering it, which the browser reads instead of calling the API. A page
that no link reaches is not generated unless the configuration lists it.

```
ana@dev:~/vue/planner-nuxt$ ls .output/public .output/public/courses
.output/public:
200.html
404.html
_nuxt
_payload.json
courses
favicon.ico
index.html
robots.txt

.output/public/courses:
guitar
spanish
statistics
```

`index.html` and one folder per course, each holding its own `index.html`. `200.html` is the shell a
static host should send for an address with no file, so the router can take it from there, the job
`vite preview` did for lesson 17's build, and `404.html` is the error page.

## What generating the planner gets wrong

Two things, and both are the planner's nature rather than a mistake in the command.

**The data is the data of the build.** Every session in those files is as `courses.json` had it when
the command ran. A tick sends a `PATCH` to `/api/sessions/…`, and a static host has no server to
answer it: the API exists only where Nitro runs. A generated planner could show a week; it could not
keep one.

**And so is the clock.** The server-side `today` of the last section ran once, at build time:

```
ana@dev:~/vue/planner-nuxt$ grep -o '<li class="today"[^>]*><label[^>]*><input[^>]*>[^<]*' .output/public/index.html
<li class="today" data-v-a1b0f0de><label data-v-a1b0f0de><input type="checkbox" data-v-a1b0f0de> 21 October 2026, Statistics, 60 minutes 
```

The grep finds the highlight on the 21st, the day of the build, baked into the file. Opened on any
later day, the page is a hydration mismatch with no server involved at all, and in production it is
left wrong, as the last section showed.

Generation fits pages whose content changes when you deploy and not in between: the planner's
`about` page, a course's description, documentation, a blog. The next section mixes the two in one
project, page by page.
