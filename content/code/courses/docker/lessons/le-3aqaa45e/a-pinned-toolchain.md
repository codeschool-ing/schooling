---
title: The same Go everywhere
version: 1
---

**"It passes on my machine" is the testing version of lesson 1's problem.** The tests ran against
whatever compiler, libraries and tools that machine had, and the pipeline has others. Running the
tests in the same image everywhere removes the difference, and Ana's machine, which has no Go at all,
shows it cleanly:

```
ana@vm:~/shelf$ docker run --rm -v "$PWD":/src -w /src golang:1.25 go version
go version go1.25.14 linux/amd64
ana@vm:~/shelf$ docker run --rm -v "$PWD":/src -w /src golang:1.25 go test ./...
ok  	example.com/shelf	0.005s
?   	example.com/shelf/probe	[no test files]
ana@vm:~/shelf$ docker run --rm -v "$PWD":/src -w /src golang:1.25 go test -race -count=1 ./...
ok  	example.com/shelf	1.019s
?   	example.com/shelf/probe	[no test files]
```

**`golang:1.25` brings Go 1.25.14, and that is the Go every run uses**, on Ana's machine, a
colleague's and the pipeline's, until somebody changes the tag. The source is mounted, as in lesson
24, so nothing is built into an image. `-race` turns on Go's race detector, which needs a C toolchain
the `golang` image already has; on a laptop it is one more thing to install, and here it is not.

`-count=1` stops Go from reusing a cached result, which matters when a test talks to something
outside the program, as the integration test later in this lesson does.
