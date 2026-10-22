---
title: How the collector marks while the program runs
version: 1
---
Lesson 24 of the `go` course established that Go's collector does its marking while the program
keeps running, and stops it only briefly. That raises a question it left alone. Marking means
following every pointer from the roots, and the program is changing those pointers the whole time.
**What stops the program from hiding a live value from a marker that is halfway through the heap?**
The answer is a colour for every value and a few instructions the compiler adds to every pointer
write, and both show up as numbers in a `gctrace` line.

## Three colours

The runtime describes marking with three colours, and the words are its own (`mgc.go` says "grey
objects", "scanning each grey object to black"):

- **white**: not reached yet. At the end of marking, white means garbage.
- **grey**: reached, but its own pointers have not been followed yet. The grey values are the
  marker's to-do list.
- **black**: reached, and every pointer inside it has been followed.

A cycle starts with everything white. The roots, the package variables and every goroutine's stack,
shade what they point at grey. A marker then takes a grey value, shades everything it points at
grey, and turns it black, over and over, until nothing is grey. Whatever is still white was never
reached from a root, and the sweep reuses its memory. Values allocated while marking runs are made
black at once, since the program clearly still has a pointer to them.

**The rule that makes this correct is that a black value never points at a white one.** A black
value has been dealt with, and the marker will not look inside it again. If the program stores a
pointer to a white value in a black one, and removes every other path to it, the white value will
never be reached, and it will be freed while the program is still using it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Tri-colour marking and the write barrier. Before: a stack points at A, which is black, and at B, which is grey; B points at C, which is white. The program sets A.next to C and B.next to nil. After: A points at C, nothing grey points at C, and without help C would stay white and be freed while A still uses it. The write barrier shaded C grey when B.next was overwritten, so C will be scanned.\"><defs><marker id=\"tri-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"tri-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"175\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1. Marking is under way</text><rect x=\"20\" y=\"50\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a stack</text><rect x=\"140\" y=\"48\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\"></rect><text x=\"160\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">A</text><text x=\"200\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">black</text><rect x=\"140\" y=\"128\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">B</text><text x=\"200\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">grey</text><rect x=\"140\" y=\"208\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"160\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">C</text><text x=\"200\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">white</text><path d=\"M101 65 L137 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tri-ph)\"></path><path d=\"M101 72 C 120 110, 120 140, 137 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tri-ph)\"></path><path d=\"M188 163 L188 205\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tri-ph)\"></path><text x=\"250\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">B.next = nil</text><text x=\"250\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">A.next = C</text><text x=\"545\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2. After the two writes</text><rect x=\"390\" y=\"50\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a stack</text><rect x=\"510\" y=\"48\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\"></rect><text x=\"530\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">A</text><text x=\"570\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">black</text><rect x=\"510\" y=\"128\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">B</text><text x=\"570\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">grey</text><rect x=\"510\" y=\"208\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">C</text><text x=\"570\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">grey</text><path d=\"M471 65 L507 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tri-ph)\"></path><path d=\"M471 72 C 490 110, 490 140, 507 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tri-ph)\"></path><path d=\"M607 70 C 670 110, 670 210, 609 224\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tri-ph)\"></path><text x=\"620\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the barrier shaded C: it will be scanned</text><path d=\"M355 40 V280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path></svg>", "caption": "The program moves the only pointer to C from a grey object to a black one; the write barrier shades C so marking does not miss it."}
```

## The write barrier

The two writes in the figure are ordinary Go, `a.next = c` and `b.next = nil`, and they can happen
between any two steps of the marker. So while a cycle is marking, **every write of a pointer into
the heap goes through a write barrier**, a short piece of code the compiler puts in front of the
store. The runtime's source gives the whole of it in five lines:

```
ana@vm:~/mem-hits$ sed -n 31,35p /usr/local/go/src/runtime/mbarrier.go
//     writePointer(slot, ptr):
//         shade(*slot)
//         if current stack is grey:
//             shade(ptr)
//         *slot = ptr
```

`slot` is the field being written and `ptr` the new value. The first shade colours what the field
pointed at **before** the write: in the figure, `b.next = nil` shades C grey on its way out, so
removing the last grey path to C cannot hide it. The second colours the new value, but only while
the writing goroutine's own stack has not been scanned yet, because until then that stack may hold
pointers the marker has not seen. Writes to a stack never go through the barrier, which is why
stacks are scanned instead, each goroutine stopped for the moment its own stack takes.

The barrier is off when no cycle is marking: the compiled code checks one flag and skips it. A
program that allocates heavily is marking much of the time, so it pays for the barrier often, which
is how lesson 13 came to find write barriers among the costs of `strings.Fields` filling the slice
it returns.

## Assists, and the share the collector takes

Marking runs on the program's own processors. The runtime plans to give it a quarter of them:

```
ana@vm:~/mem-hits$ grep -n "gcBackgroundUtilization = " /usr/local/go/src/runtime/mgcpacer.go
39:	gcBackgroundUtilization = 0.25
```

On the lab's four processors that is one background worker. **If the program allocates faster than
that worker marks, the allocating goroutines are made to help**: before a goroutine gets new memory
in the middle of a cycle, it does some marking itself, in proportion to what it asked for. That is a
mutator assist, and it is the way a collection that is falling behind slows the program down, a
little at a time, instead of stopping it.

## A real trace, field by field

`hits count` on two million lines of `genlog`'s log, about 91 MB, is a program that allocates
quickly and keeps almost nothing: lesson 12's benchmark counted two allocations a line, and the
counts it keeps fit in a few maps. In `~/mem-hits`, lesson 1's `main.go`, `internal/tally/tally.go`
and `tools/genlog/main.go` placed as lesson 1 printed them, with a module of its own:

```
ana@vm:~/mem-hits$ go build -o hits . && go build -o genlog ./tools/genlog
ana@vm:~/mem-hits$ ./genlog -n 2000000 > big.log; stat -c "%s bytes  %n" big.log
91465537 bytes  big.log
ana@vm:~/mem-hits$ GODEBUG=gctrace=1 ./hits count big.log 2>&1 >/dev/null | head -4
gc 1 @0.008s 1%: 0.12+1.1+0.008 ms clock, 0.51+0.10/0.14/0+0.034 ms cpu, 3->4->0 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 2 @0.017s 1%: 0.032+1.2+0.004 ms clock, 0.13+0.025/0.001/0.11+0.019 ms cpu, 3->3->0 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 3 @0.024s 1%: 0.14+1.9+0.063 ms clock, 0.56+0/0.082/0.11+0.25 ms cpu, 3->4->0 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 4 @0.030s 0%: 0.019+1.9+0.004 ms clock, 0.078+0/0.015/0.11+0.017 ms cpu, 3->3->0 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 4 P
ana@vm:~/mem-hits$ GODEBUG=gctrace=1 ./hits count big.log 2>&1 >/dev/null | grep -c "^gc "
85
```

`2>&1 >/dev/null` sends the trace, which goes to standard error, into the pipe and throws the
program's own table away. **Eighty-five collections for one run of a counting program**, and the
format is the one `go doc runtime` gives under `gctrace`. Here is `gc 2`, every field of it:

| field | in `gc 2` | what it says |
|---|---|---|
| `gc #` | `gc 2` | the second cycle of this run |
| `@#s` | `@0.017s` | it began 17 ms after the program started |
| `#%` | `1%` | the share of the run so far spent collecting |
| clock | `0.032+1.2+0.004 ms` | the stop that starts the cycle, the concurrent mark, the stop that ends it, in wall-clock time |
| cpu, first | `0.13` | the first stop, in processor time |
| cpu, mark | `0.025/0.001/0.11` | marking done by assists, by the background worker, and by otherwise idle processors |
| cpu, last | `0.019` | the second stop, in processor time |
| `#->#-># MB` | `3->3->0 MB` | the heap when marking began, when it ended, and what was found alive |
| goal | `4 MB goal` | the heap size this cycle meant to finish under |
| stacks, globals | `0 MB`, `0 MB` | stacks and package variables to scan, both under a megabyte |
| `# P` | `4 P` | the processors the program runs on |

