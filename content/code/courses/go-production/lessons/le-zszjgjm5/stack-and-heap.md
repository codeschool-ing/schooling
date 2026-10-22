---
title: Goroutine stacks, and what lives on them
version: 1
---
The `go` course's lesson 24 split a program's memory in two: the stack, where a call's local
variables live and die with the call, and the heap, where a value goes when the compiler cannot
prove it dies with the call. It drew one stack. A Go program has as many as it has goroutines, and
the usual picture of a stack, a fixed block reserved when a thread starts, is wrong for every one of
them. **A goroutine's stack starts at 2 KiB and grows by being copied, whole, to a block twice the
size.** That is why ten thousand goroutines cost twenty megabytes of stack, and it rests on a rule
about pointers that the compiler enforces for you.

## A thread's stack and a goroutine's

An operating-system thread gets its stack when it starts, and the stack never moves. `ulimit -s`
shows the size this machine gives the main thread, in KiB, and the runtime's source shows what a
goroutine gets:

```
ana@vm:~/mem-stacks$ ulimit -s
8192
ana@vm:~/mem-stacks$ sed -n 77,78p /usr/local/go/src/runtime/stack.go
	// The minimum size of stack used by Go code
	stackMin = 2048
```

**8,192 KiB against 2,048 bytes, a factor of four thousand.** A thread's stack has to be large,
because nothing can enlarge it later: a program that recurses past it is killed. A goroutine's can
be small because the runtime enlarges it the moment it is about to run out. Almost every Go function
begins with a few instructions that compare the stack pointer with the end of the current stack.
When the next frame would not fit, the runtime allocates a block twice the size, copies the stack
into it and carries on.

