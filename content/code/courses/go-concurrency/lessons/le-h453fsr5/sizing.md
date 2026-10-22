---
title: How many workers
version: 1
---

`pool.go` chose fifty workers because fifty files at a time sat comfortably under the limit. That
is one of the two questions that decide the size of a pool, and the other is what the job spends
its time doing. **A job that computes wants about one worker per processor. A job that waits
wants as many workers as whatever it waits on will bear.** The program below measures both, with 64 jobs
and a number of workers given on the command line, saved as `size.go`:

```go
// Command size runs 64 jobs on a given number of workers and times them.
//
//	./size cpu 4     jobs that compute
//	./size wait 16   jobs that wait
package main

import (
	"fmt"
	"os"
	"strconv"
	"sync"
	"time"
)

// compute keeps one processor busy for about 30 ms.
func compute() {
	var x uint64
	for range 40_000_000 {
		x = x*6364136223846793005 + 1
	}
	sink = x
}

var sink uint64

// wait stands in for a request to another machine.
func wait() { time.Sleep(20 * time.Millisecond) }

func main() {
	job := compute
	if os.Args[1] == "wait" {
		job = wait
	}
	workers, _ := strconv.Atoi(os.Args[2])

	start := time.Now()
	jobs := make(chan int)
	var wg sync.WaitGroup
	for range workers {
		wg.Go(func() {
			for range jobs {
				job()
			}
		})
	}
	for i := range 64 {
		jobs <- i
	}
	close(jobs)
	wg.Wait()
	fmt.Printf("%-4s %2d workers: %v\n", os.Args[1], workers, time.Since(start).Round(time.Millisecond))
}
```

`os.Args[1]` and `os.Args[2]` are the two words after the program's name; lesson 21 does command
lines properly with the `flag` package. The `for range jobs` loop and the close are the shape from
section 02, without the results.

## Work that computes

```
ana@vm:~/pool$ for w in 1 2 4 8 16; do ./size cpu $w; done
cpu   1 workers: 2.039s
cpu   2 workers: 1.033s
cpu   4 workers: 572ms
cpu   8 workers: 543ms
cpu  16 workers: 560ms
```

One worker took 2.039 seconds, about 32 milliseconds a job. Two halved it, four nearly halved it
again to 572 milliseconds, and **past four the gains stopped**: eight and sixteen workers took 543
and 560, within a few tens of milliseconds of four, which is the noise between two runs. The lab has four processors, and `GOMAXPROCS` lets four goroutines compute
at once, as lesson 1 showed. A fifth worker has no processor to run on and only takes turns with the
others, which adds switching and saves nothing. For work like this, **`runtime.GOMAXPROCS(0)` is the
starting size**.

## Work that waits

```
ana@vm:~/pool$ for w in 1 4 16 64; do ./size wait $w; done
wait  1 workers: 1.295s
wait  4 workers: 324ms
wait 16 workers: 102ms
wait 64 workers: 20ms
```

Each job sleeps 20 milliseconds, so 64 of them one at a time took 1.295 seconds. Here every extra
worker helped, down to 20 milliseconds with 64 workers: one round, every job waiting at the same
time. **A waiting worker needs no processor**, lesson 1's `wait.go` again, so the processor count
sets no ceiling.

The ceiling comes from what the jobs wait on. A sleep can be shared by any number of goroutines; a
database that accepts a hundred connections cannot, nor can an API that allows ten requests a
second from you, nor a disk. So for waiting work the size of the pool is **the limit of the thing on
the other end**, minus whatever else uses it, and it is worth writing that reason beside the
number.

## Measure, then choose

The two runs disagree on purpose, and real jobs are rarely pure. A job that decodes a file is mostly
computing; one that calls three services is mostly waiting; most are a mixture. The method is the
one used here: **run the real job with a few sizes, double each time, and stop where the time stops
falling** or where the resource downstream starts to refuse. Benchmarks, lesson 29, are how to make
that measurement repeatable.
