---
title: Where the four megabytes go
version: 1
---

A program that counts the lines of a log comes out of `go build` at four megabytes, and the usual
guess is that Go binaries are simply fat. **Most of that file is not `hits`, and more than a third of
it is not code at all.** There is the runtime and the parts of the standard library the program
reaches, a table the runtime reads to know which function it is in, and information written for
debuggers that the program never looks at while it runs. Each part can be measured, and this section
uses three tools to do it: `size`, `readelf` and `go tool nm`.

This lesson works on `hits` as lesson 1 left it, in a fresh directory, `~/small`: the `tally` package,
`main.go`, `main_test.go` and `genlog`, with `go mod init example.com/hits` and the 20,000-line
`access.log` that `go run ./tools/genlog -n 20000` writes. The first build, and what `file` makes of
it:

```
ana@vm:~/small$ go build -o hits . && stat -c "%s bytes  %n" hits
4031935 bytes  hits
ana@vm:~/small$ file hits | cut -d, -f1,2,7,8
hits: ELF 64-bit LSB executable, x86-64, with debug_info, not stripped
```

**4,031,935 bytes here, against 4,031,903 in lesson 1, from the same source.** A Go binary records
the paths of the files it was compiled from, and `~/small` is not `~/hits`. Lesson 16's native build in
`~/cross`, a directory name of the same length, also came out at 4,031,935. So measure your own
baseline before you compare with any number on this page; section 03 shows the paths and the flag
that takes them out. `cut` kept the two fields of `file` this lesson is about: `with debug_info` and
`not stripped`.

## The sections of an executable

An ELF file, the format Linux runs, is a header followed by named sections. `size -A` lists them with
their length in bytes and the address each is loaded at:

```
ana@vm:~/small$ size -A hits
hits  :
section                 size      addr
.note.go.buildid         100   4198264
.note.gnu.build-id        36   4198364
.text                1227441   4198400
.rodata                85890   5427200
.gopclntab           1049995   5513096
.go.type              213872   6563104
.go.func                1504   6776976
.go.buildinfo            320   6778880
.go.fipsinfo             120   6779200
.go.module               568   6779328
.noptrdata             41634   6779904
.data                  25522   6821568
.bss                  133112   6847104
.noptrbss              87624   6980224
.debug_abbrev            368         0
.debug_line           275035         0
.debug_frame           50663         0
.debug_gdb_scripts        42         0
.debug_info           468388         0
.debug_loclists       238976         0
.debug_rnglists       120986         0
.debug_addr             7849         0
Total                4030045


ana@vm:~/small$ readelf -S -W hits | grep -E "debug_info|symtab|strtab"
  [19] .debug_info       PROGBITS        0000000000000000 2d79dc 0725a4 00   C  0   0  1
  [23] .symtab           SYMTAB          0000000000000000 3a3c48 016c68 18     24 639  8
  [24] .strtab           STRTAB          0000000000000000 3ba8b0 01dbed 00      0   0  1
  [25] .shstrtab         STRTAB          0000000000000000 3d849d 000122 00      0   0  1
```

The list reads in three groups.

**What the program runs.** `.text` is the machine code, 1,227,441 bytes of it: every function of
`hits`, of the runtime and of each standard package the program reaches. `.rodata`, `.data` and
`.noptrdata` hold constants and initialised variables, and `.go.type` holds the 213,872 bytes of type
descriptors that interfaces, `fmt` and `encoding/json` consult at run time. `.bss` and `.noptrbss` are
memory the program starts with zeroed. They have an address and a size and **no bytes in the file**,
which is why the `Total` line is not the file's size.

**What the runtime reads about the program.** `.gopclntab` is 1,049,995 bytes, a quarter of the file.
It maps every instruction address to its function, its source file and its line, and it records how
big each function's stack frame is. The runtime reads it to walk a goroutine's stack: to print a
stack trace, to grow a stack that has run out of room, and to let the garbage collector find the
pointers on it. A Go program cannot run without it.

