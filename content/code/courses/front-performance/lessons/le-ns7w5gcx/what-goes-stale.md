---
title: What goes stale, and what a rebuild costs
version: 1
---

**A prerendered page keeps saying what the data said at the build, however much the data has
changed since.** Nothing warns anybody. The file is served with a 200, it is a perfectly good page,
and it is wrong.

## Watching it happen

With `static.ts` still running, rename the Git course in the planner's data and ask for its page:

```
ana@dev:~/planner$ sed -i 's/"title": "Git"/"title": "Git and GitHub"/' public/courses.json
ana@dev:~/planner$ grep -o '"title": "Git[^"]*"' public/courses.json
"title": "Git and GitHub"
ana@dev:~/planner$ curl -s http://localhost:8080/courses/git | grep -o '<h1>[^<]*</h1>'
<h1>Git</h1>
```

**The data says *Git and GitHub* and the page says *Git*,** because the page is the file the build
wrote and the build has not run since. With JavaScript on, the person sees something worse for a
moment: the prerendered page says *Git*, then the script fetches the new data and redraws the
heading. A rebuild fixes both, and `static.ts` serves the new file at once, because it reads from
disk on every request:

```
ana@dev:~/planner$ npm run build:static >/dev/null && curl -s http://localhost:8080/courses/git | grep -o '<h1>[^<]*</h1>'
<h1>Git and GitHub</h1>
```

Put the title back the same way before going on, with the two words swapped in the `sed`, and build
once more.

## What a rebuild costs as the site grows

Three pages build in no time at all. The question is how the time grows. `gen.ts` replaces the
plan in `dist/` with as many made-up courses as you ask for, one session each, so the same
`prerender.ts` can be timed on a bigger site. Save it beside `prerender.ts`:

```typescript
// gen.ts: replace dist/courses.json with N made-up courses, one session each,
// to time prerender.ts on a bigger site. npm run build:static puts the real one back.
import { writeFile } from "node:fs/promises";

const n = Number(process.argv[2]);
const courses = Array.from({ length: n }, (_, i) => ({ slug: `course-${i + 1}`, title: `Course ${i + 1}` }));
const sessions = courses.map((c, i) => ({ id: i + 1, course: c.slug, date: "2026-10-23", minutes: 30, done: false }));
await writeFile("dist/courses.json", JSON.stringify({ courses, sessions }));
console.log(`${n} courses`);
```

Each run starts from a fresh `npm run build`, because `prerender.ts` needs the empty shell:

```
ana@dev:~/planner$ TIMEFORMAT='%R s'; for n in 100 1000 5000; do npm run build >/dev/null && node gen.ts $n && time node prerender.ts >/dev/null; done
100 courses
0.207 s
1000 courses
1.108 s
5000 courses
4.773 s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A bar chart of how long prerender.ts took for three sizes of site: 100 courses in 0.207 seconds, 1000 in 1.108, and 5000 in 4.773.\"><text x=\"130\" y=\"43\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">100 courses</text><rect x=\"140\" y=\"30\" width=\"20.817096165933375\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"168.81709616593338\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.207 s</text><text x=\"130\" y=\"87\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1000 courses</text><rect x=\"140\" y=\"74\" width=\"111.42677561282214\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"259.42677561282215\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1.108 s</text><text x=\"130\" y=\"131\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">5000 courses</text><rect x=\"140\" y=\"118\" width=\"480.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"628.0\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4.773 s</text><line x1=\"140\" y1=\"170\" x2=\"630\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"140\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time to prerender every page, this computer</text></svg>", "caption": "Every page, every build: the time follows the number of pages, whatever changed."}
```

**Past the first hundred pages, the time grows in step with the number of pages**: from 1000 to
5000 courses it went from 1.108 to 4.773 seconds, about 0.9 milliseconds for each extra page, most
of it writing a file. The first hundred cost almost nothing beyond starting Node. At that rate a
site with a hundred thousand pages spends about a minute on every build rendering pages, and a real
page, with a template engine and a database query each, costs many times what this one does.

**And the build renders every page every time, including the thousands nobody changed.** One
corrected title costs as much as a new site. That is the cost the next section removes: render a
page again only when it is asked for and old enough, or only when its data changed.
