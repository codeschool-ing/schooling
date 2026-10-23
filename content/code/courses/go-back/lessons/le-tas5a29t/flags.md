---
title: The flag package
version: 1
---

The standard library parses command lines with `flag`. A small program shows all of it; it is not part of
boxoffice and lives in `~/knobs`:

```go
// knobs/main.go
package main

import (
	"flag"
	"fmt"
	"os"
	"time"
)

func main() {
	addr := flag.String("addr", "localhost:8080", "`address` to listen on")
	conns := flag.Int("max-conns", 10, "most database connections open at once")
	wait := flag.Duration("wait", 0, "how long to keep running before exiting")
	verbose := flag.Bool("v", false, "say more")
	flag.Parse()

	fmt.Println("addr:", *addr, "max-conns:", *conns, "verbose:", *verbose)
	fmt.Println("arguments left:", flag.Args())

	region, set := os.LookupEnv("BOXOFFICE_REGION")
	fmt.Printf("BOXOFFICE_REGION: %q, set: %v\n", region, set)
	time.Sleep(*wait)
}
```

Each `flag.String`, `flag.Int`, `flag.Duration` and `flag.Bool` declares a flag with a name, a default and
a line of help, and returns a pointer that `flag.Parse` fills in. The word between backquotes in the help,
`` `address` ``, is what the help shows as the kind of value the flag takes.

```
ana@vm:~/knobs$ go build -o knobs . && ./knobs
addr: localhost:8080 max-conns: 10 verbose: false
arguments left: []
BOXOFFICE_REGION: "", set: false
ana@vm:~/knobs$ ./knobs -addr :9000 -max-conns=20 -v
addr: :9000 max-conns: 20 verbose: true
arguments left: []
BOXOFFICE_REGION: "", set: false
```

Run with nothing, every value is its default. `-addr :9000` and `-max-conns=20` are the two ways to give a
value, and a bool flag on its own means true.

## When the command line is wrong

```
ana@vm:~/knobs$ ./knobs -max-conns ten; echo "exit $?"
invalid value "ten" for flag -max-conns: parse error
Usage of ./knobs:
  -addr address
    	address to listen on (default "localhost:8080")
  -max-conns int
    	most database connections open at once (default 10)
  -v	say more
  -wait duration
    	how long to keep running before exiting
exit 2
ana@vm:~/knobs$ ./knobs -h; echo "exit $?"
Usage of ./knobs:
  -addr address
    	address to listen on (default "localhost:8080")
  -max-conns int
    	most database connections open at once (default 10)
  -v	say more
  -wait duration
    	how long to keep running before exiting
exit 0
```

A value that does not parse stops the program with the reason, the full help and **exit status 2**, the
conventional status for "you used this wrong". `-h`, or `-help`, prints the same help and exits with 0,
because asking for help is not an error. The program wrote none of this itself; `flag.Parse` did, from the
declarations, defaults included.

## Three things that surprise people

```
ana@vm:~/knobs$ ./knobs report.csv -v
addr: localhost:8080 max-conns: 10 verbose: false
arguments left: [report.csv -v]
BOXOFFICE_REGION: "", set: false
```

**Parsing stops at the first argument that is not a flag.** `report.csv` is not a flag, so `-v` after it is
not read as one either; both land in `flag.Args()`. Put flags first.

```
ana@vm:~/knobs$ ./knobs -v false -addr :9000
addr: localhost:8080 max-conns: 10 verbose: true
arguments left: [false -addr :9000]
BOXOFFICE_REGION: "", set: false
```

**A bool flag takes a value only with `=`.** `-v false` sets `-v` to true and leaves `false` as an argument,
and since `false` is not a flag, parsing stops there and `-addr` is never read. The address is still the
default, and nothing complained.

```
ana@vm:~/knobs$ ./knobs --addr=:9000 -v=false
addr: :9000 max-conns: 10 verbose: false
arguments left: []
BOXOFFICE_REGION: "", set: false
```

**Two dashes work the same as one.** `--addr=:9000` and `-addr=:9000` are the same flag. What the package
does not do is combine short flags the way GNU tools do, `-xvf` meaning three flags; it reads that as one
flag named `xvf`. Programs that want that style use a library: `spf13/pflag` keeps `flag`'s API with GNU
rules, and `spf13/cobra`, built on it, adds subcommands, as in `kubectl get pods`. For a server with a
handful of settings, `flag` is enough.

## Not the global set

`flag.String` and `flag.Parse` use one set of flags shared by the whole program, which reads `os.Args`.
That is fine for `knobs` and awkward for a server: a test cannot hand it arguments without changing
`os.Args`, and any package that declares a flag in `init` adds it to your program's help. **`flag.NewFlagSet`
makes a set of your own**, parsed from a slice you pass in. Section 07 uses one for boxoffice.