The two stops are the ones the runtime's documentation names: sweep termination, which finishes the
previous cycle's sweeping and turns the barrier on, and mark termination, which ends marking and
turns it off. **Two of the numbers check each other.** The stops last 0.032 and 0.004 ms on the
clock and 0.13 and 0.019 ms of processor time, close to four times as much, because a stop holds all
four processors at once. The runtime's printing code multiplies by exactly that:

```
ana@vm:~/mem-hits$ sed -n 1609,1615p /usr/local/go/src/runtime/mgc.go
		for i, ns := range []int64{
			int64(work.stwprocs) * (work.tMark - work.tSweepTerm),
			gcController.assistTime.Load(),
			gcController.dedicatedMarkTime.Load() + gcController.fractionalMarkTime.Load(),
			gcController.idleMarkTime.Load(),
			int64(work.stwprocs) * (work.tEnd - work.tMarkTerm),
		} {
```

The mark is the reverse: 1.2 ms of wall-clock time, while the program kept running, and 0.136 ms of
processor time spread across three kinds of worker. In this cycle the assists did more marking than
the background worker. That is `hits` allocating faster than one worker could keep up with, and the
runtime making the allocating goroutine pay for it as it went.

## Why the goal says 4 MB

`3->3->0` says that almost nothing survives a cycle, and the goal of the next one should be twice
nothing, by the rule lesson 24 of the `go` course gave for `GOGC=100`. It is 4 MB, because the pacer
has a floor:

```
ana@vm:~/mem-hits$ sed -n 58,60p /usr/local/go/src/runtime/mgcpacer.go; sed -n 1343p /usr/local/go/src/runtime/mgcpacer.go
	// defaultHeapMinimum is the value of heapMinimum for GOGC==100.
	defaultHeapMinimum = (goexperiment.HeapMinimum512KiBInt)*(512<<10) +
		(1-goexperiment.HeapMinimum512KiBInt)*(4<<20)
	c.heapMinimum = defaultHeapMinimum * uint64(in) / 100
```

**The minimum heap goal is 4 MB at `GOGC=100`, and it scales with `GOGC`.** A `GOEXPERIMENT` could
lower it to 512 KiB, which is the other half of the expression; in 1.27.1 that experiment is off and
the 4 MB half applies. So a program with a tiny live heap collects every time it has allocated about
4 MB, and the fifth cycle under two other settings shows the floor moving with the setting:

```
ana@vm:~/mem-hits$ for g in 50 200; do GOGC=$g GODEBUG=gctrace=1 ./hits count big.log 2>&1 >/dev/null | sed -n 5p; done
gc 5 @0.024s 1%: 0.13+2.3+0.021 ms clock, 0.52+0/0.071/0.71+0.086 ms cpu, 1->1->0 MB, 2 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 5 @0.077s 0%: 0.043+1.0+0.003 ms clock, 0.17+0/0.031/0.14+0.014 ms cpu, 7->7->0 MB, 8 MB goal, 0 MB stacks, 0 MB globals, 4 P
```

A 2 MB goal at `GOGC=50` and an 8 MB one at `GOGC=200`. For `hits count`, then, `GOGC` decides
nothing but how many tiny collections there are. The work they do is marking a heap with almost
nothing on it, which is why every cycle above finished its mark in under 2.5 ms and the `#%` column
of those lines never rose above 1%. Section 04 measures a program for which the setting matters.