**What only other programs read.** The eight `.debug_` sections are DWARF, the standard format in
which a compiler tells a debugger about types, variables and lines; they total 1,162,307 bytes. Their
address is 0 because they are never loaded into memory, and the `C` that `readelf -S` prints beside
`.debug_info` means the linker has already compressed them. `.symtab` and `.strtab` do not appear in `size`'s
list at all. `readelf` finds them, with sizes in hexadecimal: `16c68` is 93,288 bytes of symbol table
and `1dbed` is 121,837 bytes of the names it points into. That is the list of names that `nm`, `gdb`
and other tools look up, and the program does not read it either.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 240\" role=\"img\" aria-label=\"Two bars to scale. The default build of hits, 4,031,935 bytes: machine code 1,227,441, the function table .gopclntab 1,049,995, types and data 377,067, the symbol table 215,125, and DWARF debugging information 1,162,307. The build with -s -w, 2,654,368 bytes, keeps the first three parts unchanged and loses the last two, 1,377,567 bytes.\"><rect x=\"131.0\" y=\"50.0\" width=\"165.4\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"213.7\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">machine code</text><text x=\"213.7\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.text</text><text x=\"213.7\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1,227,441</text><rect x=\"298.4\" y=\"50.0\" width=\"141.2\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"369.1\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">function table</text><text x=\"369.1\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.gopclntab</text><text x=\"369.1\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1,049,995</text><rect x=\"441.7\" y=\"50.0\" width=\"49.4\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"493.1\" y=\"50.0\" width=\"27.3\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"522.4\" y=\"50.0\" width=\"156.6\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.7\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">DWARF, for debuggers</text><text x=\"600.7\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">.debug_*</text><text x=\"600.7\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1,162,307</text><text x=\"20.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">default build</text><text x=\"20.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4,031,935</text><path d=\"M466.4 50.0 V30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"466.4\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">types and data  377,067</text><path d=\"M506.8 104.0 V122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"506.8\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">symbol table  215,125</text><rect x=\"131.0\" y=\"165.0\" width=\"165.4\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"213.7\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">machine code</text><text x=\"213.7\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1,227,441</text><rect x=\"298.4\" y=\"165.0\" width=\"141.2\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"369.1\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">function table</text><text x=\"369.1\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1,049,995</text><rect x=\"441.7\" y=\"165.0\" width=\"49.4\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"493.1\" y=\"165.0\" width=\"185.9\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"586.1\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">removed by -s</text><text x=\"586.1\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,377,567 bytes</text><text x=\"20.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">-s -w</text><text x=\"20.0\" y=\"201.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2,654,368</text></svg>", "caption": "The default build of hits by part, to scale, from size -A and readelf -S. The flag -s takes the last two parts, which the program never reads; the function table stays, because the runtime does read it."}
```

## Whose code it is

`go tool nm` reads the symbol table, one line per symbol: its address, its size with `-size`, a letter
for its kind, and its name. `T` is code, `D` initialised data, `B` zeroed data and `R` read-only data,
with lower case for what `go doc cmd/nm` calls a static symbol, one the linker keeps local. Here is how many
there are, the eight largest, and the ten functions `hits` itself contributed:

```
ana@vm:~/small$ go tool nm hits | wc -l
3886
ana@vm:~/small$ go tool nm -size -sort size hits | sed -n 1,8p
  60fb08     201376 r go:func.*
  691560      93464 B runtime.mheap_
  6ac880      69632 B runtime.cgroupScratch
  68d6a0      16064 B runtime.semtable
  4a91a0      11688 T time.parse
  67eb20      11136 D internal/strconv.pow10Tab
  6a9fa0      10440 B runtime.memstats
  4f7ea0      10399 T encoding/json/v2.parseFieldOptions
ana@vm:~/small$ go tool nm -size hits | grep -E " T (main|example.com/hits)"
  528ec0        901 T example.com/hits/internal/tally.Count
  528ac0       1005 T example.com/hits/internal/tally.Parse
  529260        568 T example.com/hits/internal/tally.Top
  52b8e0       1079 T main.count
  52c5e0        347 T main.encode
  52c520        165 T main.flush
  52b5a0        138 T main.main
  52b640        671 T main.run
  52c160        941 T main.summarise
  52bd20       1083 T main.top
```

**3,886 symbols, and `hits` wrote ten of them.** The largest, `go:func.*`, sits at an address inside
`.gopclntab`: it is 201,376 bytes of that table's per-function data. The largest piece of code is
`time.parse`, at 11,688 bytes, which is what `tally.Parse` calls for every line. The loop below adds up
the code, `T` and `t`, whose names begin with each prefix:

```
ana@vm:~/small$ for p in runtime encoding/json time fmt example.com/hits main.; do go tool nm -size hits | awk -v p=$p '$3 ~ /^[Tt]$/ && index($4, p) == 1 { s += $2 } END { print s, p }'; done
438417 runtime
265797 encoding/json
68117 time
40012 fmt
2703 example.com/hits
4468 main.
```

**The runtime is 438,417 bytes of code, and the `tally` package and `main` together are 7,171**: a
little over half a per cent of `.text`. The second biggest thing in the binary is `encoding/json`, at
265,797 bytes, and the symbols show that in Go 1.27 it brings `encoding/json/v2` and
`encoding/json/jsontext` with it. That is the price of the two `-json` flags. Section 05 builds a
program that does nothing but encode one string, to see what the import costs on its own.

## Two tables that name functions

The two tables that hold names are easily confused, and the difference decides what can be removed.
**The ELF symbol table is for tools outside the program**; the linker writes it, `nm` and debuggers
read it from the file, and the running program never opens it. **`.gopclntab` is for the runtime**,
inside the program, and a panic names its functions by reading it. Removing the first, and the DWARF
beside it, therefore costs the debugger and costs nothing at run time. No flag removes the second,
and section 03 shows a stripped binary still naming every function in a stack trace.
