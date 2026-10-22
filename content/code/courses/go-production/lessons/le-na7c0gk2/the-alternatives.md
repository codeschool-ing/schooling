---
title: Two other ways to add a reporter
version: 1
---

A plugin solves two problems at once: adding a reporter without touching the host's source, and
adding it without rebuilding the host. Section 03 showed how little the second half is worth: a
plugin has to be rebuilt whenever a shared package changes, from the same source and with the same
toolchain, so host and plugins end up built together anyway. **The two
alternatives each give up one half and keep the other.** A reporter that is a separate program
keeps "without rebuilding the host" and pays for it with a process per call. A reporter compiled
into the binary keeps "without touching the host's source" and pays for it with a rebuild.

## A reporter that is a program

The oldest plugin system on Unix is the pipe. The host starts the reporter as a child process,
writes the summary to its standard input as JSON, and copies whatever it writes to standard output.
**The two programs share no memory and no packages, only an agreement about the bytes.** The mean
reporter, as a program of its own, `exec/mean/main.go`:

```go
// Command mean-exec is the mean-duration reporter as a program of its own.
// It reads one message from standard input and writes its report to
// standard output.
package main

import (
	"encoding/json"
	"fmt"
	"os"

	"example.com/hits/internal/tally"
	"example.com/hits/reporters/mean"
)

type message struct {
	Protocol int           `json:"protocol"`
	Summary  tally.Summary `json:"summary"`
}

func main() {
	var m message
	if err := json.NewDecoder(os.Stdin).Decode(&m); err != nil {
		fmt.Fprintln(os.Stderr, "mean-exec:", err)
		os.Exit(1)
	}
	if m.Protocol != 1 {
		fmt.Fprintf(os.Stderr, "mean-exec: protocol %d, and this reporter speaks 1\n", m.Protocol)
		os.Exit(1)
	}
	if err := (mean.Reporter{}).Report(m.Summary, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "mean-exec:", err)
		os.Exit(1)
	}
}
```

It reuses `reporters/mean` because it is written in Go and lives in the same module, but nothing
requires either. A reporter in Python reads the same message, `exec/top.py`:

```python
#!/usr/bin/env python3
# A reporter in another language: the busiest path, from the same message.
import json, sys

msg = json.load(sys.stdin)
if msg["protocol"] != 1:
    sys.exit(f"top.py: protocol {msg['protocol']}, and this reporter speaks 1")
paths = msg["summary"]["ByPath"]
if not paths:
    print("busiest path: none, the log is empty")
else:
    busiest = min(paths, key=lambda p: (-paths[p], p))
    print(f"busiest path: {busiest} ({paths[busiest]} requests)")
```

And the host that runs them, `cmd/hits-exec/main.go`:

