---
title: A buffer, and what it changes
version: 1
---

`make(chan T, n)` gives the channel room for `n` values. **A send on a buffered channel completes as
soon as there is room, without waiting for a receiver; it blocks only when the buffer is full.** A
receive takes the oldest value, and blocks only when the buffer is empty. Two built-ins report the
state: `cap(ch)` is the room, `len(ch)` how much of it is in use.

The same late receiver as section 02, but the channel now holds three, and the sender has five
values to send, saved as `buffered.go`:

```go
// Command buffered sends five values into a channel with room for three.
package main

import (
	"fmt"
	"time"
)

var start = time.Now()

func stamp(format string, args ...any) {
	ms := time.Since(start).Round(10 * time.Millisecond).Milliseconds()
	fmt.Printf("%4dms  "+format+"\n", append([]any{ms}, args...)...)
}

func main() {
	ch := make(chan int, 3)
	done := make(chan struct{})

	go func() {
		for i := 1; i <= 5; i++ {
			ch <- i
			stamp("sent %d, len %d of cap %d", i, len(ch), cap(ch))
		}
		close(ch)
		close(done)
	}()

	time.Sleep(300 * time.Millisecond)
	for v := range ch {
		stamp("received %d", v)
		time.Sleep(100 * time.Millisecond)
	}
	<-done
}
```

```
ana@vm:~/buffers$ go run buffered.go
   0ms  sent 1, len 1 of cap 3
   0ms  sent 2, len 2 of cap 3
   0ms  sent 3, len 3 of cap 3
 300ms  received 1
 300ms  sent 4, len 3 of cap 3
 400ms  received 2
 400ms  sent 5, len 3 of cap 3
 500ms  received 3
 600ms  received 4
 700ms  received 5
```

**The first three sends returned at 0 milliseconds**, with `len` climbing to 3: the buffer took
them and nobody had to be there. The fourth had to wait. It returned at 300, the moment the receiver
took `1` and freed a slot, and `len` was back at 3 because `4` filled the slot at once. From then on
the sender and receiver kept pace, one value per 100 milliseconds, because the receiver sleeps 100
between receives and every send waited for the slot it freed. After the close, the receiver still
took `3`, `4` and `5`, the values the buffer held.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two channels compared. Unbuffered: the channel has no room, so the sender waits from 0 to 300 milliseconds until the receiver arrives, and the value passes straight from one to the other. Buffered with room for three: the sender puts 1, 2 and 3 into the buffer at once and only waits on the fourth, when the buffer is full; the receiver takes values from the front.\"><defs><marker id=\"l04meet-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l04meet-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">unbuffered: make(chan string)</text><rect x=\"30\" y=\"48\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sender</text><rect x=\"570\" y=\"48\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">receiver</text><path d=\"M150 65 H566\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l04meet-amber)\"></path><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&quot;ping&quot;</text><text x=\"360\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no room: hand to hand</text><text x=\"90\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">waits until the receiver comes</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">buffered: make(chan int, 3)</text><rect x=\"30\" y=\"180\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sender</text><rect x=\"570\" y=\"180\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">receiver</text><rect x=\"280\" y=\"178\" width=\"46\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"303\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">3</text><rect x=\"334\" y=\"178\" width=\"46\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"357\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><rect x=\"388\" y=\"178\" width=\"46\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"411\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M272 172 H450 V222 H272 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M150 197 H268\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l04meet-amber)\"></path><text x=\"206\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">4</text><path d=\"M454 197 H566\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l04meet-phosphor)\"></path><text x=\"510\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">takes the oldest</text><text x=\"90\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">waits only when all three are taken</text></svg>", "caption": "An unbuffered send waits for its receiver. A buffered send waits only for room."}
```

So a buffer changes two things, and both matter for design.

- **It lets the sender run ahead, by at most the buffer's size.** A producer with bursts and a
  consumer with a steady pace can be decoupled by a buffer big enough for one burst.
- **It removes the meeting.** A send that returns has put the value in the buffer; it says nothing
  about whether anybody has received it. The guarantee of section 02 is gone.

What a buffer does not do is make a slow consumer fast. Here the buffer was full from the fourth
send on, and the sender went at the receiver's pace regardless. **A buffer absorbs a burst; it does
not absorb a difference in speed that lasts.** Making it bigger only delays the moment it fills,
and hides the mismatch in the meantime.

Two sizes have a meaning of their own. `0` is the unbuffered channel. `1` is a channel a sender can
always leave one value in without waiting, which lesson 6 uses to stop a goroutine from leaking.
Any other size is a number somebody chose, and the honest question about it is what happens when
it fills.
