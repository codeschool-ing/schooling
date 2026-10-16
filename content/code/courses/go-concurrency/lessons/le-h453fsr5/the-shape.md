---
title: The shape of a worker pool
version: 1
---

Goroutines are cheap, lesson 2 measured how cheap, and that tempts everybody into one goroutine per
job. **The goroutines are cheap; what the jobs touch is not.** Each one may hold a file, a
connection to a database, a slot in somebody else's rate limit, or a share of the memory. A
thousand jobs at once means a thousand of those at once, and the machine or the server on the other
end has a limit that a goroutine count knows nothing about.

## A thousand jobs, a thousand files

The first program starts one goroutine per job, and every job opens a file, works for 50
milliseconds and closes it. A mutex, lesson 8's subject, guards the two variables the goroutines
share. It is built with `go build -o unbounded unbounded.go`, like every program in this lesson,
and saved as `unbounded.go`:

```go
// Command unbounded starts one goroutine per job, and every job holds a file open.
package main

import (
	"fmt"
	"os"
	"sync"
	"time"
)

// job opens a file, works on it for a moment, and closes it.
func job() error {
	f, err := os.Open("/etc/hostname")
	if err != nil {
		return err
	}
	defer f.Close()
	time.Sleep(50 * time.Millisecond)
	return nil
}

func main() {
	var mu sync.Mutex
	failed := 0
	var lastErr error
	var wg sync.WaitGroup
	for range 1000 {
		wg.Go(func() {
			if err := job(); err != nil {
				mu.Lock()
				failed++
				lastErr = err
				mu.Unlock()
			}
		})
	}
	wg.Wait()
	fmt.Println("jobs: 1000  failed:", failed)
	if lastErr != nil {
		fmt.Println("last error:", lastErr)
	}
}
```

A process may only have so many files open at once, and `ulimit -n` prints that limit for the
shell and everything it starts. Run under the machine's limit, and then under a lower one in a
subshell, which is what the parentheses are for, so the lower limit ends with them:

```
ana@vm:~/pool$ ulimit -n
1024
ana@vm:~/pool$ ./unbounded
jobs: 1000  failed: 0
ana@vm:~/pool$ (ulimit -n 256; ./unbounded)
jobs: 1000  failed: 752
last error: open /etc/hostname: too many open files
```

**Under 1,024 it worked, and under 256 three jobs in four failed**: 752 of them. Nothing in the program changed.
At its peak it had nearly a thousand files open at once, because a thousand goroutines reached
`os.Open` within the same few milliseconds. Under the higher limit it got away with it; the lower
one is what a busier machine, a container or a database's connection limit looks like. A program
that works only while the resource is plentiful has its limit set by accident.

## A fixed number of workers

