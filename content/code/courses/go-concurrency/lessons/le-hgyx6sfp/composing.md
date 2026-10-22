---
title: Composing them
version: 1
---

Because every source is a Reader and every destination a Writer, the standard library can offer
small pieces that take one and return another, and a program builds what it needs by plugging
them together. **It is the shell's pipe, `cat file | gzip | sha256sum`, done with values instead
of processes.** The pieces in `io` worth knowing by name:

| function | takes | gives | what it does |
|---|---|---|---|
| `io.Copy(dst, src)` | a Writer and a Reader | bytes copied, error | moves everything from `src` to `dst` until `EOF` |
| `io.ReadAll(r)` | a Reader | `[]byte`, error | reads to the end into memory |
| `io.LimitReader(r, n)` | a Reader | a Reader | stops after `n` bytes |
| `io.MultiReader(rs...)` | Readers | a Reader | one after another, as if concatenated |
| `io.TeeReader(r, w)` | a Reader and a Writer | a Reader | whatever is read from it is also written to `w` |
| `io.MultiWriter(ws...)` | Writers | a Writer | every write goes to all of them |
| `io.Pipe()` | nothing | a Reader and a Writer | what one goroutine writes, another reads |

`io.Pipe` is where the two halves of this course meet. It has no buffer: a `Write` blocks until a
`Read` takes the bytes, exactly like the unbuffered channel of lesson 4, so the writer and the
reader have to be different goroutines.

## Four pieces in one program

The program below has a goroutine write three lines into a pipe. The other end is read through a
`TeeReader` that feeds a hash, and copied into a `MultiWriter` that feeds both the terminal and a
`strings.Builder`. Saved as `pipe.go`:

```schooling-example
{"language": "go", "file": "pipe.go", "parts": [{"code": "// Command pipe connects a goroutine that writes to code that reads.\npackage main\n\nimport (\n\t\"crypto/sha256\"\n\t\"fmt\"\n\t\"io\"\n\t\"os\"\n\t\"strings\"\n)\n\n", "note": "Nothing outside the standard library, and nothing that touches a disk."}, {"code": "func main() {\n\tpr, pw := io.Pipe()\n\tgo func() {\n\t\tfor i := 1; i <= 3; i++ {\n\t\t\tfmt.Fprintf(pw, \"line %d from the writer\\n\", i)\n\t\t}\n\t\tpw.Close()\n\t}()\n\n", "note": "**The writing end goes to a goroutine of its own.** Each `Fprintf` blocks until the reading side takes its bytes. `pw.Close()` is what the reader will see as `EOF`; forget it and `io.Copy` waits for ever, which is lesson 6's leak in a new shape."}, {"code": "\th := sha256.New()\n\tvar kept strings.Builder\n\tn, err := io.Copy(io.MultiWriter(os.Stdout, &kept), io.TeeReader(pr, h))\n", "note": "**One line of plumbing.** `io.Copy` reads from the tee, the tee hands each chunk to the hash on its way past, and the multi-writer sends each chunk to the terminal and to `kept`. Nothing here is told what any other piece is."}, {"code": "\tfmt.Println(\"copied\", n, \"bytes, err\", err)\n\tfmt.Printf(\"sha256 %x\\n\", h.Sum(nil))\n\tfmt.Print(strings.ToUpper(kept.String()))\n}\n", "note": "Three ways to show that every byte went everywhere: the count `io.Copy` returns, the hash, and the copy kept in memory, printed again in capitals."}], "output": "line 1 from the writer\nline 2 from the writer\nline 3 from the writer\ncopied 69 bytes, err <nil>\nsha256 dd142e8966cd4c3cad296af10a08470b0aa8cb054285239b78f1d238d8b60946\nLINE 1 FROM THE WRITER\nLINE 2 FROM THE WRITER\nLINE 3 FROM THE WRITER"}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"How pipe.go is plumbed. A goroutine writes three lines into pw, the writing end of io.Pipe. main reads from pr, the reading end, through io.TeeReader, which also writes every chunk into the sha256 hash. io.Copy moves the chunks into io.MultiWriter, which writes each one to os.Stdout and to a strings.Builder called kept.\"><defs><marker id=\"l17pipe-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17pipe-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"70\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a goroutine</text><rect x=\"20\" y=\"48\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Fprintf(pw)</text><path d=\"M122 65 H150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17pipe-amber)\"></path><rect x=\"152\" y=\"48\" width=\"110\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"207.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">io.Pipe</text><text x=\"207\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">each write waits for a read</text><path d=\"M264 65 H292\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17pipe-phosphor)\"></path><rect x=\"294\" y=\"48\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">io.TeeReader</text><path d=\"M359 84 V138\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17pipe-phosphor)\"></path><rect x=\"304\" y=\"140\" width=\"110\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sha256</text><path d=\"M426 65 H454\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17pipe-phosphor)\"></path><rect x=\"456\" y=\"48\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"516.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">io.MultiWriter</text><text x=\"516\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">main, inside io.Copy</text><path d=\"M578 58 H606\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17pipe-phosphor)\"></path><path d=\"M578 74 C592 74 592 157 606 157\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17pipe-phosphor)\"></path><rect x=\"608\" y=\"41\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"654.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">os.Stdout</text><rect x=\"608\" y=\"140\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"654.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kept</text><text x=\"152\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pw</text><text x=\"262\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pr</text><path d=\"M152 108 V114\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M262 108 V114\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "Every chunk read from the pipe is written twice by the tee and the multi-writer, and lands in three places: the hash, the terminal and kept."}
```

The run, then the same three lines given to the shell's `sha256sum` for comparison, and the
program again under the race detector:

```
ana@vm:~/rw$ go run pipe.go
line 1 from the writer
line 2 from the writer
line 3 from the writer
copied 69 bytes, err <nil>
sha256 dd142e8966cd4c3cad296af10a08470b0aa8cb054285239b78f1d238d8b60946
LINE 1 FROM THE WRITER
LINE 2 FROM THE WRITER
LINE 3 FROM THE WRITER
ana@vm:~/rw$ printf "line %d from the writer\n" 1 2 3 | sha256sum
dd142e8966cd4c3cad296af10a08470b0aa8cb054285239b78f1d238d8b60946  -
ana@vm:~/rw$ go run -race pipe.go > /dev/null; echo "exit: $?"
exit: 0
```

**69 bytes went through, the hashes agree, and the detector is silent**, because the pipe itself
synchronises the two goroutines: each byte the reader sees was handed over, not shared. `err` is
`<nil>` although the data ended, for the same reason `io.ReadAll` reported none in section 02:
`io.Copy` treats `EOF` as the finish line, not as a failure.

## Why it matters past this lesson

Almost every type in the rest of this half plugs into the same two interfaces. A file from
`os.Open` is a Reader and a Writer (lesson 18). `json.NewDecoder` takes a Reader and
`json.NewEncoder` a Writer (lesson 19). A log handler writes to a Writer (lesson 22). An HTTP
response body is a Reader and a handler writes its answer to a Writer (lesson 28). **Write your
functions against `io.Reader` and `io.Writer` rather than against a file or a string**, and they
work on all of these, and in a test on a `strings.Reader` and a `bytes.Buffer`, with no change.
