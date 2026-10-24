---
title: A heavy page, and what the report names
version: 1
---

**Three courses make a page nobody can slow down. Five thousand can.** Lesson 3's `gen.ts` writes a
plan of any size into `dist/`, and `server.ts` reads it on every request, so the home page of a large
catalogue is one command away. Measure it:

```
ana@dev:~/planner$ node gen.ts 5000 && npm run lighthouse -- http://localhost:3000/ >/dev/null && node tools/report.ts report.report.json
5000 courses
performance 75, throttling simulate
  FCP  4.3 s    weight 10
  LCP  4.3 s    weight 25
  TBT  10 ms    weight 30
  CLS  0        weight 25
  SI   4.3 s    weight 10
  insight: Use efficient cache lifetimes, Est savings of 18 KiB
  insight: Document request latency, Est savings of 414 KiB
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 300 ms
  request /                            done at    39 ms, 633040 B
  request /assets/index-C9VFYfGa.js    done at    63 ms, 17819 B
  request /assets/index-CGM1waBA.css   done at    63 ms, 538 B
  request /favicon.svg                 done at   102 ms, 9695 B
```

**Seventy-five, and the LCP is more than four seconds.** The home page shows a hundred courses and a line
saying how many more, since lesson 5, so the page a person sees is small. What is not small is
the response: the first request is more than six hundred kilobytes.

## Reading the insights

The first insight is the one that matters here. **Document request latency** is about the first
request, the HTML, which everything else waits for, and its estimated saving is in kilobytes: in the
HTML report it is a checklist of three things, and the one that fails is *No compression applied*.

The size has two causes, and both are lessons you have read:

- **the plan is in the page.** Lesson 4's hydrating planner embeds the whole plan as JSON so the
  script does not fetch it again, and with five thousand courses the plan is most of the page;
- **nothing is compressed.** `server.ts` sends every byte as it is, and HTML and JSON are text,
  which compresses very well.

`curl` shows how well. The first number is the page as `server.ts` sends it, the second is the same
bytes through `gzip`, the compression every browser understands:

```
ana@dev:~/planner$ curl -s http://localhost:3000/ | wc -c
632855
ana@dev:~/planner$ curl -s http://localhost:3000/ | gzip | wc -c
54053
```

**The same page, a twelfth of the size.** Names like `course-4182` repeat thousands of times, and
repetition is what compression removes.

The other insights are smaller and belong to other lessons: a stylesheet that blocks the first
paint (lesson 7), files sent with no cache lifetime (lesson 9), and the chain of requests. The section
"What the report still says" comes back to them. First, a doubt about the four seconds.