A worker pool turns the arrangement round. **A fixed number of goroutines, the workers, each take
jobs from a channel one at a time**, so no more than that many jobs are in progress whatever the
size of the queue. Three roles make it work: someone feeds the jobs and
closes the channel, the workers drain it, and someone closes the results once the workers are done.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A worker pool. A producer goroutine sends job numbers on the channel jobs and closes it when it has sent them all. A fixed number of workers, here three of fifty, each take the next job from jobs and send the result on the channel results. A closer goroutine waits for every worker with wg.Wait and then closes results. main reads results until it is closed.\"><defs><marker id=\"l07pool-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07pool-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l07pool-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"110\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">producer</text><text x=\"95\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sends 1000 jobs, then close(jobs)</text><rect x=\"195\" y=\"125\" width=\"70\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">jobs</text><path d=\"M172 145 H193\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-phosphor)\"></path><text x=\"390\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">workers: a fixed number</text><rect x=\"330\" y=\"45\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">worker 1</text><path d=\"M267 145 L328 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-phosphor)\"></path><path d=\"M452 65 L493 145\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-amber)\"></path><rect x=\"330\" y=\"105\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">worker 2</text><path d=\"M267 145 L328 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-phosphor)\"></path><path d=\"M452 125 L493 145\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-amber)\"></path><rect x=\"330\" y=\"165\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">worker 3</text><path d=\"M267 145 L328 185\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-phosphor)\"></path><path d=\"M452 185 L493 145\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-amber)\"></path><text x=\"390\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">… 47 more</text><rect x=\"495\" y=\"125\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">results</text><rect x=\"600\" y=\"115\" width=\"105\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main</text><text x=\"652\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">reads until results is closed</text><path d=\"M577 145 H598\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-amber)\"></path><rect x=\"470\" y=\"250\" width=\"235\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"587\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">closer</text><text x=\"587\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">wg.Wait(); close(results)</text><path d=\"M535 248 V167\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l07pool-wire)\"></path></svg>", "caption": "pool.go: the queue may be any length, and no more than fifty jobs are in progress at once."}
```

The program, piece by piece, saved as `pool.go`:

```schooling-example
{"language": "go", "file": "pool.go", "parts": [{"code": "// Command pool runs 1000 jobs on a fixed number of workers.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"os\"\n\t\"sync\"\n\t\"time\"\n)\n\n", "note": "The standard library, and nothing else."}, {"code": "func job() error {\n\tf, err := os.Open(\"/etc/hostname\")\n\tif err != nil {\n\t\treturn err\n\t}\n\tdefer f.Close()\n\ttime.Sleep(50 * time.Millisecond)\n\treturn nil\n}\n\n", "note": "**The same job as `unbounded.go`.** It holds a file open for 50 milliseconds, which is the resource the pool exists to ration."}, {"code": "func main() {\n\tconst workers = 50\n\tstart := time.Now()\n\n", "note": "**The size of the pool is one number, chosen here.** Fifty workers means at most fifty files open at once, whatever the number of jobs."}, {"code": "\tjobs := make(chan int)\n\tresults := make(chan error)\n\n", "note": "Two unbuffered channels: `jobs` carries work to the workers, `results` carries their answers back. The values on `jobs` are only job numbers, because the job itself needs no input."}, {"code": "\tvar wg sync.WaitGroup\n\tfor range workers {\n\t\twg.Go(func() {\n\t\t\tfor range jobs {\n\t\t\t\tresults <- job()\n\t\t\t}\n\t\t})\n\t}\n\n", "note": "**The workers.** Fifty goroutines, each running a `for range` over `jobs`, so each takes the next job as soon as it finishes the last. The loop ends when `jobs` is closed and empty, and the worker returns."}, {"code": "\tgo func() {\n\t\tfor i := range 1000 {\n\t\t\tjobs <- i\n\t\t}\n\t\tclose(jobs)\n\t}()\n\n", "note": "**The producer**, in a goroutine of its own, hands out a thousand jobs and then closes `jobs`. Closing is what lets every worker's loop end."}, {"code": "\tgo func() {\n\t\twg.Wait()\n\t\tclose(results)\n\t}()\n\n", "note": "**The closer.** When all fifty workers have returned, nothing will send on `results` again, so this goroutine closes it. Without it the loop below would wait forever, the receiver leak of lesson 6."}, {"code": "\tfailed := 0\n\tfor err := range results {\n\t\tif err != nil {\n\t\t\tfailed++\n\t\t}\n\t}\n\tfmt.Println(\"jobs: 1000  workers:\", workers, \" failed:\", failed, \" took:\", time.Since(start).Round(10*time.Millisecond))\n}\n", "note": "`main` is the only reader of `results`, so the count needs no lock. The loop ends when the closer closes the channel."}]}
```

```
ana@vm:~/pool$ (ulimit -n 256; ./pool)
jobs: 1000  workers: 50  failed: 0  took: 1.01s
```

**Under the limit that broke `unbounded.go`, nothing failed.** Fifty files open at a time is far
below 256. The thousand jobs took about a second: twenty rounds of fifty jobs, each 50 milliseconds
long. Section 03 is about how that `50` should be chosen.

The two closing goroutines are the part people get wrong. The producer must close `jobs`, or the
workers wait for more jobs forever. Someone must close `results` after the last worker, or `main`
waits for more results forever. And the one who closes `results` cannot be a worker, because a
worker does not know whether the other forty-nine have finished, which is what `wg.Wait` knows.
