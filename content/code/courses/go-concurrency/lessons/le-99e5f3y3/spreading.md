---
title: Spreading work across goroutines
version: 1
---

**Fan-out is several goroutines reading from one channel**, so that a stream of work is shared
among them. Lesson 7 built the worker pool to put a limit on how much runs at once. This lesson is
about the other half of the same shape: who gets which piece, in what order the answers come back,
and what happens when one piece fails.

The picture people bring is a dealer at a card table, handing job 1 to the first worker, job 2 to
the second, and round again. **Nobody deals.** Each worker asks the channel for its next job when
it is free, and the channel hands each value to exactly one of the goroutines waiting on it. The
program below sends twelve jobs of different sizes, 10 to 40 milliseconds each and 300 in all, to
three workers. Each records the jobs it took, under a lock from lesson 8. It is saved in
`~/fanout/spread` as `spread.go`:

```go
// Command spread hands twelve jobs of different sizes to three workers through one channel.
package main

import (
	"fmt"
	"sync"
	"time"
)

func main() {
	jobs := make(chan int)
	var mu sync.Mutex
	took := map[string][]int{}

	var wg sync.WaitGroup
	for _, name := range []string{"w1", "w2", "w3"} {
		wg.Go(func() {
			for job := range jobs {
				time.Sleep(time.Duration(job%4+1) * 10 * time.Millisecond)
				mu.Lock()
				took[name] = append(took[name], job)
				mu.Unlock()
			}
		})
	}

	start := time.Now()
	for job := 1; job <= 12; job++ {
		jobs <- job
	}
	close(jobs)
	wg.Wait()

	for _, name := range []string{"w1", "w2", "w3"} {
		fmt.Println(name, took[name])
	}
	fmt.Println("twelve jobs, 300ms of work, took", time.Since(start).Round(10*time.Millisecond))
}
```

Run twice:

```
ana@vm:~/fanout$ go run ./spread
w1 [2 5 8 10]
w2 [3 7 11]
w3 [1 4 6 9 12]
twelve jobs, 300ms of work, took 120ms
ana@vm:~/fanout$ go run ./spread
w1 [2 5 8 9 11]
w2 [3 7 12]
w3 [1 4 6 10]
twelve jobs, 300ms of work, took 120ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Fan-out in spread.go. main sends jobs 1 to 12 into one unbuffered channel, jobs. Three workers range over the same channel, and each job goes to exactly one of them, whichever is free. In the first run w1 took 2, 5, 8 and 10; w2 took 3, 7 and 11; w3 took 1, 4, 6, 9 and 12. Closing jobs ends all three loops.\"><defs><marker id=\"l13fan-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main</text><text x=\"80\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sends 1 … 12, then closes</text><rect x=\"210\" y=\"105\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">jobs</text><text x=\"285\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one channel, three readers</text><path d=\"M142 125 H207\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13fan-phosphor)\"></path><rect x=\"470\" y=\"40\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">w1</text><text x=\"610\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2 5 8 10</text><path d=\"M362 125 L467 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13fan-phosphor)\"></path><rect x=\"470\" y=\"110\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">w2</text><text x=\"610\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">3 7 11</text><path d=\"M362 125 L467 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13fan-phosphor)\"></path><rect x=\"470\" y=\"180\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">w3</text><text x=\"610\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1 4 6 9 12</text><path d=\"M362 125 L467 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13fan-phosphor)\"></path><text x=\"470\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">each job reaches exactly one worker</text></svg>", "caption": "spread.go's first run. Nobody deals the jobs out: whichever worker is free takes the next one."}
```

Three things in those eight lines are the whole pattern.

- **Every job was done once.** The twelve numbers appear exactly once across the three lists, in
  both runs. A channel never gives one value to two receivers, so fan-out needs no bookkeeping to
  avoid doing a job twice.
- **The split follows speed, not turns.** `w3` took five jobs in the first run and four in the
  second; `w2` took three both times. A worker that drew short jobs came back sooner and drew more.
  That is exactly what you want from a shared queue, and it is why the split differs between runs.
- **The total was 120 milliseconds for 300 of work**, close to a third, because three workers
  shared it. It was more than 100 because the last jobs to be handed out cannot be split, and some
  worker always finishes last.

**Closing `jobs` is the signal that there is no more work**, and it reaches every worker at once:
each `for job := range jobs` loop ends when the channel is closed and empty, as lesson 3 showed.
`main` closes it after the last send, because the sender is the one that knows when sending is
over, and then waits for the three with `wg.Wait`.

One worker reading a channel is a loop. Several reading the same channel are fan-out, and the only
change in the code is how many goroutines run that loop.
