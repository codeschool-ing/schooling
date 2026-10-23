---
title: Beyond the linker
version: 1
---

The linker flags took a third off the file, and what is left is almost all code and the table that
describes it. **Three more levers are on offer, and only one of them changes what is in the program.**
A compressor squeezes the finished file, a compiler flag trades speed for bytes, and the imports
decide how much of the standard library and of other people's modules is in the program to begin
with. Each is measured here on the release build of section 04, which is 2,666,656 bytes.

## Compressing the file with UPX

UPX, the Ultimate Packer for eXecutables, rewrites an executable as a small decompressor followed by
the original program, compressed. Ubuntu's archive has it as `upx-ucl` (`sudo apt install upx-ucl`),
and it was installed that way here:

```
ana@vm:~/small$ upx --version | head -1
upx 4.2.2
ana@vm:~/small$ upx --best -q -o hits-upx hits
                       Ultimate Packer for eXecutables
                          Copyright (C) 1996 - 2024
UPX 4.2.2       Markus Oberhumer, Laszlo Molnar & John Reiser    Jan 3rd 2024

        File size         Ratio      Format      Name
   --------------------   ------   -----------   -----------
   2666656 ->   1140620   42.77%   linux/amd64   hits-upx

Packed 1 file.
ana@vm:~/small$ stat -c "%s bytes  %n" hits hits-upx
2666656 bytes  hits
1140620 bytes  hits-upx
ana@vm:~/small$ ./hits-upx top -n 2 access.log
path         requests
/login       2576
/api/orders  2542
ana@vm:~/small$ go version -m hits-upx; echo $?
hits-upx: could not read Go build info from hits-upx: not a Go executable
1
```

**1,140,620 bytes, 42.77% of the original, and the program still counts.** `go version -m` can no
longer read it, and neither can any other tool that reads a Go binary's build information, because
that information is now inside the compressed part. The cost that matters is paid on every start, when
the decompressor rebuilds the program in memory before running it. A hundred starts of `hits version`,
which does almost nothing else:

```
ana@vm:~/small$ time (for i in $(seq 100); do ./hits version > /dev/null; done)

real	0m0.270s
user	0m0.116s
sys	0m0.047s
ana@vm:~/small$ time (for i in $(seq 100); do ./hits-upx version > /dev/null; done)

real	0m2.182s
user	0m1.591s
sys	0m0.187s
```

**0.270 seconds against 2.182, under 3 milliseconds per start against 22.** The figures move from run
to run, and the ratio, about eight times, is the part to keep. A person typing a command will not
notice 19 milliseconds; a script that calls `hits` for each of ten thousand files will.

The other half of the comparison is that a file is rarely sent anywhere uncompressed. A release is
downloaded as an archive, and `gzip`, the compressor in every `.tar.gz`, does nearly as well on the
plain binary:

```
ana@vm:~/small$ gzip -9 -c hits | wc -c; gzip -9 -c hits-upx | wc -c
1171128
1118110
```

**`gzip -9` brings the plain binary to 1,171,128 bytes**, 30,508 more than UPX, and the user unpacks it
once instead of on every start. A UPX file barely compresses further, because compressed bytes look
random. UPX pays where the binary is stored and run uncompressed and its size on disk is the
constraint, which is rarer than it sounds; for a tool somebody downloads, the archive already did most
of its work.

## Compiler flags

`-gcflags` passes flags to the compiler, `go tool compile`, the way `-ldflags` passes them to the
linker. With a bare flag it applies only to the packages named on the command line; with `all=` in
front, to every package in the build, the standard library included. Two compiler flags change the
size, in opposite directions:

```
ana@vm:~/small$ go build -trimpath -gcflags=all=-l -ldflags="-s -w" -o hits-noinline . && stat -c "%s bytes  %n" hits hits-noinline
2666656 bytes  hits
2543776 bytes  hits-noinline
ana@vm:~/small$ go build -o hits-default . && go build -gcflags="all=-N -l" -o hits-debug . && stat -c "%s bytes  %n" hits-default hits-debug
4055138 bytes  hits-default
4190697 bytes  hits-debug
```

**`-l` turns inlining off and saved 122,880 bytes, 4.6%.** Inlining copies a small function's body
into each place that calls it, which costs bytes and saves a call. Here is what turning it off did to
the time `hits` takes over a million lines:

```
ana@vm:~/small$ go run ./tools/genlog -n 1000000 > big.log; wc -l big.log
1000000 big.log
ana@vm:~/small$ time ./hits count big.log > /dev/null

real	0m0.324s
user	0m0.287s
sys	0m0.048s
ana@vm:~/small$ time ./hits-noinline count big.log > /dev/null

real	0m0.431s
user	0m0.375s
sys	0m0.049s
```

**0.324 seconds with inlining and 0.431 without, a third slower**, for a file 4.6% smaller. That
is a bad trade for nearly every program. `-N -l`, which also turns the optimiser off, made the binary
135,559 bytes *larger* than the default build. It is the pair to use when a debugger has to step
through code exactly as it was written, and never the pair to ship.

## What the program imports

**Every package a program imports is in the binary, along with everything that package imports.** The
linker leaves out functions nothing calls, but it cannot leave out what the program uses. To see the
cost of an import on its own, here are three programs that print `hello` and do nothing else, in a
directory of their own, `~/sizes`, with `go mod init example.com/sizes`. The first writes to standard
output directly, `none/main.go`:

```go
package main

import "os"

func main() {
	os.Stdout.WriteString("hello\n")
}
```

The second uses `fmt`, `fmtonly/main.go`:

```go
package main

import "fmt"

func main() {
	fmt.Println("hello")
}
```

The third encodes the word as JSON, `withjson/main.go`:

```go
package main

import (
	"encoding/json"
	"os"
)

func main() {
	json.NewEncoder(os.Stdout).Encode("hello")
}
```

Each is built with `-s -w`, measured, and asked how many packages it depends on with `go list -deps`,
which prints one package per line:

```
ana@vm:~/sizes$ for p in none fmtonly withjson; do go build -ldflags="-s -w" -o $p.bin ./$p; done
ana@vm:~/sizes$ stat -c "%s bytes  %n" none.bin fmtonly.bin withjson.bin
1310880 bytes  none.bin
1511584 bytes  fmtonly.bin
2568352 bytes  withjson.bin
ana@vm:~/sizes$ for p in none fmtonly withjson; do echo "$(go list -deps ./$p | wc -l) $p"; done
54 none
60 fmtonly
75 withjson
```

| program | bytes, `-s -w` | packages |
|---|---|---|
| `none` | 1,310,880 | 54 |
| `fmtonly` | 1,511,584 | 60 |
| `withjson` | 2,568,352 | 75 |

**1,310,880 bytes is the floor**: the runtime and the packages it needs, with one line of program on
top. `fmt` adds 200,704 bytes and six packages. `encoding/json` adds 1,257,472 bytes over the floor,
and a program that encodes one string comes to 97% of the 2,650,272 bytes of section 03's smallest
`hits`. Section 02 found the same package as the second largest block of code in `hits`, and this is
its price measured alone.

**The imports are the lever that moves megabytes.** Lessons 2 and 3 rebuilt `hits` on Cobra and on
urfave/cli, and each version came out more than a megabyte larger than lesson 1's, for the same two
subcommands. That can be a fair price for completion and generated help, and it is a price that no
linker flag will refund. `go list -deps` answers what a dependency brings before anything is built;
whether `-json` is worth a megabyte to `hits` is a question about its users, and the measurement is
what makes it a question at all.