A program in `~/mem-stacks` watches that happen. It starts ten thousand goroutines that wait, then
calls a function 100,000 levels deep, and reports the runtime's own count of stack memory at each
step:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command stacks watches goroutine stacks: how big they start, and how one\n// grows, moves and shrinks.\npackage main\n\nimport (\n\t\"flag\"\n\t\"fmt\"\n\t\"runtime\"\n\t\"runtime/debug\"\n\t\"runtime/metrics\"\n\t\"sync\"\n\t\"unsafe\"\n)\n",
      "note": "`runtime/metrics` is the runtime's own accounting, read by name. `unsafe` is here for one conversion, explained below; lesson 22 is about the package."
    },
    {
      "code": "// read returns the current value of one runtime metric.\nfunc read(name string) uint64 {\n\ts := []metrics.Sample{{Name: name}}\n\tmetrics.Read(s)\n\treturn s[0].Value.Uint64()\n}\n\n// stacksKiB is the memory the runtime holds for goroutine stacks.\nfunc stacksKiB() uint64 {\n\treturn read(\"/memory/classes/heap/stacks:bytes\") >> 10\n}\n",
      "note": "**A metric is read by its name, and the unit is part of the name.** `/memory/classes/heap/stacks:bytes` is all the memory the runtime has set aside for goroutine stacks, the ones in use and the ones kept for reuse."
    },
    {
      "code": "// down calls itself n times. Each call's frame holds a 256-byte array.\nfunc down(n int) byte {\n\tvar pad [256]byte\n\tpad[n%256] = byte(n)\n\tif n == 0 {\n\t\treturn pad[0]\n\t}\n\treturn down(n-1) + pad[n%256]\n}\n",
      "note": "Recursion with a frame of a known size. The array is local and never leaves the call, so it lives in the frame, and every call adds a little over 256 bytes to the stack."
    },
    {
      "code": "func main() {\n\tdepth := flag.Int(\"depth\", 100_000, \"how many calls deep to go\")\n\tlimit := flag.Int(\"max\", 0, \"the largest stack allowed, in bytes (0: the default)\")\n\tflag.Parse()\n\tif *limit > 0 {\n\t\tdebug.SetMaxStack(*limit)\n\t}\n",
      "note": "Two flags: how deep to go, and a ceiling on the stack. `debug.SetMaxStack` lowers the ceiling so that an overflow happens at a megabyte and not at the default."
    },
    {
      "code": "\tfmt.Printf(\"a new goroutine starts with %d bytes\\n\", read(\"/gc/stack/starting-size:bytes\"))\n\tbefore := stacksKiB()\n\tvar wg sync.WaitGroup\n\trelease := make(chan struct{})\n\tfor range 10_000 {\n\t\twg.Go(func() { <-release })\n\t}\n\tfmt.Printf(\"10,000 goroutines waiting: %d KiB of stacks more\\n\", stacksKiB()-before)\n\tclose(release)\n\twg.Wait()\n\truntime.GC()\n",
      "note": "**Ten thousand goroutines that do nothing but wait**, and the stack memory measured before and after. `wg.Go` starts a goroutine and counts it in one call. The collection at the end frees the stacks of the goroutines that have finished."
    },
    {
      "code": "\tx := 1\n\tfmt.Printf(\"stacks %6d KiB, x at %#x\\n\", stacksKiB(), uintptr(unsafe.Pointer(&x)))\n\tdown(*depth)\n\tfmt.Printf(\"stacks %6d KiB, x at %#x, after %d calls\\n\", stacksKiB(), uintptr(unsafe.Pointer(&x)), *depth)\n\tfor range 3 {\n\t\truntime.GC()\n\t\tfmt.Printf(\"stacks %6d KiB, x at %#x, after a collection\\n\", stacksKiB(), uintptr(unsafe.Pointer(&x)))\n\t}\n}",
      "note": "`uintptr(unsafe.Pointer(&x))` turns the address of `x` into a plain number. A number is not a pointer, so `x` stays in `main`'s frame, and printing it shows **where the frame is now**. Then the deep call, and three collections in a row."
    }
  ]
}
```

Built and run with the defaults:

```
ana@vm:~/mem-stacks$ go build -o stacks . && ./stacks
a new goroutine starts with 2048 bytes
10,000 goroutines waiting: 20000 KiB of stacks more
stacks   1280 KiB, x at 0x3d6e0e954de0
stacks  34080 KiB, x at 0x3d6e14407de0, after 100000 calls
stacks  17664 KiB, x at 0x3d6e11487de0, after a collection
stacks   9504 KiB, x at 0x3d6e123ffde0, after a collection
stacks   5408 KiB, x at 0x3d6e10887de0, after a collection
```

The first two lines are the cheap end. **A new goroutine starts with 2,048 bytes, and ten thousand
waiting goroutines took 20,000 KiB**: ten thousand stacks of exactly 2 KiB. With threads, the same
ten thousand would reserve 8 MiB each.

The rest is the expensive end. After 100,000 calls of a little over 256 bytes each, the stack memory
went from 1,280 KiB to 34,080 KiB: `main`'s stack had been doubled again and again until it held
about 32 MiB. **And `x`, a variable of `main` that nothing touched, is at a different address.** It
was never reassigned and never escaped; the whole frame it sits in was copied to the new block, and
it moved with it. Each collection after that moved it again, because the collector shrinks a stack
that uses less than a quarter of its size, by half at a time: 17,664, then 9,504, then 5,408 KiB.
Goroutine stacks are memory the collector manages, like the heap, and they shrink back without any
help.

## Why a stack can move

Copying a stack to a new address is only safe if every pointer to something on it can be found and
fixed. Pointers inside the stack itself are easy: the compiler records, for every function, which
words of its frame hold pointers, and the runtime adjusts them during the copy. A pointer held on
the heap would be another matter. The runtime would have to search the whole heap for pointers into
the old block, at every growth of every goroutine.

**It never has to, because no value on the heap may point into a stack.** That is the first of the
two invariants escape analysis exists to keep, in the words of the compiler's own source
(`cmd/compile/internal/escape/escape.go`): "pointers to stack objects cannot be stored in the heap".
When code would store the address of a local variable somewhere on the heap, the compiler puts the
variable on the heap instead, and the stack is left holding only pointers outward.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Goroutine stacks beside the heap. Two new goroutines each have a 2 KiB stack; 10,000 of them take 20,000 KiB. The main goroutine, 100,000 calls deep, has a 32 MiB stack. Arrows run from frames on the stacks to values on the shared heap, and between heap values, but never from the heap into a stack. Because of that, a full stack can be copied whole to a block twice the size, fixing only the pointers inside it.\"><defs><marker id=\"stk-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"stk-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"160\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">goroutine stacks: one each</text><text x=\"530\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the heap: one, shared</text><rect x=\"30\" y=\"40\" width=\"90\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">32 MiB</text><path d=\"M36 72 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 84 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 96 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 108 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 120 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 132 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 144 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 156 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 168 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 180 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 192 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 204 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 216 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 228 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"75\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">main, after</text><text x=\"75\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">100,000 calls</text><rect x=\"150\" y=\"196\" width=\"70\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2 KiB</text><path d=\"M156 224 H214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"235\" y=\"196\" width=\"70\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2 KiB</text><path d=\"M241 224 H299\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"185\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a new one</text><text x=\"270\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">waiting</text><text x=\"228\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">10,000 of these: 20,000 KiB</text><rect x=\"360\" y=\"36\" width=\"340\" height=\"214\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"385\" y=\"62\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"520\" y=\"62\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"600\" y=\"128\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"385\" y=\"130\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"385\" y=\"196\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"520\" y=\"196\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M121 80 L382 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M121 150 L382 143\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M306 210 L382 209\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M466 75 L517 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M600 89 L630 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M466 143 L597 141\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M466 209 L517 209\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M392 223 C 375 246, 340 246, 308 234\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#stk-am)\"></path><path d=\"M343 236 L355 248 M355 236 L343 248\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"410\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">never: a heap value pointing into a stack</text><text x=\"360\" y=\"304\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">A stack that runs out is copied whole to a block twice the size; only the pointers inside it need fixing.</text></svg>", "caption": "Pointers run from stacks into the heap and never back, which is what lets the runtime move a stack."}
```

