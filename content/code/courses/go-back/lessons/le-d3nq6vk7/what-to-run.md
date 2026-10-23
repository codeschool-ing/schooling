---
title: What to run, and when
version: 1
---

All of it, with the database variable set and the cache off:

```
ana@vm:~/boxoffice$ time go test -count=1 ./...
ok  	example.com/boxoffice	0.238s
?   	example.com/boxoffice/cmd/seats	[no test files]
?   	example.com/boxoffice/cmd/sizes	[no test files]
?   	example.com/boxoffice/cmd/watchws	[no test files]
?   	example.com/boxoffice/internal/db	[no test files]
?   	example.com/boxoffice/internal/seatspb	[no test files]

real	0m0.902s
user	0m0.686s
sys	0m0.387s
```

The packages with `[no test files]` are the generated code and the small clients in `cmd/`, which is
fine; what `?` means is that nobody claims otherwise. The same run with the race detector:

```
ana@vm:~/boxoffice$ time go test -race -count=1 ./...
ok  	example.com/boxoffice	1.285s
?   	example.com/boxoffice/cmd/seats	[no test files]
?   	example.com/boxoffice/cmd/sizes	[no test files]
?   	example.com/boxoffice/cmd/watchws	[no test files]
?   	example.com/boxoffice/internal/db	[no test files]
?   	example.com/boxoffice/internal/seatspb	[no test files]

real	0m2.117s
user	0m0.907s
sys	0m0.398s
```

**About twice the time, here, and still about two seconds.** Instrumenting every memory access costs CPU
and memory, typically several times more of each, and for a test suite this size the price is nothing. The
detector is not for production binaries, where that cost would be paid on every request; it is for tests,
and for running a staging build under real load now and then.

## Three habits

| when | what | why |
|---|---|---|
| on every save | `go test -run 'TestBuyTickets' .` for the part you are changing | milliseconds, and the cache makes the rest free |
| before every commit | `go vet ./...` and `go test -race ./...` | the whole suite with races checked, still seconds |
| in CI, on every push | `go test -race -count=1 ./...` with `BOXOFFICE_TEST_DATABASE_URL` set | no cache, no skipped database, on a machine that is not yours |

CI needs a PostgreSQL to point the variable at. Every CI service can start one beside the job, and a job
that cannot is a job where section 07's tests skip and say `ok`. A step that fails when the variable is
empty is the cheap guard against that.

## Coverage

```
ana@vm:~/boxoffice$ go test -count=1 -cover .
ok  	example.com/boxoffice	0.323s	coverage: 60.6% of statements
ana@vm:~/boxoffice$ go test -count=1 -coverprofile=cover.out . && go tool cover -func=cover.out | grep -w "0.0%"
ok  	example.com/boxoffice	0.231s	coverage: 60.6% of statements
example.com/boxoffice/config.go:31:	LogValue	0.0%
example.com/boxoffice/config.go:32:	String		0.0%
example.com/boxoffice/config.go:110:	LogValue	0.0%
example.com/boxoffice/grpc.go:29:	toStatus	0.0%
example.com/boxoffice/grpc.go:41:	GetEvent	0.0%
example.com/boxoffice/grpc.go:49:	Watch		0.0%
example.com/boxoffice/grpc.go:73:	Scan		0.0%
example.com/boxoffice/grpc.go:96:	logCalls	0.0%
example.com/boxoffice/grpc.go:103:	newGRPCServer	0.0%
example.com/boxoffice/main.go:19:	main		0.0%
example.com/boxoffice/middleware.go:43:	Unwrap		0.0%
example.com/boxoffice/pgstore.go:37:	List		0.0%
example.com/boxoffice/pgstore.go:49:	Get		0.0%
example.com/boxoffice/tickets.go:10:	HasTicket	0.0%
```

**Sixty per cent of boxoffice's statements ran during the tests.** go-concurrency's lesson 30 said what
that number does not tell you: a line that ran was not necessarily checked, and a line that did not run may
not matter. Read it the other way round, as a list of what no test has touched. A profile records which
statements ran, and `go tool cover -func` lists it per function; these are the functions no test entered
at all:

```
ana@vm:~/boxoffice$ go test -count=1 -coverprofile=cover.out . && go tool cover -func=cover.out | grep -w "0.0%"
ok  	example.com/boxoffice	0.231s	coverage: 60.6% of statements
example.com/boxoffice/config.go:31:	LogValue	0.0%
example.com/boxoffice/config.go:32:	String		0.0%
example.com/boxoffice/config.go:110:	LogValue	0.0%
example.com/boxoffice/grpc.go:29:	toStatus	0.0%
example.com/boxoffice/grpc.go:41:	GetEvent	0.0%
example.com/boxoffice/grpc.go:49:	Watch		0.0%
example.com/boxoffice/grpc.go:73:	Scan		0.0%
example.com/boxoffice/grpc.go:96:	logCalls	0.0%
example.com/boxoffice/grpc.go:103:	newGRPCServer	0.0%
example.com/boxoffice/main.go:19:	main		0.0%
example.com/boxoffice/middleware.go:43:	Unwrap		0.0%
example.com/boxoffice/pgstore.go:37:	List		0.0%
example.com/boxoffice/pgstore.go:49:	Get		0.0%
example.com/boxoffice/tickets.go:10:	HasTicket	0.0%
```

`main` runs every time the server starts, and lesson 17's health check exercises it from outside.
`pgStore`'s `List` and `Get` and `HasTicket` are each one query that section 07 could call in a line. Two
entries are promises nobody checks: the `LogValue` and `String` methods of lesson 14 that hide secrets, and
`Unwrap`, which lesson 13's streams depend on and no test opens a stream to reach. **The gRPC server of
lesson 10 is the real gap**, six functions and a whole second API with no test at all;
`google.golang.org/grpc/test/bufconn` serves gRPC over an in-memory connection, which makes it a test the
size of section 04's. `go tool cover -html=cover.out` shows the same profile as the source, every statement
coloured by whether it ran.

**Raise the number by testing promises, never by testing lines**: a test written to cover a line asserts
nothing anybody needed.
