---
title: The bytes, measured
version: 1
---

"Protobuf is smaller" is said often and measured rarely, and the honest answer depends on what is compared
with what. This program builds the same list of events twice, as boxoffice's JSON would send it and as a
Protocol Buffers message with a repeated `Event`, and reports the sizes raw and compressed with gzip, the
way HTTP compresses a body when both sides agree to. Then it times encoding the larger list:

```go
// boxoffice/cmd/sizes/main.go
package main

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"example.com/boxoffice/internal/seatspb"
	"google.golang.org/protobuf/encoding/protowire"
	"google.golang.org/protobuf/proto"
)

type jsonEvent struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Seats int    `json:"seats"`
	Sold  int    `json:"sold"`
}

// encode writes the events as a message with one field, repeated Event events = 1.
func encode(events []*seatspb.Event) []byte {
	var b []byte
	for _, e := range events {
		msg, _ := proto.Marshal(e)
		b = protowire.AppendTag(b, 1, protowire.BytesType)
		b = protowire.AppendBytes(b, msg)
	}
	return b
}

func gzipped(b []byte) int {
	var buf bytes.Buffer
	w := gzip.NewWriter(&buf)
	w.Write(b)
	w.Close()
	return buf.Len()
}

func main() {
	for _, n := range []int{2, 200} {
		var pbs []*seatspb.Event
		var js []jsonEvent
		for i := 1; i <= n; i++ {
			name := fmt.Sprintf("Recital number %03d", i)
			pbs = append(pbs, &seatspb.Event{Id: int32(i), Name: name, Seats: 120, Sold: int32(i % 120)})
			js = append(js, jsonEvent{ID: i, Name: name, Seats: 120, Sold: i % 120})
		}
		j, _ := json.Marshal(js)
		p := encode(pbs)
		fmt.Printf("%3d events: JSON %6d bytes, %5d gzipped; protobuf %6d bytes, %5d gzipped\n",
			n, len(j), gzipped(j), len(p), gzipped(p))
		if n == 200 {
			jt := testing.Benchmark(func(b *testing.B) {
				for b.Loop() {
					json.Marshal(js)
				}
			})
			pt := testing.Benchmark(func(b *testing.B) {
				for b.Loop() {
					encode(pbs)
				}
			})
			fmt.Printf("encoding 200 events: JSON %v per list, protobuf %v per list\n",
				time.Duration(jt.NsPerOp()), time.Duration(pt.NsPerOp()))
		}
	}
}
```

`encode` writes the list exactly as a message declaring `repeated Event events = 1` would be written, one
tag and length per event, with `protowire`, the package that knows the wire format byte by byte. The two
encodings carry the same four fields. It ran twice:

```
ana@vm:~/boxoffice$ go run ./cmd/sizes
  2 events: JSON    117 bytes,   142 gzipped; protobuf     56 bytes,    81 gzipped
200 events: JSON  12094 bytes,  1430 gzipped; protobuf   5671 bytes,  1350 gzipped
encoding 200 events: JSON 35.146µs per list, protobuf 27.145µs per list
ana@vm:~/boxoffice$ go run ./cmd/sizes
  2 events: JSON    117 bytes,   142 gzipped; protobuf     56 bytes,    81 gzipped
200 events: JSON  12094 bytes,  1430 gzipped; protobuf   5671 bytes,  1350 gzipped
encoding 200 events: JSON 33.271µs per list, protobuf 27.296µs per list
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"Bars for two hundred events. Raw: JSON 12,094 bytes, protobuf 5,671. Gzipped: JSON 1,430, protobuf 1,350. The raw bars differ by more than half; the gzipped bars are almost the same length.\"><defs><marker id=\"gb-l11-bytes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"165\" y=\"31\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">JSON, raw</text><rect x=\"175\" y=\"18\" width=\"420.0\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"603.0\" y=\"31\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">12,094 B</text><text x=\"165\" y=\"75\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">protobuf, raw</text><rect x=\"175\" y=\"62\" width=\"196.9\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"379.9\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">5,671 B</text><text x=\"165\" y=\"119\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">JSON, gzipped</text><rect x=\"175\" y=\"106\" width=\"49.7\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"232.7\" y=\"119\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1,430 B</text><text x=\"165\" y=\"163\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">protobuf, gzipped</text><rect x=\"175\" y=\"150\" width=\"46.9\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"229.9\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1,350 B</text></svg>", "caption": "Two hundred events, measured by cmd/sizes. Compression removes most of what made JSON larger."}
```

**Raw, protobuf is less than half the size**: 5,671 bytes against 12,094 for two hundred events. The
names `"id"`, `"name"`, `"seats"` and `"sold"` are repeated in every JSON object and absent from protobuf,
and numbers are a byte or two instead of their digits.

**Compressed, the difference almost disappears**: 1,350 against 1,430 bytes, about six per cent. gzip is
very good at removing exactly the repetition that made JSON large. Since HTTP APIs compress their answers
as a matter of course, **for large lists the bandwidth argument for gRPC is small**. For tiny messages it
is the other way round: two events compress to more bytes than they started with, for both, because gzip's
header costs more than it saves, and there protobuf's 56 bytes against 117 is the whole difference.

**Encoding is faster, and not by much**: about 27 µs against 33 to 35 µs per list of two hundred, on this
machine. Next to the milliseconds a database query costs, from lesson 6, neither number matters to a
service like boxoffice. It matters to a service that does nothing but move messages, at hundreds of
thousands per second.

**The measurement does not say gRPC is pointless.** It says that size and speed are rarely the reason to
choose it. The reasons that hold up are in the contract, the streaming, the deadlines and the generated
clients, and they are the subject of the rest of this lesson.
