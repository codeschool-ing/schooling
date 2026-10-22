---
title: What a program is given
version: 1
---

A program started from a terminal does not receive the line you typed. **The shell reads the line
first, splits it into words, and hands the program a list.** Quotes decide where one word ends,
`$NAME` is replaced before anything starts, and a `*` becomes the file names it matches. By the time
`main` runs, all of that has happened, and the list is in `os.Args`.

The flag package reads that list, takes the words that look like settings, and leaves the rest.
`go-concurrency` lesson 21 introduced it on a single program. This section looks at the boundary it
draws, because a command-line tool lives on that boundary: which words are flags, which are the
tool's own arguments, and what happens to a word that is neither. A program that prints both sides,
in `~/args`, `main.go`:

```go
// Command args prints what it was given, before and after the flag package
// has read it.
package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	fmt.Printf("os.Args:   %q\n", os.Args)
	verbose := flag.Bool("v", false, "say more")
	n := flag.Int("n", 1, "how many")
	flag.Parse()
	fmt.Printf("flags:     -v=%t -n=%d\n", *verbose, *n)
	fmt.Printf("flag.Args: %q\n", flag.Args())
}
```

Built once, and given a few lines that differ in one way each:

```
ana@vm:~/args$ go build -o args .
ana@vm:~/args$ ./args -v -n 3 jan.log feb.log
os.Args:   ["./args" "-v" "-n" "3" "jan.log" "feb.log"]
flags:     -v=true -n=3
flag.Args: ["jan.log" "feb.log"]
ana@vm:~/args$ ./args -n=3 "two words" feb.log
os.Args:   ["./args" "-n=3" "two words" "feb.log"]
flags:     -v=false -n=3
flag.Args: ["two words" "feb.log"]
```

`os.Args[0]` is the program as it was invoked, and the words follow in order. **`flag.Args` is what is
left once the flags are taken out**, and it is the part a tool treats as its input: file names,
usually. `-n 3` and `-n=3` mean the same thing. The quotes in the second line never reach the
program; they told the shell that `two words` is one word, and the program got it as one.

## Where the flags stop

The flag package reads flags from the front of the list and **stops at the first word that is not
one**. Everything after that word is an argument, even a word that looks like a flag:

```
ana@vm:~/args$ ./args --n 3 jan.log -v
os.Args:   ["./args" "--n" "3" "jan.log" "-v"]
flags:     -v=false -n=3
flag.Args: ["jan.log" "-v"]
ana@vm:~/args$ ./args -- -v
os.Args:   ["./args" "--" "-v"]
flags:     -v=false -n=1
flag.Args: ["-v"]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The line ./args --n 3 jan.log -v becomes five words in os.Args. The flag package reads --n and 3 as the flag -n with value 3, and stops at jan.log, the first word that is not a flag, so jan.log and -v are left in flag.Args and -v stays false.\"><text x=\"360\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what Ana typed</text><text x=\"360\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">$ ./args --n 3 jan.log -v</text><text x=\"40\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what the shell hands the program</text><rect x=\"95\" y=\"112\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"./args\"</text><text x=\"150.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os.Args[0]</text><rect x=\"225\" y=\"112\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"--n\"</text><text x=\"265.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os.Args[1]</text><rect x=\"325\" y=\"112\" width=\"60\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"3\"</text><text x=\"355.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os.Args[2]</text><rect x=\"405\" y=\"112\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"jan.log\"</text><text x=\"465.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os.Args[3]</text><rect x=\"545\" y=\"112\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">\"-v\"</text><text x=\"585.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os.Args[4]</text><path d=\"M395 92 V250\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" fill=\"none\"></path><text x=\"403\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the first word that is not a flag: parsing stops here</text><path d=\"M225 178 V186 H385 V178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"305\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">read as flags</text><text x=\"305\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">-n=3   -v=false</text><path d=\"M405 178 V186 H625 V178\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"515\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">left for the program</text><text x=\"515\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">flag.Args() = [\"jan.log\" \"-v\"]</text><path d=\"M95 178 V186 H205 V178\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"150\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the program itself</text></svg>", "caption": "The shell makes the list; the flag package reads flags from the front and stops at the first word that is not one."}
```

Two things show in the first line. `--n` worked: Go accepts one dash or two for the same flag, and
neither is a "long form". And `-v` after `jan.log` was not read as a flag. That surprises people
who learnt the GNU tools, where `ls dir -l` works, and it is the first difference lesson 2 removes
when the same program moves to Cobra. The bare `--` in the second line is the standard way to say
"no flags from here on", for an argument that really does start with a dash.

## What a wrong flag costs

A value that does not parse, and a request for help, both end the program before `main` gets past
`flag.Parse`:

```
ana@vm:~/args$ ./args -n three; echo $?
os.Args:   ["./args" "-n" "three"]
invalid value "three" for flag -n: parse error
Usage of ./args:
  -n int
    	how many (default 1)
  -v	say more
2
ana@vm:~/args$ ./args -h; echo $?
os.Args:   ["./args" "-h"]
Usage of ./args:
  -n int
    	how many (default 1)
  -v	say more
0
```

