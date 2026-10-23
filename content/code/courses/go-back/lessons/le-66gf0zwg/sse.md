---
title: Server-sent events, with nothing but net/http
version: 1
---

Server-sent events are an ordinary `GET` whose response never finishes. The server answers with the
content type `text/event-stream` and then writes messages as they happen, each one a `data:` line followed
by an empty line:

```
data: 118

data: 115

```

A browser reads that stream with `EventSource`, which is built in, and calls a function for every message.
This is the whole of the page's side, given an element `seatsLeft` to write the number into:

```javascript
const live = new EventSource("/events/1/live");
live.onmessage = (e) => { seatsLeft.textContent = e.data; };
```

**If the connection drops, `EventSource` opens it again by itself**, a few seconds later. The format also
has `id:` lines, so a reconnecting browser can say which message it saw last, and `event:` lines for
naming several kinds of message on one stream. boxoffice needs neither: every message is the whole number
of seats left, so the first message after a reconnect is everything the page needs.

## The handler

```go
// boxoffice/sse.go
package main

import (
	"fmt"
	"net/http"
	"time"
)

// liveEvents streams an event's availability as server-sent events.
func liveEvents(store Store, h *hub) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := pathID(w, r)
		if !ok {
			return
		}
		ch, unsubscribe := h.subscribe(id) // before reading, so no sale falls between the two
		defer unsubscribe()
		e, err := store.Get(r.Context(), id)
		if err != nil {
			fail(w, err)
			return
		}

		rc := http.NewResponseController(w)
		rc.SetWriteDeadline(time.Time{}) // this response is meant to outlive WriteTimeout
		w.Header().Set("Content-Type", "text/event-stream")
		w.Header().Set("Cache-Control", "no-store")
		fmt.Fprintf(w, "data: %d\n\n", e.Seats-e.Sold)
		rc.Flush()
		for {
			select {
			case <-r.Context().Done():
				return
			case n := <-ch:
				fmt.Fprintf(w, "data: %d\n\n", n)
				if err := rc.Flush(); err != nil {
					return
				}
			}
		}
	}
}
```

Read it in four steps.

- **It subscribes before it reads.** The first message is the availability as it stands, so a page opened
  between two sales is not blank until the next one. Reading first and subscribing after would leave a
  gap in which a sale is in neither, and that page would show a stale number until the sale after it.
  This order can at worst deliver the same number twice.
- **`SetWriteDeadline(time.Time{})` lifts lesson 1's `WriteTimeout` for this one response.** Section 08
  of lesson 1 set ten seconds as the most any response may take to write, and promised this route would
  be the exception. The zero time means no deadline. Every other route keeps its ten seconds.
- **`Flush` sends what has been written now**, instead of when the buffer fills or the handler returns,
  which for this handler is never. Without it the browser would receive nothing for a long time.
- **`r.Context().Done()` ends the loop when the visitor leaves.** Closing the tab closes the connection,
  net/http cancels the request's context, and the deferred `unsubscribe` takes the channel out of the
  hub.

Both `SetWriteDeadline` and `Flush` belong to the connection, and the handler does not hold the
connection's writer: it holds lesson 2's `statusRecorder`, which wraps it. `http.ResponseController`
finds the real one by calling `Unwrap`, which is the method section 03 of lesson 2 added to
`statusRecorder` for this lesson.

## A stream in a terminal

Section 05 puts the route in `routes.go` beside the WebSocket one. With both in place, `curl -N` turns off
curl's own buffering and prints each message as it arrives:

```
ana@vm:~/boxoffice$ curl -sN localhost:8080/events/1/live
data: 118

data: 115

data: 114
```

While it ran, two purchases were made from another terminal, eleven seconds apart:

```
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 3, "email": "rui@example.com"}' localhost:8080/events/1/tickets
{"ticket_id":2,"event_id":1,"quantity":3,"email":"rui@example.com","remaining":115}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 1, "email": "bea@example.com"}' localhost:8080/events/1/tickets
{"ticket_id":3,"event_id":1,"quantity":1,"email":"bea@example.com","remaining":114}
```

118 arrived at once, 115 with Rui's three seats and 114 with Bea's one. The stream ran for fourteen
seconds, until curl was stopped. **That is past the ten that `WriteTimeout` allows**, so the lifted
deadline did its job; lesson 12's access log, shown in section 05, records the request at just under
14,000 milliseconds and 33 bytes, the three messages of eleven bytes each.

A proxy in front of the server can undo all of this by buffering the response until it is complete,
which for this response means forever. nginx, for one, buffers by default and has to be told not to for
these routes. If events arrive in a burst when the connection closes, a buffer somewhere in the middle is
the first thing to look for.
