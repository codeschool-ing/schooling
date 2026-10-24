---
title: "Field data: the number from the visitor"
version: 1
---

**Every number in this lesson so far was measured in one browser, on one computer, with conditions
chosen by you.** That is called **lab data**, and it is what finds causes. The thresholds of the
section "Good, needs improvement, poor" are meant for **field data**: what real visitors' browsers
measured on their own devices and networks, collected from many visits and read at the 75th
percentile.

## Two places field data comes from

**Google's Chrome User Experience Report**, CrUX, is field data that Chrome collects from users who
have agreed to share usage statistics, for sites with enough traffic, aggregated by origin and by
page. Google's tools show it beside their own lab measurements, and lesson 6 is about those tools. A
small site, or a new page, has none.

**Your own collection**, usually called **RUM**, real user monitoring: the page measures itself, as
`vitals.ts` already does, and sends the values to a server of yours. It works for any site, every
page, and every browser that supports the metrics, and it can carry what CrUX cannot, such as which
course page it was. The rest of this section adds it to the planner.

## Sending the values home

The values a person's browser reports while they read a page are not final until they leave it: CLS
can grow, and the slowest interaction may be the last one. The library therefore reports each final
value **when the page is hidden or left**, and at that moment an ordinary `fetch` may be cut off with
the page. **`navigator.sendBeacon` is made for exactly that moment**: the browser keeps the request
going after the page is gone.

In `src/vitals.ts`, change the first line so it also imports the type of a value:

```typescript
import { onCLS, onINP, onLCP, type Metric } from "web-vitals/attribution";
```

and add these lines at the end. They register the three metrics a second time, without
`reportAllChanges`, so each sends once per page view, with its final value:

```typescript

// Once per page view, when the visitor leaves or hides the page, the final values go to the
// server. sendBeacon is made for this: it outlives the page that sent it.
const send = (m: Metric) => navigator.sendBeacon("/vitals",
  JSON.stringify({ name: m.name, value: Math.round(m.value * 1000) / 1000, rating: m.rating, page: location.pathname }));
onLCP(send);
onINP(send);
onCLS(send);
```

`server.ts` needs an address that receives them. Add these lines right after the line that reads
`pathname`, before the one that checks for a file:

```typescript
  if (req.method === "POST" && pathname === "/vitals") {
    // A visitor's browser reporting its Core Web Vitals: one line in the log for each.
    let body = "";
    for await (const chunk of req) body += chunk;
    console.log(`vitals ${body}`);
    res.writeHead(204).end();
    return;
  }
```

Build and restart. `vitals.ts` already leaves the page at the end of every run, as a visitor does, so
one run with a click is enough:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/courses/git --click "[data-done]"
[vitals] LCP 68 ms good #notice
[vitals] CLS 0.000 good 
```

And the second terminal, where `server.ts` runs:

```
ana@dev:~/planner$ npm run build >/dev/null && TZ=UTC node server.ts
planner on http://localhost:3000
vitals {"name":"LCP","value":68,"rating":"good","page":"/courses/git"}
vitals {"name":"CLS","value":0,"rating":"good","page":"/courses/git"}
```

**Two lines arrived, LCP and CLS, and no INP.** The click was quick, and the library only listens for
interactions of 40 milliseconds and more, so a visit whose every interaction was quick has no INP to
send. That is a property of the data to remember when it is counted: the share of visits with an INP
is not the share of visits with an interaction.

## What a log line is not

A log line is one visit. What answers "does this page pass" is many of them, grouped by page and by
kind of device, and read at the 75th percentile, which is a job for whatever stores the
application's other logs and metrics. Two cautions travel with the collection itself:

- **it is data about visitors**, sent from their browsers: the address they read, the device they
  used. A site with a privacy policy has to account for it, as it would for any other measurement;
- **the endpoint takes anything anybody posts**. Nothing here trusts it beyond writing a line; a real
  one checks the shape and the size of what it receives before storing it.
