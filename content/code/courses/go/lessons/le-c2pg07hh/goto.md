---
title: goto, and the two jumps it refuses
version: 1
---

`goto` is one of the 25 keywords lesson 1 counted. It takes a label like the ones in section 03
and jumps to it from anywhere in the same function. This program, in `~/flow-goto`, is a loop with no `for` in
it:

```go
package main

import "fmt"

func main() {
	i := 0
again:
	fmt.Println("turn", i)
	i++
	if i < 3 {
		goto again
	}
	fmt.Println("after", i, "turns")
}
```

```
ana@vm:~/flow-goto$ go run .
turn 0
turn 1
turn 2
after 3 turns
```

It is also exactly what nobody should write. **Every loop made of `goto` is a `for` that does not
say it is one.** `for i := 0; i < 3; i++` puts the start, the condition and the step on one line
and the body between braces, and a reader sees the shape before reading a statement of it. Here,
the reader has to find the label, find every `goto` that names it, and work out from the
conditions around them that the whole thing is a loop. Section 02's `break` and `continue`, the
labels of section 03 and an early `return` cover nearly every jump a Go program needs, and each
of them says where it goes by where it is written.

## The two jumps the compiler refuses

The risk in any jump is landing where a variable exists but its declaration never ran. Go refuses
both ways of getting there:

```go
package main

import "fmt"

func main() {
	n := len("hello")
	if n > 3 {
		goto done
	}
	msg := "short"
	fmt.Println(msg)
done:
	fmt.Println("finished")

	goto inside
	if n > 0 {
	inside:
		fmt.Println("inside the if")
	}
}
```

```
ana@vm:~/flow-jump$ go build
# example.com/jump
./main.go:8:8: goto done jumps over declaration of msg at ./main.go:10:6
./main.go:15:7: goto inside jumps into block starting at ./main.go:16:11
```

**A `goto` may not skip a declaration whose variable is still in scope at the label.** `msg` is
declared on line 10 and its scope runs to the end of `main`, so at `done:` the name `msg` would
exist without its declaration ever having run. The message names the variable and the line.
Declaring `msg` above the `goto` with `var msg string`, and only assigning it below, satisfies the
rule, because then nothing new comes into scope at the label.

**And a `goto` may not jump into a block from outside it.** The `if` body is a block of its own,
lesson 6's innermost scope, and entering it at `inside:` would skip the condition that guards it.
Jumping out of a block is allowed: the loop at the top of this section does it from inside its
`if`, and `break` does it all the time.

## Where it is still used

Go's own source has a few places where a `goto` is the clearest thing available, and the
standard library of the lab's Go 1.27.1 is in `/usr/local/go/src` to look at. The densest is the
code that runs in a new process between `fork` and `exec` on Linux:

```
ana@vm:~/flow-goto$ grep -c 'goto childerror' /usr/local/go/src/syscall/exec_linux.go
37
ana@vm:~/flow-goto$ sed -n '228,232p' /usr/local/go/src/syscall/exec_linux.go
	// vfork requires that the child not touch any of the parent's
	// active stack frames. Hence, the child does all post-fork
	// processing in this stack frame and never returns, while the
	// parent returns immediately from this frame and does all
	// post-fork processing in the outer frame.
ana@vm:~/flow-goto$ sed -n '678,683p' /usr/local/go/src/syscall/exec_linux.go
childerror:
	// send error code on pipe
	RawSyscall(SYS_WRITE, uintptr(pipe), uintptr(unsafe.Pointer(&err1)), unsafe.Sizeof(err1))
	for {
		RawSyscall(SYS_EXIT, 253, 0, 0)
	}
```

Thirty-seven lines in one function jump to the same label. The comment says why the ordinary way
out is closed: the child process **never returns** from this function, so each failure cannot
`return err` the way lesson 32 shows. Instead each one jumps to `childerror:`, which writes the
error code to a pipe for the parent and ends the process. One exit, shared by every
failure, in a function that may not return: that is the shape `goto` still fits.

How rare it is, counted over the same source tree with tests left out:

```
ana@vm:~/flow-goto$ grep -rE --include=*.go '^\s*goto\b' /usr/local/go/src | grep -vc -e _test.go -e testdata
572
ana@vm:~/flow-goto$ grep -rE --include=*.go '^\s*break\b' /usr/local/go/src | grep -vc -e _test.go -e testdata
22416
```

572 lines start with `goto` and 22,416 start with `break`, roughly one `goto` for every forty. You
will read `goto` in other people's code now and then, in places like this one. **Write one only when `break`, `continue`, a label and `return` have all been
tried and each made the function harder to read.**
