---
title: Results out of order
version: 1
---

Fan-out takes jobs in order and finishes them in whatever order the work allows. **A result that
travels back on a channel arrives in the order the work finished, not in the order it was
started**, and a program that prints or stores results as they arrive has quietly given up the
input's order.

The program below measures four words in parallel; a longer word takes longer to measure. Each
goroutine sends its result back on one channel, and `main` prints them as they come. It is saved in
`~/fanout/arrival` as `arrival.go`:

```go
// Command arrival measures four words in parallel and prints the results as they arrive.
package main

import (
	"fmt"
	"time"
)

type result struct {
	index int
	word  string
	size  int
}

// measure stands for slow work whose time depends on its input.
func measure(word string) int {
	time.Sleep(time.Duration(len(word)) * 10 * time.Millisecond)
	return len(word)
}

func main() {
	words := []string{"concurrency", "is", "not", "parallelism"}
	results := make(chan result)
	for i, w := range words {
		go func() { results <- result{i, w, measure(w)} }()
	}
	for range words {
		r := <-results
		fmt.Println(r.index, r.word, r.size)
	}
}
```

```
ana@vm:~/fanout$ go run ./arrival
1 is 2
2 not 3
0 concurrency 11
3 parallelism 11
```

The input was `concurrency is not parallelism`. The output starts with `is`, the shortest word and
the quickest job, and the two long words come last. Nothing went wrong: the order of arrival is the
order of finishing.

## Two ways to get the order back

The result carries its `index`, and that is the first fix: whoever receives the results can put
each one where it belongs, in a slice of the right length or by sorting afterwards. Carrying the
index costs one field and keeps the channel, which matters when results feed a further stage, as in
lesson 15.

The second fix needs no channel at all. **Each goroutine writes its answer into its own element of
a slice made in advance**, and `main` reads the slice once every goroutine is done. It is saved in
`~/fanout/inplace` as `inplace.go`:

```go
// Command inplace measures four words in parallel and keeps the input's order.
package main

import (
	"fmt"
	"sync"
	"time"
)

func measure(word string) int {
	time.Sleep(time.Duration(len(word)) * 10 * time.Millisecond)
	return len(word)
}

func main() {
	words := []string{"concurrency", "is", "not", "parallelism"}
	sizes := make([]int, len(words))
	var wg sync.WaitGroup
	for i, w := range words {
		wg.Go(func() { sizes[i] = measure(w) })
	}
	wg.Wait()
	for i, w := range words {
		fmt.Println(i, w, sizes[i])
	}
}
```

```
ana@vm:~/fanout$ go run -race ./inplace
0 concurrency 11
1 is 2
2 not 3
3 parallelism 11
```

The input's order, and the race detector, running throughout, reported nothing. Four goroutines
wrote into one slice at the same time and that was not a race, because **each element of a slice
is a separate variable**: `sizes[0]` and `sizes[3]` are different memory, and lesson 1's definition
of a race needs two goroutines touching the same memory. What makes it safe is the discipline that
each goroutine writes only its own index, and that `main` reads only after `wg.Wait`, whose promise
from lesson 1 makes every write visible.

The same discipline does not stretch to `append`. Appending to a shared slice from several
goroutines reads and writes its length, which is shared, and that is a race lesson 16 shows. Size
the slice first and write by index, or send the results on a channel.