**The package prints the problem and a usage listing, then exits with status 2**, the conventional
code for "you called me wrongly". Asked for help, it prints the same listing and exits 0, because
nothing went wrong. The listing is built from the help texts given to `flag.Int` and `flag.Bool`,
with the default shown when it is not the zero value. That is the behaviour of the package-level
functions; section 04 builds a tool where each subcommand has a set of flags of its own and decides
for itself what a failed parse means.

## A log to read

The tool this lesson builds, `hits`, reads a web server's access log. Rather than hand you a file,
the course gives you a program that writes one, so you and Ana count the same lines. It lives in a
new module in `~/hits`, made with `go mod init example.com/hits`, in its own directory under
`tools/`:

```schooling-example
{
  "language": "go",
  "file": "tools/genlog/main.go",
  "parts": [
    {
      "code": "// Command genlog writes a made-up web server access log: the same lines\n// every time for the same flags.\npackage main\n\nimport (\n\t\"bufio\"\n\t\"flag\"\n\t\"fmt\"\n\t\"math/rand/v2\"\n\t\"os\"\n\t\"time\"\n)\n",
      "note": "A program in a directory of its own under `tools/`, in the same module as `hits`. `go run ./tools/genlog` runs it, and it never ships with the tool."
    },
    {
      "code": "var (\n\tmethods  = []string{\"GET\", \"GET\", \"GET\", \"POST\"}\n\tpaths    = []string{\"/\", \"/login\", \"/api/orders\", \"/api/orders/42\", \"/api/users\", \"/static/app.js\", \"/static/app.css\", \"/health\"}\n\tstatuses = []int{200, 200, 200, 200, 200, 200, 201, 204, 301, 304, 400, 401, 404, 404, 500, 503}\n)\n",
      "note": "What a line can contain. **A value listed twice is drawn twice as often**: three `GET`s against one `POST`, and six `200`s among sixteen statuses, so the log looks like a busy site rather than a uniform one."
    },
    {
      "code": "func main() {\n\tn := flag.Int(\"n\", 1000, \"how many lines to write\")\n\tseed := flag.Uint64(\"seed\", 1, \"the seed: the same seed writes the same log\")\n\tflag.Parse()\n",
      "note": "Two flags, read the way `go-concurrency` lesson 21 read them: each call returns a pointer, and `flag.Parse` fills it from the command line. The third argument of each is the help text `-h` prints."
    },
    {
      "code": "\tr := rand.New(rand.NewPCG(*seed, *seed))\n\tw := bufio.NewWriter(os.Stdout)\n\tdefer w.Flush()\n",
      "note": "**A generator built from a seed draws the same numbers every run.** That is what makes the log reproducible: the counts this lesson prints are the counts you will get."
    },
    {
      "code": "\tt := time.Date(2026, 10, 1, 9, 0, 0, 0, time.UTC)\n\tfor range *n {\n\t\tt = t.Add(time.Duration(r.IntN(2000)) * time.Millisecond)\n\t\tfmt.Fprintf(w, \"%s %s %s %d %dms\\n\",\n\t\t\tt.Format(time.RFC3339),\n\t\t\tmethods[r.IntN(len(methods))],\n\t\t\tpaths[r.IntN(len(paths))],\n\t\t\tstatuses[r.IntN(len(statuses))],\n\t\t\t1+r.IntN(400))\n\t}\n}",
      "note": "Each line moves the clock on by up to two seconds and writes five fields separated by spaces. The buffered writer collects them and `defer w.Flush()` writes the rest out when `main` returns."
    }
  ]
}
```


Run with a handful of lines, and then with another seed:

```
ana@vm:~/hits$ cat go.mod
module example.com/hits

go 1.27.1
ana@vm:~/hits$ go run ./tools/genlog -n 5
2026-10-01T09:00:01Z POST /api/users 404 115ms
2026-10-01T09:00:03Z GET /static/app.js 200 119ms
2026-10-01T09:00:04Z GET /health 500 3ms
2026-10-01T09:00:06Z GET /api/orders 201 101ms
2026-10-01T09:00:06Z GET /login 500 141ms
ana@vm:~/hits$ go run ./tools/genlog -n 3 -seed 7
2026-10-01T09:00:01Z GET /api/orders/42 503 95ms
2026-10-01T09:00:02Z GET /api/orders 503 226ms
2026-10-01T09:00:03Z GET /api/orders/42 304 281ms
ana@vm:~/hits$ go run ./tools/genlog -n 20000 > access.log; wc -l access.log
20000 access.log
```

Each line is a time in UTC, a method, a path, a status code and how long the request took. Your
first five lines should be exactly these, and **if they are not, your `genlog` differs from the one
above**; every count in this lesson depends on the same 20,000 lines in `access.log`.
