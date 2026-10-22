---
title: Not fooling yourself
version: 1
---

A benchmark is easy to write and easy to make lie. The three ways below each produce a clean,
confident number that is not the number you wanted. **The first is the compiler, the second is the
setup, the third is the machine.**

## The compiler removed the work

The compiler deletes code whose result nobody uses. In an ordinary program that is a gift; in a
benchmark it can delete the very thing being measured. A throwaway file shows it with a function
that adds up a thousand squares, timed in the old `b.N` style and with `b.Loop`, saved as
`sum_test.go`:

```go
package wordcount

import "testing"

func sumTo(n int) int {
	s := 0
	for i := range n {
		s += i * i
	}
	return s
}

func BenchmarkSumN(b *testing.B) {
	for i := 0; i < b.N; i++ {
		sumTo(1000)
	}
}

func BenchmarkSumLoop(b *testing.B) {
	for b.Loop() {
		sumTo(1000)
	}
}
```

```
ana@vm:~/wordcount$ go test -run '^$' -bench Sum -count 3
goos: linux
goarch: amd64
pkg: example.com/wordcount
cpu: Intel(R) Xeon(R) Processor
BenchmarkSumN-4      	 7396468	       148.5 ns/op
BenchmarkSumN-4      	 7991452	       152.2 ns/op
BenchmarkSumN-4      	 8008995	       152.2 ns/op
BenchmarkSumLoop-4   	 4154817	       279.4 ns/op
BenchmarkSumLoop-4   	 4203289	       284.9 ns/op
BenchmarkSumLoop-4   	 4162086	       287.5 ns/op
PASS
ok  	example.com/wordcount	7.606s
```

**The same function, the same argument, and the `b.N` version is much faster.** It is not faster
at adding squares; it is not adding them. The compiler inlined `sumTo` into the loop, saw that the
result was thrown away, and removed the arithmetic. `go test -c` builds the test binary without
running it, and `go tool objdump` shows the machine code of one function:

```
ana@vm:~/wordcount$ go test -c -o wc.test && go tool objdump -s 'BenchmarkSumN$' wc.test
TEXT example.com/wordcount.BenchmarkSumN(SB) /home/ana/wordcount/sum_test.go
  sum_test.go:14	0x772420		31c9			XORL CX, CX		
  sum_test.go:14	0x772422		eb03			JMP 0x772427		
  sum_test.go:14	0x772424		48ffc1			INCQ CX			
  sum_test.go:14	0x772427		48398810020000		CMPQ 0x210(AX), CX	
  sum_test.go:14	0x77242e		7e1b			JLE 0x77244b		
  sum_test.go:15	0x772430		90			NOPL			
  sum_test.go:7		0x772431		31d2			XORL DX, DX		
  sum_test.go:7		0x772433		eb0b			JMP 0x772440		
  sum_test.go:7		0x772435		48ffc2			INCQ DX			
  sum_test.go:7		0x772438		0f1f840000000000	NOPL 0(AX)(AX*1)	
  sum_test.go:7		0x772440		4881fae8030000		CMPQ DX, $0x3e8		
  sum_test.go:7		0x772447		7cec			JL 0x772435		
  sum_test.go:7		0x772449		ebd9			JMP 0x772424		
  sum_test.go:17	0x77244b		c3			RET			
ana@vm:~/wordcount$ rm sum_test.go wc.test
```

Read the lines tagged `sum_test.go:7`, the body of `sumTo`'s loop: an increment, a comparison with
1000 (`$0x3e8`) and a jump back. There is no multiplication and no addition into `s` anywhere. What
the benchmark timed was a loop counting to a thousand. **`b.Loop` keeps the calls inside it and
their results alive**, which is the main reason it replaced the `b.N` loop. With older code, the
remedy is to store the result somewhere the compiler cannot prove unused, such as a package-level
variable.

## The setup was timed

Anything inside the timed loop is measured, including work that is not the subject. Building
`sample` inside `BenchmarkCount`'s loop would have measured `strings.Repeat` as well as `Count`.
With `b.Loop`, setup before the loop is excluded on its own. In the `b.N` style it is not: the
timer runs from the start of the function, and the setup has to be followed by `b.ResetTimer()`.
Setup that has to happen for every round, such as a fresh copy of something the code modifies,
belongs in the loop and is then part of the number, which is honest as long as you know it is
there.

## The machine was busy

The lab machine runs other work, and so does your laptop: a browser tab, an indexer, an update.
Section 03's five runs of an unchanged program spread by almost three percent, and a single run
before them was slower by more than ten, which is ordinary. Three
habits keep that from deciding anything:

1. **Compare runs made one after the other, on the same machine**, never a number today against a
   number written down last month.
2. **Run each side several times with `-count`** and look at the spread before the averages.
3. **Prefer the allocation columns when they tell the story**, because they do not move with load.

For comparing many runs statistically, the Go project publishes `benchstat`, in the module
`golang.org/x/perf`. It is a separate download rather than part of the toolchain, so this course
reads the runs by eye; it is the first thing to install when the differences you care about are
smaller than the spread.

A benchmark says how long; it does not say where. When the number is bad, `go test -bench` also
takes `-cpuprofile` and `-memprofile`, which record where the time and the allocations went.