That is the same decision lesson 24 of the `go` course watched the compiler make with `-gcflags=-m`,
seen from the other side. **A value escapes when a pointer to it could outlive its frame or be
stored on the heap**; the compiler's reasons, and how to read them, are lesson 20. For this lesson
one consequence is enough: what stays on a stack costs the collector nothing, and what escapes is an
allocation the collector of section 03 has to find again later.

## The ceiling

Growth is not unlimited. The runtime refuses to grow a stack past a maximum, and `-max` lowers that
maximum through `debug.SetMaxStack` so the refusal comes quickly:

```
ana@vm:~/mem-stacks$ ./stacks -max 1000000 2>&1 | head -6; echo ${PIPESTATUS[0]}
a new goroutine starts with 2048 bytes
10,000 goroutines waiting: 20064 KiB of stacks more
stacks   1056 KiB, x at 0x26184975ede0
runtime: goroutine stack exceeds 1000000-byte limit
runtime: sp=0x26184ac783b0 stack=[0x26184ac78000, 0x26184acf8000]
fatal error: stack overflow
2
ana@vm:~/mem-stacks$ sed -n 160,167p /usr/local/go/src/runtime/proc.go
	// Max stack size is 1 GB on 64-bit, 250 MB on 32-bit.
	// Using decimal instead of binary GB and MB because
	// they look nicer in the stack overflow failure message.
	if goarch.PtrSize == 8 {
		maxstacksize = 1000000000
	} else {
		maxstacksize = 250000000
	}
```

**A stack overflow is a fatal error, not a panic.** No `recover` catches it, the runtime prints the
goroutine's stack (cut off here by `head`) and exits with status 2. The default ceiling is
1,000,000,000 bytes on a 64-bit machine, written in decimal, as the comment says, so that the
message reads well. A call that never stops recursing reaches it, a hundred million calls asked for
and the default left alone:

```
ana@vm:~/mem-stacks$ time ./stacks -depth 100000000 2>&1 | sed -n 4,6p
runtime: goroutine stack exceeds 1000000000-byte limit
runtime: sp=0x2e31a2300350 stack=[0x2e31a2300000, 0x2e31c2300000]
fatal error: stack overflow

real	0m0.863s
user	0m0.317s
sys	0m0.527s
```

Under a second, because each doubling copies only what is in use and there are about nineteen of
them between 2 KiB and a gigabyte. **The cost of a runaway recursion in Go is a gigabyte of memory
for a moment**, where a thread's 8 MiB would have ended it sooner; a server that recurses on input
it was sent wants its own depth limit long before either.

One more thing in the source explains why the first line of the program is worth printing:

```
ana@vm:~/mem-stacks$ grep -n "adaptivestackstart = " /usr/local/go/src/runtime/runtime1.go
397:	debug.adaptivestackstart = 1 // set this to 0 to turn larger initial goroutine stacks off
```

The starting size is not fixed at 2 KiB. **At every collection the runtime measures how much stack
the goroutines it scanned were using, and starts new goroutines at that average**, rounded up to a
power of two. A program whose goroutines all go 20 KiB deep stops paying for the same few growths in
every one of them. `/gc/stack/starting-size:bytes` reports the current value; `~/mem-stacks` printed
2,048 because it read the metric before the first collection had measured anything.
