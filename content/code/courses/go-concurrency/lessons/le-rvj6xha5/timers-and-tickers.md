---
title: Timers and tickers
version: 1
---

`time.Sleep` stops the goroutine that calls it, and nothing else can happen in that goroutine
until it wakes. **A timer is a sleep turned into a channel**: it delivers one value after a
duration, so a goroutine can wait for it inside a `select` beside other things, as lesson 5 did
with `time.After`. A ticker delivers a value again and again. Both are values you hold, so both can
be stopped, and that is the difference from `time.After`.

Saved as `timer.go`:

```schooling-example
{"language": "go", "file": "timer.go", "parts": [{"code": "// Command timer starts timers, stops one, and lets a ticker run.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"time\"\n)\n\nfunc main() {\n\tstart := time.Now()\n\tsince := func() time.Duration { return time.Since(start).Round(10 * time.Millisecond) }\n\n", "note": "`since` reports how far into the run each line was printed, rounded to ten milliseconds so that the scheduler's small delays do not clutter the output."}, {"code": "\tt := time.NewTimer(300 * time.Millisecond)\n\t<-t.C\n\tfmt.Println(\"timer fired at\", since())\n\n", "note": "**A timer's channel is `t.C`.** Receiving from it waits until the duration has passed and then gets the time it fired. Here the receive is alone, so this is a sleep written the long way."}, {"code": "\tlate := time.NewTimer(time.Hour)\n\tfmt.Println(\"stopped before firing:\", late.Stop())\n\n", "note": "`Stop` cancels a timer that has not fired and says whether it did anything. `true` means the hour will never be delivered."}, {"code": "\ttime.AfterFunc(100*time.Millisecond, func() { fmt.Println(\"AfterFunc ran at\", since()) })\n\n", "note": "**`AfterFunc` has no channel: it runs the function in a goroutine of its own** when the time comes. `main` does not wait for it; it is still running the ticker below when the function fires."}, {"code": "\ttick := time.NewTicker(200 * time.Millisecond)\n\tfor range 3 {\n\t\t<-tick.C\n\t\tfmt.Println(\"tick at\", since())\n\t}\n\ttick.Stop()\n}\n", "note": "A ticker fires every 200 milliseconds until stopped. `Stop` after the loop ends the ticks; a ticker nobody stops keeps firing for as long as the program runs."}]}
```

```
ana@vm:~/clock$ go run timer.go
timer fired at 300ms
stopped before firing: true
AfterFunc ran at 400ms
tick at 500ms
tick at 700ms
tick at 900ms
```

The timer fired at 300 milliseconds. `AfterFunc` was set at that moment for a hundred more and ran
at 400, in its own goroutine, between the ticker's start and its first tick. The ticks came at 500,
700 and 900, two hundred apart, counted from when the ticker was made.

## What changed in Go 1.23

Old code is full of a ritual: `defer t.Stop()` right after every `NewTimer`, and a drain of `t.C`
before every `Reset`. **Both were needed before Go 1.23 and neither is now**, and `go doc
time.NewTimer` says so in as many words. A timer nobody refers to any more is collected by the
garbage collector even if it never fired. And a timer's channel no longer holds a stale value, so
after `Stop` or `Reset` returns, a receive cannot get a time from the old setting. `Stop` is still
how you cancel a timer you do not want; it is no longer how you avoid a leak.

That holds because the module's `go.mod` says `go 1.23` or later, which every module made with
Go 1.27.1 does. A module declaring an older version keeps the old behaviour, so the ritual you
meet in an old project may still be doing its job there.

## A ticker that is read late drops ticks

A ticker does not queue its ticks for a slow reader. **One tick waits to be read, and every tick
that fires while it waits is dropped.** Here the reader sleeps 250 milliseconds
after every tick of a 100-millisecond ticker, saved as `slow.go`:

```go
// Command slow reads a ticker more slowly than it ticks.
package main

import (
	"fmt"
	"time"
)

func main() {
	start := time.Now()
	tick := time.NewTicker(100 * time.Millisecond)
	defer tick.Stop()
	for range 4 {
		at := <-tick.C
		fmt.Println("tick stamped", at.Sub(start).Round(10*time.Millisecond),
			"read at", time.Since(start).Round(10*time.Millisecond))
		time.Sleep(250 * time.Millisecond)
	}
}
```

```
ana@vm:~/clock$ go run slow.go
tick stamped 100ms read at 120ms
tick stamped 200ms read at 370ms
tick stamped 400ms read at 620ms
tick stamped 700ms read at 870ms
```

Each value carries the time it was stamped, and the stamps are 100, 200, 400 and 700. Ticks at
300, 500 and 600 were never delivered. The tick stamped 400 was read at 620, so it had waited 220
milliseconds while two newer ticks came and went. **The reader never receives a burst of old ticks
to catch up with**: however late it is, it finds one tick waiting and no more.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A ticker fires every 100 milliseconds, at 100, 200 and so on up to 800. The reader takes the ticks stamped 100, 200, 400 and 700, reading them at 120, 370, 620 and 870 milliseconds. The ticks at 300, 500, 600 and 800 are dropped, because each fired while an older tick was still waiting to be read.\"><defs><marker id=\"l20ticks-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the ticker fires</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the reader receives</text><path d=\"M150.0 60 H690.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M150.0 150 H690.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"201.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M210.0 71 L222.0 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20ticks-phosphor)\"></path><rect x=\"215.0\" y=\"143\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"261.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M270.0 71 L372.0 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20ticks-phosphor)\"></path><rect x=\"365.0\" y=\"143\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"321.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"381.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M390.0 71 L522.0 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20ticks-phosphor)\"></path><rect x=\"515.0\" y=\"143\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"441.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"501.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"561.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M570.0 71 L672.0 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20ticks-phosphor)\"></path><rect x=\"665.0\" y=\"143\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"621.0\" y=\"51\" width=\"18\" height=\"18\" rx=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><path d=\"M150.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"150.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M210.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"210.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M270.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"270.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><path d=\"M330.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"330.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300</text><path d=\"M390.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"390.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400</text><path d=\"M450.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"450.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">500</text><path d=\"M510.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"510.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600</text><path d=\"M570.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"570.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">700</text><path d=\"M630.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"630.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">800</text><path d=\"M690.0 190 V196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"690.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">900</text><path d=\"M150.0 190 H690.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"420.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">milliseconds since start</text><rect x=\"470\" y=\"16\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">delivered</text><rect x=\"580\" y=\"16\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"600\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dropped</text></svg>", "caption": "slow.go: one tick waits to be read, and the ticks that fire meanwhile are dropped."}
```

That is the right behaviour for the job a ticker does, which is "do this every so often". A
program that needs every event counted, a rate of requests for instance, has to count them some
other way than by ticks received.
