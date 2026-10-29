---
title: The plan in the page
version: 1
---

**Lesson 6 left one finding with no insight attached: the whole plan is in every page.** Code is not
the only thing a page can download that it does not use, and the plan is the planner's largest example.
It is the same question as this lesson's, asked of data: what does this page need, and when?

## What it costs

`curl --compressed` asks for gzip, as a browser does, and `-w` prints how many bytes came over the
network. With the real plan, and with lesson 3's five thousand courses:

```
ana@dev:~/planner$ curl -s --compressed -o /dev/null -w '%{size_download} bytes\n' http://localhost:3000/courses/git
1318 bytes
ana@dev:~/planner$ node gen.ts 5000 && curl -s --compressed -o /dev/null -w '%{size_download} bytes\n' http://localhost:3000/courses/course-1
5000 courses
52966 bytes
```

**Fifty-three kilobytes, compressed, for a page that draws one course and its two sessions**, and every
visitor parses all of it before the page responds. With the real plan the same page is 1.3 kilobytes.

## Three ways to arrange it

| arrangement | what each page sends | what it costs |
|---|---|---|
| **the whole plan in every page**, as now | everything, every time | the bytes and the parsing grow with the catalogue, on every page |
| **the plan as a file of its own**, fetched by the script | nothing; the script asks for `/courses.json` | a round trip before the page responds, the dead window of lesson 4 again; but the file is fetched once and, with lesson 9's headers, cached for every page after |
| **each page's own data**, and more fetched on navigation | the course and its sessions, on a course page | the server must know what every page needs, and the script must fetch it on every navigation, and merge what the visitor changed |

The third is what the four frameworks of lesson 2 do: a page's data is loaded with the page, and a
navigation inside the application asks the server for the next page's data. Next.js sends it as the
payload of its server components, Nuxt and SvelteKit as JSON for the route, and in Angular the route's
own code asks the server's API for it.

## The decision, for the planner

**The planner keeps the whole plan in the page.** Its catalogue is three courses, and its navigation,
`mount`'s click handler, draws any page from the plan it holds with no request at all, which is the best
kind of navigation there is. The arrangement is wrong at five thousand courses, and the measurement above
is how to know when that point arrives: when the data in a page is larger than the page, it is time to
send each page its own.

That is a decision, not a fix, and it is written down here because a decision nobody wrote down looks,
a year later, exactly like a mistake nobody noticed.

Put the real plan back before going on: `npm run build` copies it into `dist/` again.