```schooling-example
{
  "language": "go",
  "file": "cmd/hits-exec/main.go",
  "parts": [
    {
      "code": "// Command hits-exec counts a log and hands the summary to reporters that\n// are programs of their own, one process per reporter.\npackage main\n\nimport (\n\t\"bytes\"\n\t\"encoding/json\"\n\t\"fmt\"\n\t\"os\"\n\t\"os/exec\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "No `plugin` import and no cgo: `os/exec` starts programs, and that works on every platform Go builds for."
    },
    {
      "code": "// message is the protocol: one JSON object on the reporter's standard\n// input. A reporter that does not know the number refuses.\ntype message struct {\n\tProtocol int           `json:\"protocol\"`\n\tSummary  tally.Summary `json:\"summary\"`\n}\n",
      "note": "**The protocol is this struct, and the number in it is its version.** A reporter is anything that reads one of these and writes text. When the message has to change, the number goes up, and an old reporter refuses it in words instead of misreading it."
    },
    {
      "code": "func main() {\n\tif len(os.Args) < 3 {\n\t\tfmt.Fprintln(os.Stderr, \"usage: hits-exec <log> <program>...\")\n\t\tos.Exit(2)\n\t}\n\tf, err := os.Open(os.Args[1])\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"hits-exec:\", err)\n\t\tos.Exit(1)\n\t}\n\ts, err := tally.Count(f)\n\tf.Close()\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"hits-exec:\", err)\n\t\tos.Exit(1)\n\t}\n\tin, err := json.Marshal(message{Protocol: 1, Summary: s})\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"hits-exec:\", err)\n\t\tos.Exit(1)\n\t}",
      "note": "The counting is lesson 1's. The summary is encoded once, because every reporter gets the same bytes."
    },
    {
      "code": "\tcode := 0\n\tfor _, program := range os.Args[2:] {\n\t\tcmd := exec.Command(program)\n\t\tcmd.Stdin = bytes.NewReader(in)\n\t\tcmd.Stdout = os.Stdout\n\t\tcmd.Stderr = os.Stderr\n\t\tif err := cmd.Run(); err != nil {\n\t\t\tfmt.Fprintf(os.Stderr, \"hits-exec: %s: %v\\n\", program, err)\n\t\t\tcode = 1\n\t\t}\n\t}\n\tos.Exit(code)\n}",
      "note": "**One process per reporter, started, fed and waited for.** The reporter's standard output and standard error are the host's, so its report lands in the same place a compiled-in reporter's would. A reporter that fails costs its own report and an exit code of 1; the loop goes on to the next."
    }
  ]
}
```

The Python file needs to be executable, since `exec.Command` runs it as a program:

```
ana@vm:~/plugins$ chmod +x exec/top.py
ana@vm:~/plugins$ go build -o mean-exec ./exec/mean && go build -o hits-exec ./cmd/hits-exec
ana@vm:~/plugins$ ./hits-exec access.log ./mean-exec exec/top.py
20000 requests, mean 200ms
busiest path: /login (2576 requests)
```

**Two reporters in two languages, built at different times, and neither was compiled against
`hits-exec`.** `mean-exec` could be rebuilt with Go 1.27.2 or `-race` tomorrow and nothing in
section 03 would happen, because no package is shared at run time. What they share is the message.
The message carries its version, so a mismatch is a sentence instead of a crash deep in the
runtime:

```
ana@vm:~/plugins$ echo '{"protocol":2}' | ./mean-exec; echo $?
mean-exec: protocol 2, and this reporter speaks 1
1
```

## A crash stays outside

`mean` divides by the number of lines and has never been given an empty log. Both hosts get one.
`GOTRACEBACK=none` keeps the panic's first line and drops the goroutine stacks, whose addresses
change on every run; the child process inherits it:

```
ana@vm:~/plugins$ touch empty.log
ana@vm:~/plugins$ GOTRACEBACK=none ./hits-plugin empty.log csv.so mean.so; echo $?
status,requests
panic: runtime error: integer divide by zero
2
ana@vm:~/plugins$ GOTRACEBACK=none ./hits-exec empty.log ./mean-exec exec/top.py; echo $?
panic: runtime error: integer divide by zero
hits-exec: ./mean-exec: exit status 2
busiest path: none, the log is empty
1
```

The same bug, two outcomes. **In `hits-plugin` the panic is a panic of the host.** The CSV reporter
had written its report, which for an empty log is the header alone. Then the whole process died with
exit status 2, and the registry line never came. In `hits-exec` the panic killed `mean-exec`, the
host reported `exit status 2` for that one reporter, ran the Python one, and exited with 1. A
reporter that leaks memory, spins a CPU or calls `os.Exit` is contained the same way, and the
operating system can limit its memory and time in ways it cannot limit a library inside your
process.

**The cost is a process start for every call**, which section 05 measures, and a protocol that is
now a public interface you version by hand. HashiCorp's `go-plugin` library is this design
generalised: it starts each plugin once, keeps it running, and calls it over RPC, so the process
start is paid once instead of per call. Terraform's providers work that way. Another route in the
same family is WebAssembly. A reporter is compiled to a `.wasm` module and run inside the host by a
runtime written in pure Go, such as `wazero`, which needs no cgo and confines the module to the
memory it is given. Neither is used in this course; both answer the question this section asks with
a different price list.

## A reporter compiled in

The third way is the one the standard library uses. `database/sql` knows no database, and
`image.Decode` knows no format: a driver or a codec registers itself from `init`, and a program
chooses which ones it contains by importing them. `import _ "image/png"` is an import for its side
effect only, and the side effect is `image.RegisterFormat("png", …)`. `report` already has the
registry and both reporters already register themselves, so the host is a list of imports.
`cmd/hits-static/main.go`:

```go
// Command hits-static counts a log and writes it out with a reporter
// compiled into the binary, chosen by name.
package main

import (
	"flag"
	"fmt"
	"os"

	"example.com/hits/internal/tally"
	"example.com/hits/report"

	_ "example.com/hits/reporters/csv"
	_ "example.com/hits/reporters/mean"
)

func main() {
	name := flag.String("r", "csv", "the reporter to use")
	flag.Parse()
	r, ok := report.Get(*name)
	if !ok {
		fmt.Fprintf(os.Stderr, "hits-static: no reporter %q; have %v\n", *name, report.Names())
		os.Exit(2)
	}
	s, err := tally.Count(os.Stdin)
	if err == nil {
		err = r.Report(s, os.Stdout)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "hits-static:", err)
		os.Exit(1)
	}
}
```

```
ana@vm:~/plugins$ go build -o hits-static ./cmd/hits-static
ana@vm:~/plugins$ ./hits-static -r mean < access.log
20000 requests, mean 200ms
ana@vm:~/plugins$ ./hits-static < access.log | head -3
status,requests
200,7554
201,1256
ana@vm:~/plugins$ ./hits-static -r xml < access.log; echo $?
hits-static: no reporter "xml"; have [csv mean]
2
```

**The blank imports are the whole plugin system**: the same `init` functions that ran inside
`plugin.Open` in section 02 run here at start-up, from packages the linker put in the binary.
Adding a reporter is one import line and a rebuild. That rebuild is the price, and section 03
showed that plugins charge it too, in a less helpful form. `go doc plugin` ends its list of
warnings with the same advice: if the application and its plugins are built together anyway, it
may be simpler to generate a Go file that blank-imports the chosen plugins and compile one static
executable. A team that wants the list outside the source can generate that file with
`go generate`, the subject of lesson 10.
