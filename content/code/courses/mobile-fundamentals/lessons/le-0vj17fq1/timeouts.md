---
title: Timeouts, and the screen that stops waiting
version: 1
---

**A request has stages, and a request can stall in any one of them.** Before your server sees a
byte, the phone has to find the server's address and open a connection to it; then it sends the
request, waits for the first byte of the answer, and reads the rest. A timeout is a limit on one of
those waits, and there are three kinds worth telling apart:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l14-timeline\" aria-label=\"A request drawn as five stages along a time line: find the server's address, open the connection, send the request, wait for the first byte, read the body. Above the first two, the connect timeout. Above the last two, the read timeout, the longest silence between two pieces of data, which restarts whenever data arrives. Below all five, the whole-request deadline, which AbortSignal.timeout sets. A marker at the wait for the first byte says that /hang stops there: connected, request sent, and no byte ever comes.\"><defs><marker id=\"l14-timeline-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-timeline-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l14-timeline-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"92\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"107.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">find the</text><text x=\"80.0\" y=\"120.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">address</text><rect x=\"160\" y=\"92\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"220.0\" y=\"107.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">open the</text><text x=\"220.0\" y=\"120.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">connection</text><rect x=\"300\" y=\"92\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"107.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">send the</text><text x=\"360.0\" y=\"120.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">request</text><rect x=\"440\" y=\"92\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"107.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">wait for the</text><text x=\"500.0\" y=\"120.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">first byte</text><rect x=\"580\" y=\"92\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"107.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">read the</text><text x=\"640.0\" y=\"120.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">body</text><path d=\"M140 114 L160 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-paper-dim)\"></path><path d=\"M280 114 L300 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-paper-dim)\"></path><path d=\"M420 114 L440 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-paper-dim)\"></path><path d=\"M560 114 L580 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-paper-dim)\"></path><path d=\"M20 66 L280 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-phosphor)\" marker-start=\"url(#l14-timeline-ah-phosphor)\"></path><text x=\"150\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">connect timeout</text><path d=\"M440 66 L700 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-phosphor)\" marker-start=\"url(#l14-timeline-ah-phosphor)\"></path><text x=\"570\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">read timeout: the longest silence, restarted by every byte</text><path d=\"M20 162 L700 162\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-timeline-ah-amber)\" marker-start=\"url(#l14-timeline-ah-amber)\"></path><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">the whole-request deadline</text><text x=\"500\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">/hang stops here: no byte ever comes</text><path d=\"M500 196 L500 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-timeline-ah-paper-dim)\"></path><text x=\"690\" y=\"222\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">time →</text></svg>", "caption": "Three limits on one request. Only the deadline at the bottom covers every stage, which is why it is the one a screen needs."}
```

- A **connect timeout** limits how long the phone tries to open the connection. It catches a server
  that is down or unreachable, and a lift where the connection never forms.
- A **read timeout** limits the longest *silence* once connected: the clock restarts every time some
  data arrives. Apple's documentation for `URLSession`, as read on 30 October 2026, calls this the
  request timeout and gives it a default of 60 seconds.
- A **whole-request deadline** limits everything, from the first step to the last byte. The same
  page gives `URLSession`'s version of it, the resource timeout, a default of seven days.

**The read timeout alone does not save you from a slow trickle**: a server that sends one byte every
fifty seconds never trips a 60-second read timeout and never finishes. A deadline on the whole
request is the limit a screen actually needs, because a person waiting for the week does not care
which stage is slow.

## A client with a deadline

`fetch`, in Node.js as in a browser and in React Native, takes an `AbortSignal`: an object that can
be told to stop, and that stops the request when it is. Save this as `fetchweek.ts`:

```schooling-example
{"language": "typescript", "file": "fetchweek.ts", "parts": [{"code": "// fetchweek.ts: ask for the week with a deadline, a way to cancel, and a bounded retry\nimport { parseArgs } from \"node:util\";\n\nexport type Options = {\n  timeoutMs?: number; // the whole request: connecting, waiting, reading the body\n  signal?: AbortSignal; // aborted by the screen that asked, when it goes away\n  retries?: number; // extra attempts after the first, for a 5xx answer only\n  backoffMs?: number; // the first wait between attempts; each one after doubles\n};\n", "note": "The four things a caller can decide. Every one is optional, so `fetchWeek(url)` on its own is a plain request with no limit at all, which is the case this section starts from."}, {"code": "export async function fetchWeek(url: string, o: Options = {}) {\n  let wait = o.backoffMs ?? 500;\n  for (let attempt = 1; ; attempt++) {\n    const stops: AbortSignal[] = [];\n    if (o.signal) stops.push(o.signal);\n    if (o.timeoutMs) stops.push(AbortSignal.timeout(o.timeoutMs));\n    const res = await fetch(url, { signal: AbortSignal.any(stops) });\n", "note": "Each attempt gets a fresh deadline, made by `AbortSignal.timeout`. `AbortSignal.any` joins it to the screen's signal, so the request stops at whichever comes first: the deadline or the screen going away."}, {"code": "    if (res.ok) return res.json();\n    if (res.status < 500 || attempt > (o.retries ?? 0)) {\n      throw new Error(`HTTP ${res.status} after ${attempt} attempt(s)`);\n    }\n    console.log(`attempt ${attempt}: HTTP ${res.status}, waiting ${wait} ms`);\n    await new Promise((r) => setTimeout(r, wait));\n    wait *= 2;\n  }\n}\n", "note": "Only a status of 500 or more is tried again, and only as many times as `retries` allows; anything else is thrown at once. The wait doubles after every failure. The next section runs this part."}, {"code": "// Run as `node fetchweek.ts PATH [--timeout MS] [--leave MS] [--retries N]`.\nif (process.argv[1]?.endsWith(\"fetchweek.ts\")) {\n  const { values, positionals } = parseArgs({\n    allowPositionals: true,\n    options: { timeout: { type: \"string\" }, leave: { type: \"string\" }, retries: { type: \"string\" } },\n  });\n  const url = new URL(positionals[0] ?? \"/week\", \"http://127.0.0.1:8014\").href;\n  const screen = new AbortController();\n  if (values.leave) setTimeout(() => screen.abort(), Number(values.leave)).unref();\n", "note": "This part runs only when the file is the one `node` was given, so `screen.ts` can import `fetchWeek` without starting it. `screen` stands for the screen that asked; `--leave` aborts it after that many milliseconds."}, {"code": "  console.log(`asking ${url}`);\n  const start = performance.now();\n  try {\n    console.log(await fetchWeek(url, {\n      timeoutMs: values.timeout ? Number(values.timeout) : undefined,\n      signal: screen.signal,\n      retries: Number(values.retries ?? 0),\n    }));\n  } catch (e: any) {\n    console.log(`${e.name}: ${e.message}${e.cause?.code ? ` (${e.cause.code})` : \"\"}`);\n  }\n  console.log(`after ${((performance.now() - start) / 1000).toFixed(1)} s`);\n}", "note": "Whatever happens is printed with its name, which is how the transcripts below tell a timeout from a cancellation, and with how long it took, to a tenth of a second."}]}
```

## The request that never returns

First, `/hang` with no deadline at all. In the lift there is nothing to stop the app waiting, so
the transcript lends it one from outside: the `timeout` command kills a program that is still
running after five seconds, and exits with 124 to say it had to:

```
ana@dev:~/planner$ timeout 5 node fetchweek.ts /hang; echo "exit $?"
asking http://127.0.0.1:8014/hang
exit 124
```

**Nothing was printed after `asking`**: no error, no answer. Left alone, Node.js does give up in
the end, and this is when:

```
ana@dev:~/planner$ node fetchweek.ts /hang
asking http://127.0.0.1:8014/hang
TypeError: fetch failed (UND_ERR_HEADERS_TIMEOUT)
after 301.0 s
```

Five minutes, and the number is nobody's decision for your screen: it is a default inside the
library behind Node.js's `fetch`. Each platform has its own, and they disagree, which is the reason
to set yours rather than inherit theirs. Now the same request with a deadline of two seconds, and
`/slow` with a deadline of five, which it meets:

```
ana@dev:~/planner$ node fetchweek.ts /hang --timeout 2000
asking http://127.0.0.1:8014/hang
TimeoutError: The operation was aborted due to timeout
after 2.0 s
ana@dev:~/planner$ node fetchweek.ts /slow --timeout 5000
asking http://127.0.0.1:8014/slow
{ monday: '2026-10-19', planned: 180, done: 120 }
after 3.1 s
```

`AbortSignal.timeout(2000)` stopped the request at 2.0 seconds with a `TimeoutError`, and the three
seconds `/slow` took were inside a five-second limit. **How long is right is a judgement about the
screen, not the network**: two to ten seconds for something a person is looking at, longer for an
upload they started on purpose and can watch progress on. The times here were measured once, on the
computer this course was recorded on, and vary by a tenth of a second from run to run.

## When the screen goes away

**A request belongs to the screen that asked for it.** If the student opens the week and leaves it
before the answer arrives, the answer has nowhere to go, and finishing the request spends battery
and data on nothing. Worse, an answer that arrives late can be drawn over the screen the student has
moved to. So the screen holds an `AbortController`, and aborts it when it goes away. `--leave 1000`
plays a student who leaves after one second:

```
ana@dev:~/planner$ node fetchweek.ts /slow --leave 1000
asking http://127.0.0.1:8014/slow
AbortError: This operation was aborted
after 1.0 s
```

**The two stops have different names on purpose.** A `TimeoutError` means the network was too slow,
and the screen should say so. An `AbortError` means the app itself stopped the request, nobody is
waiting for the result, and there is nothing to show and nothing to report. `AbortSignal.any` in
`fetchWeek` merges the two, so either one stops the request.

The three platforms tie a request to its screen in their own way, which the courses after the fork
teach: in Kotlin, a coroutine started in the screen's scope is cancelled with it; in Swift, a
`.task` attached to a view is cancelled when the view disappears; in React, the clean-up function
of an effect calls `abort()`. That is the `android-apps` course in its lesson 11, `ios-apps` in its
lesson 12, and `react-native` in its lesson 10, whichever route you take.
