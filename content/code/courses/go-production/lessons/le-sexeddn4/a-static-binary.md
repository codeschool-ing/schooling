---
title: A binary that needs nothing
version: 1
---

"A Go binary is always static" is half true, and the half that is false is the one that breaks an
image. **A binary is static when nothing in it asks for the C library**, and whether anything asks
depends on the packages it imports and on whether cgo is on. `hits` happens to need nothing. A
program that looks up who is running it can need a great deal, without a line of C in it.

This lesson works in `~/ship`, with the four files of `hits` placed there from lesson 1, `go mod
init example.com/hits` and the same `access.log` of 20,000 lines from `genlog -n 20000`.

## hits needs nothing

Built the plain way, with cgo on because this machine has `gcc`:

```
ana@vm:~/ship$ go build -o hits . && file hits | cut -d, -f1,4
hits: ELF 64-bit LSB executable, statically linked
ana@vm:~/ship$ ldd hits
	not a dynamic executable
ana@vm:~/ship$ go list -deps . | grep -x runtime/cgo; echo $?
1
```

**`statically linked` means the file holds every instruction it will run**, and `ldd`, which lists
the shared libraries a program will load, finds nothing to list. `go list -deps` prints every
package the build compiles, and `runtime/cgo`, the package a binary needs to call C, is not among
them: `grep` found nothing and said so with 1. Nothing `tally` and `main.go` import has a C
implementation, so `CGO_ENABLED=1` had nothing to switch on.

## A program that does need something

`probe` is a second small program, with no connection to `hits`, that asks three questions whose
answers live in files outside the program. It is a module of its own in `~/ship/probe`, made with
`go mod init example.com/probe`. Save it as `probe/main.go`:

```schooling-example
{
  "language": "go",
  "file": "probe/main.go",
  "parts": [
    {
      "code": "// Command probe asks three questions that a Go program answers from files\n// the system provides: who is running it, what time it is in Sao Paulo,\n// and which certificate authorities it trusts.\npackage main\n\nimport (\n\t\"crypto/x509\"\n\t\"fmt\"\n\t\"os/user\"\n\t\"time\"\n)\n",
      "note": "Standard library only. **Each question is answered by reading a file the program does not carry**, which makes the program a test of whatever system it lands on."
    },
    {
      "code": "func main() {\n\tif u, err := user.Current(); err != nil {\n\t\tfmt.Println(\"user: \", err)\n\t} else {\n\t\tfmt.Println(\"user: \", u.Username, u.Uid, u.HomeDir)\n\t}\n",
      "note": "`user.Current` has the two implementations lesson 16 showed for `os/user`. With cgo it asks the C library; without it, it reads `/etc/passwd` itself."
    },
    {
      "code": "\tif loc, err := time.LoadLocation(\"America/Sao_Paulo\"); err != nil {\n\t\tfmt.Println(\"zone: \", err)\n\t} else {\n\t\tnoon := time.Date(2026, 10, 1, 12, 0, 0, 0, time.UTC)\n\t\tfmt.Println(\"zone: \", noon.In(loc).Format(\"15:04 MST\"))\n\t}\n",
      "note": "`time.LoadLocation` reads the zone's rules from `/usr/share/zoneinfo`. A fixed instant, noon UTC on 1 October 2026, makes the answer the same on every run."
    },
    {
      "code": "\t// On Linux the pool holds the system's roots, so Subjects counts them.\n\t// It is deprecated because that is not true on every system.\n\tif pool, err := x509.SystemCertPool(); err != nil {\n\t\tfmt.Println(\"certs:\", err)\n\t} else {\n\t\tfmt.Println(\"certs:\", len(pool.Subjects()), \"authorities\")\n\t}\n}",
      "note": "`x509.SystemCertPool` loads the authorities a TLS client trusts, from `/etc/ssl/certs/ca-certificates.crt` on Ubuntu. Without them, a client has nothing to check a server's certificate against."
    }
  ]
}
```

Built the same way as `hits`:

```
ana@vm:~/ship/probe$ go build -o probe . && file probe | cut -d, -f1,4
probe: ELF 64-bit LSB executable, dynamically linked
ana@vm:~/ship/probe$ ldd probe | cut -d" " -f1
	linux-vdso.so.1
	libc.so.6
	/lib64/ld-linux-x86-64.so.2
ana@vm:~/ship/probe$ go list -deps . | grep -x runtime/cgo
runtime/cgo
ana@vm:~/ship/probe$ ./probe
user:  ana 30033 /home/ana
zone:  09:00 -03
certs: 127 authorities
```

**`os/user` pulled in cgo, and cgo made the binary depend on two files of this machine.**
`libc.so.6` is the C library, and `/lib64/ld-linux-x86-64.so.2` is the dynamic loader, the program
the kernel starts first so that it can find `libc.so.6` and join it to `probe` before `main` runs.
`linux-vdso.so.1` is supplied by the kernel itself and is not a file anywhere. The three answers are
correct: Ana's account, São Paulo three hours behind UTC, and 127 authorities in Ubuntu's bundle.

The same source with cgo turned off:

```
ana@vm:~/ship/probe$ CGO_ENABLED=0 go build -o probe . && file probe | cut -d, -f1,4
probe: ELF 64-bit LSB executable, statically linked
ana@vm:~/ship/probe$ ldd probe; ./probe
	not a dynamic executable
user:  ana 30033 /home/ana
zone:  09:00 -03
certs: 127 authorities
```

Static again, and the same three answers, because `os/user` fell back to reading `/etc/passwd`
itself. **`CGO_ENABLED=0` removed the dependency on the C library and on the loader; it did not
remove the dependency on `/etc/passwd`, `/usr/share/zoneinfo` or the certificate bundle.** Those are
data, and a static binary reads data from the machine like any other program. Section 04 puts
`probe` in two images and watches which of those files are there.

## Why a container wants the static one

A container image carries its own files and nothing of the machine it runs on. The image section 03
builds has no C library and no loader in it, so a dynamically linked binary inside it asks the
kernel for `/lib64/ld-linux-x86-64.so.2` and the kernel finds no such file. Section 04 shows the
message, and it names the wrong file. **A static binary has no such question to ask**, which is why
every release build in this lesson starts with `CGO_ENABLED=0`, as lesson 16's `release.sh` already
did for every target.

The release build of `hits` adds the two flags lesson 17 took apart:

```
ana@vm:~/ship$ CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o hits . && stat -c "%s bytes  %n" hits
2650272 bytes  hits
ana@vm:~/ship$ file hits | cut -d, -f1,4; ./hits top -n 1 access.log
hits: ELF 64-bit LSB executable, statically linked
path    requests
/login  2576
```

**2,650,272 bytes, against the 4,031,903 of lesson 1's plain build**, and the same answer to the
same question. `-s -w` leave out the symbol table and the debugging information. `-trimpath`
replaces the directories of this machine, `/home/ana/ship` among them, with module paths inside the
binary, which is what makes section 05's comparison of two builds possible. This is the file the
image ships.
