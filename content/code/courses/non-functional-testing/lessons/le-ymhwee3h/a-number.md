---
title: From an adjective to a number
version: 1
---

"It has to be fast" is a wish, and no test can fail it. Fast for whom, doing what, with how many
other people doing it at the same time? A load test run against that sentence produces a page of
numbers, and the meeting that reads them decides afterwards whether they were good, which means
the test decided nothing. **A non-functional requirement is testable when somebody could read the
result and say *fail* without asking anybody what was meant.**

## The five parts

A performance requirement that can fail has five parts, and leaving any one out is the usual way
it stops being testable:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l01-anatomy\" aria-label=\"One requirement cut into its five parts. The operation: GET /shows/{id}. The statistic: the 95th percentile of the response time, and the error rate. The threshold: under 200 ms, and under 1%. The load: 50 requests a second. The conditions: sustained for 10 minutes, timed at the client, on the staging machine. Leave out any one part and nobody can say whether a result fails.\"><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">one sentence a test can fail</text><rect x=\"20.0\" y=\"60.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">operation</text><rect x=\"20.0\" y=\"108.0\" width=\"120.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"80.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET /shows/{id}</text><rect x=\"152.0\" y=\"60.0\" width=\"126.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"215.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">statistic</text><rect x=\"152.0\" y=\"108.0\" width=\"126.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"215.0\" y=\"139.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">95th percentile</text><text x=\"215.0\" y=\"152.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">error rate</text><rect x=\"290.0\" y=\"60.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">threshold</text><rect x=\"290.0\" y=\"108.0\" width=\"120.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"350.0\" y=\"139.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt; 200 ms</text><text x=\"350.0\" y=\"152.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt; 1%</text><rect x=\"422.0\" y=\"60.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"482.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">load</text><rect x=\"422.0\" y=\"108.0\" width=\"120.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"482.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">50 requests/s</text><rect x=\"554.0\" y=\"60.0\" width=\"146.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"627.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">conditions</text><rect x=\"554.0\" y=\"108.0\" width=\"146.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"627.0\" y=\"132.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">10 minutes</text><text x=\"627.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">timed at the client</text><text x=\"627.0\" y=\"159.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">staging machine</text><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">leave one out and the result needs a meeting to read</text></svg>", "caption": "The five parts of a performance requirement. Each one is a place where \"fast\" used to hide."}
```

1. **The operation.** Not "the site" but one thing a user does: `GET /shows/{id}`, the booking
   `POST`, the search. Different operations have different costs, and an average across all of
   them hides the expensive one behind the cheap ones.
2. **The statistic.** Which number is compared: the 95th percentile of the response time, the
   error rate, the throughput. "The 95th percentile" means the time that 95 of every 100
   requests stay under. Lesson 8 shows why the percentile, and not the average, is the statistic
   to write down.
3. **The threshold.** 200 ms, 1%, 50 requests a second. A number with a unit.
4. **The load.** How many requests a second, or how many people at once, arriving how. A system
   that answers in 30 ms with one user may answer in three seconds with two hundred, and both are
   true.
5. **The conditions.** For how long, on which environment, measured where. Ten minutes on a
   machine the size of production, timed at the client, is a different claim from thirty seconds
   on a laptop timed in the server's log.

Put together, the wish becomes a sentence a test can hold:

> `GET /shows/{id}`: 95th percentile under 200 ms and errors under 1%, at 50 requests a second
> sustained for 10 minutes, timed at the client, on the staging machine.

## The same move for the other three

Accessibility and security have their own adjectives, and they turn into numbers, or into named
lists, the same way.

| the wish | something a test can fail |
|---|---|
| "it has to be fast" | the sentence above |
| "the page should load quickly" | Largest Contentful Paint at most 2.5 s at the 75th percentile of real visits (lesson 10) |
| "it has to be accessible" | conforms to WCAG 2.2 at level AA on the booking flow (lesson 12) |
| "it must be usable without a mouse" | every control on the booking page is reached and operated with the keyboard alone, in reading order (lesson 14) |
| "it has to be secure" | no finding rated high or critical left open at release, and one customer's token cannot read another customer's booking (lessons 17 and 21) |
| "we must know when it breaks" | an alert reaches the person on call within 5 minutes of the error rate passing 2% (lesson 24) |

Not every row is a number. "Conforms to WCAG 2.2 AA" is a named list of criteria, published and
versioned by somebody else, and that serves the same purpose: two people reading the same result
reach the same verdict.

## Where the numbers come from

**A threshold is a decision, and the test is only as good as the reason behind it.** Three sources
are worth more than a guess:

- **What the system does now.** Production logs give today's percentiles and today's busiest
  minute. A release that keeps the 95th percentile where it is, at the load it already meets, is
  a requirement nobody can call arbitrary.
- **What the business expects.** The box office in this course sells 300 seats a show, and a
  popular show goes on sale at 10:00. That is a spike with a known size and a known time, and
  lesson 3 turns it into a number of requests a second.
- **What published research says about people.** Google's Core Web Vitals give thresholds that
  came from measuring real visits. They are a reasonable default where nothing better exists,
  and a poor substitute for what your own users do.

A requirement nobody can trace to one of those is still better than no requirement. Write it
down, run the test against it, and expect to change it once the first results arrive. What you
cannot do is run the test first and write the requirement afterwards, around the number you got.
