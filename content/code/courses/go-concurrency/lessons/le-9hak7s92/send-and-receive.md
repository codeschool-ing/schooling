---
title: Sending and receiving
version: 1
---

Lesson 2 left a goroutine with no way to hand back what it computed: the `go` statement throws
return values away. **A channel is the way back: a typed pipe that one goroutine sends values into
and another receives them from**, and handing a value across it is also the synchronisation lesson
1 section 04 promised. People new to Go picture a channel as a queue with an API. Its defining
property is something else: it makes the goroutines on either end wait for each other.

Four pieces of syntax cover it:

| | what it does |
|---|---|
| `ch := make(chan int)` | makes a channel that carries `int` values |
| `ch <- v` | sends `v`, waiting until a receiver takes it |
| `v := <-ch` | receives a value, waiting until one arrives |
| `var ch chan int` | declares one without making it: its zero value is `nil`, and lesson 5 shows what that is good for |

The arrow always points the way the value travels. A channel is a reference, like a map: passing
`ch` to a function passes the same channel, not a copy of it.

## Two results, one channel

This program starts two goroutines that each add up a list after a pretend delay, and both send
their total on the same channel. It is shown in pieces, saved as `hand.go`:

```schooling-example
{"language": "go", "file": "hand.go", "parts": [{"code": "// Command hand sends one result from a goroutine back to main.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"time\"\n)\n\n", "note": "Two imports: `fmt` to print, `time` to make the work slow enough to watch."}, {"code": "func sum(numbers []int, out chan int) {\n\ttime.Sleep(200 * time.Millisecond) // pretend this is slow work\n\ttotal := 0\n\tfor _, n := range numbers {\n\t\ttotal += n\n\t}\n\tout <- total\n}\n\n", "note": "**The result leaves by the channel, not by `return`.** `sum` takes the channel as a parameter, and its last act is to send on it. Until somebody receives, that send waits."}, {"code": "func main() {\n\tstart := time.Now()\n\tresults := make(chan int)\n\tgo sum([]int{1, 2, 3, 4}, results)\n\tgo sum([]int{10, 20, 30}, results)\n\n", "note": "One channel, made by `make`, shared by both goroutines. Each gets its own slice to add up."}, {"code": "\ta := <-results\n\tfmt.Println(\"first result:\", a, \"after\", time.Since(start).Round(10*time.Millisecond))\n\tb := <-results\n\tfmt.Println(\"second result:\", b, \"after\", time.Since(start).Round(10*time.Millisecond))\n}\n", "note": "**Each receive waits until a value arrives.** Two receives, two values, and `main` cannot get past the second until both goroutines have sent."}]}
```

```
ana@vm:~/channels$ go run hand.go
first result: 60 after 200ms
second result: 10 after 200ms
```

Both totals arrived 200 milliseconds after the start, not 200 and then 400: the two goroutines
slept at the same time, and each send waited only for `main` to be ready. **The first result was
60, from the second goroutine started.** Which of the two finishes first is the scheduler's
business, as in lesson 1, so `a` is whichever total came first, and a program that needs to know
which list a total belongs to has to send that along with it. Lesson 13 does exactly that.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"hand.go on a time line. main starts two goroutines and blocks on its first receive. Both goroutines sleep for 200 milliseconds at the same time, then each sends its total. main&#x27;s first receive takes 60, its second takes 10, both at about 200 milliseconds.\"><defs><marker id=\"l03hand-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l03hand-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"16\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main</text><text x=\"16\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sum 10, 20, 30</text><text x=\"16\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sum 1, 2, 3, 4</text><rect x=\"150\" y=\"38\" width=\"530\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"385.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">waiting on &lt;-results</text><rect x=\"150\" y=\"98\" width=\"470\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sleeping</text><rect x=\"150\" y=\"148\" width=\"470\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sleeping</text><path d=\"M620 110 H635 V65\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03hand-amber)\"></path><text x=\"648\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">60</text><path d=\"M620 160 H665 V65\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03hand-amber)\"></path><text x=\"678\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">10</text><path d=\"M150 214 H640\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03hand-paper-dim)\"></path><path d=\"M150.0 209 V219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"150.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 ms</text><path d=\"M385.0 209 V219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"385.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100 ms</text><path d=\"M620.0 209 V219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"620.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200 ms</text></svg>", "caption": "The two goroutines slept side by side, so both sends met main's receives at about 200 ms. The first value to arrive was 60."}
```

Nothing else was needed to make `main` wait. No `WaitGroup`, no sleep: **a receive cannot finish
until a send has happened**, so the value arriving is itself the proof that the goroutine got that
far. And everything `sum` did before its send is visible to `main` after its receive, which is the
promise from lesson 1 section 04 that makes sharing a value this way safe.

Here the two sides met as equals: whichever arrived at the channel first waited for the other.
Lesson 4 is about that meeting, and about giving a channel room to hold values so that a sender
need not wait for one.
