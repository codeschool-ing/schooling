---
title: RE2, and the time it promises
version: 1
---

Most languages' regular expressions are backtracking engines: they try one way of matching, and
when it fails they go back and try the next. That buys features, and it has a price that only
shows on the wrong input. **Go's `regexp` is RE2: it runs in time proportional to the length of the
text, whatever the pattern, and refuses the features that would break that promise.**

Two of those features are references back to an earlier group and lookahead. Saved as
`nope/main.go`:

```go
// Command nope asks for two things RE2 does not do.
package main

import (
	"fmt"
	"regexp"
)

func main() {
	for _, expr := range []string{`(\w+) \1`, `\d+(?= ms)`} {
		_, err := regexp.Compile(expr)
		fmt.Println(err)
	}
}
```

```
ana@vm:~/patterns$ go run ./nope
error parsing regexp: invalid escape sequence: `\1`
error parsing regexp: invalid or unsupported Perl syntax: `(?=`
```

`\1`, "the same text the first group matched", and `(?=`, "followed by, without consuming", are
both refused when the pattern is compiled, with a message saying which. **A pattern copied from
another language can fail here for exactly this reason**, and the fix is to do that part in Go: find
the candidates with the expression, and compare the two words with `==`.

## The input that makes a backtracking engine stop

`^(a+)+$` on a run of `a`s followed by a `b` cannot match, and a backtracking engine proves it by
trying every way of splitting the `a`s between the inner and the outer `+`. There are about two to
the power of n of those. The same pattern and inputs, timed in Go, saved as `evil/main.go`:

```go
// Command evil times a pattern that makes backtracking engines give up.
package main

import (
	"fmt"
	"regexp"
	"strings"
	"time"
)

func main() {
	re := regexp.MustCompile(`^(a+)+$`)
	for _, n := range []int{20, 22, 24, 26, 1000} {
		s := strings.Repeat("a", n) + "b"
		start := time.Now()
		ok := re.MatchString(s)
		fmt.Printf("n=%d match=%v %v\n", n, ok, time.Since(start).Round(time.Microsecond))
	}
}
```

And in Python, whose `re` module is a backtracking engine, as `evil.py`:

```python
# evil.py: the same pattern and the same inputs, through Python's re module.
import re, time

pattern = re.compile(r"^(a+)+$")
for n in (20, 22, 24, 26):
    s = "a" * n + "b"
    start = time.perf_counter()
    ok = pattern.match(s) is not None
    print(f"n={n} match={ok} {time.perf_counter() - start:.2f}s")
```

```
ana@vm:~/patterns$ go run ./evil
n=20 match=false 45µs
n=22 match=false 2µs
n=24 match=false 1µs
n=26 match=false 1µs
n=1000 match=false 39µs
ana@vm:~/patterns$ python3 --version
Python 3.13.16
ana@vm:~/patterns$ python3 evil.py
n=20 match=False 0.03s
n=22 match=False 0.13s
n=24 match=False 0.52s
n=26 match=False 2.07s
```

**Python's time quadrupled with every two more `a`s**: 0.03 seconds at 20, over two seconds at 26,
and a few more characters would have taken minutes. Go answered in microseconds at 26 and at 1,000;
its first line includes the time to set the matcher up. This is the shape of a real failure, often
called ReDoS: a pattern in a web form's validation, and one request with a long, nearly-matching
value, takes a server's processor for as long as the engine keeps trying. With RE2 the worst case
is the length of the input, so the defence is the engine itself.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Time to fail to match ^(a+)+$ against n a&#x27;s and a b. Python&#x27;s re takes 0.03, 0.13, 0.52 and 2.07 seconds at n equal to 20, 22, 24 and 26, each bar four times the last. Go&#x27;s regexp takes a few microseconds at every n, too small to draw at this scale.\"><rect x=\"160\" y=\"227.2\" width=\"56\" height=\"2.8\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"188\" y=\"217.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.03 s</text><path d=\"M222 230 H252\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><text x=\"188\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><rect x=\"290\" y=\"218.1\" width=\"56\" height=\"11.9\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"318\" y=\"208.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.13 s</text><path d=\"M352 230 H382\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><text x=\"318\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22</text><rect x=\"420\" y=\"182.3\" width=\"56\" height=\"47.7\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"448\" y=\"172.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.52 s</text><path d=\"M482 230 H512\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><text x=\"448\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><rect x=\"550\" y=\"40.0\" width=\"56\" height=\"190.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"578\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2.07 s</text><path d=\"M612 230 H642\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><text x=\"578\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">26</text><path d=\"M140 230 H690\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"415\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">n, the number of a&#x27;s</text><rect x=\"30\" y=\"30\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"50\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Python re, backtracking</text><path d=\"M30 60 H44\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><text x=\"50\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Go regexp, RE2: microseconds, a line on the axis</text></svg>", "caption": "evil/main.go and evil.py on the same machine: each two more characters multiply Python's time by four and leave Go's where it was."}
```

That does not make every pattern cheap. A long input still costs its length, and a program reading
untrusted text should still limit how much it reads, with `io.LimitReader` for instance.
