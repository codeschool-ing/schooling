---
title: Building for a machine you are not on
version: 1
---

**The Go toolchain can build a binary for any operating system and processor it supports, from any of
them**, with nothing installed beyond Go itself. Two environment variables choose the target: `GOOS`, the
operating system, and `GOARCH`, the processor. Without them, `go build` builds for the machine it runs on:

```
ana@vm:~/boxoffice$ go env GOOS GOARCH; go tool dist list | wc -l
linux
amd64
47
```

Linux on `amd64`, the 64-bit Intel and AMD processors, and 47 pairs the toolchain can build for. Four of
them cover nearly every machine boxoffice could meet: Linux on `amd64` and on `arm64`, the processor of
most cloud servers sold as cheaper, and of the Raspberry Pi; macOS on `arm64`, the Apple chips; and
Windows on `amd64`:

```
ana@vm:~/boxoffice$ for t in linux/amd64 linux/arm64 darwin/arm64 windows/amd64; do GOOS=${t%/*} GOARCH=${t#*/} go build -o dist/try-${t%/*}-${t#*/} . || exit; done; ls -l dist
total 100140
-rwxr-xr-x 1 ana ana 25418370 Oct 22 20:01 try-darwin-arm64
-rwxr-xr-x 1 ana ana 26168752 Oct 22 20:01 try-linux-amd64
-rwxr-xr-x 1 ana ana 24540414 Oct 22 20:01 try-linux-arm64
-rwxr-xr-x 1 ana ana 26407424 Oct 22 20:01 try-windows-amd64
ana@vm:~/boxoffice$ file dist/try-*
dist/try-darwin-arm64:  Mach-O 64-bit arm64 executable, flags:<|DYLDLINK|PIE>
dist/try-linux-amd64:   ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, Go BuildID=dJxaNngpzGzpUm-DDWZl/Qb7CJdNknL3lITZ-g_dF/KGnFNDlvctMs6BtkzrAK/liQSlGq4CaBtIcr7_ECG, BuildID[sha1]=2bdb6128f70bc35840b48c0dba78fb803da39d1b, with debug_info, not stripped
dist/try-linux-arm64:   ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, Go BuildID=JALTTkBmDID4ij3wT60n/wXdH1Pis8-Zir6UrxfDC/G6u52ErfxVV0NTt9Rihn/PdGufm5b-B-pwUDpyLYe, BuildID[sha1]=1645a1a6d6de0958ddf8879f32130a8dc859aa05, with debug_info, not stripped
dist/try-windows-amd64: PE32+ executable (console) x86-64, for MS Windows, 16 sections
```

Four binaries of about 25 MB each, from one machine, in one loop. `file` reads each one's header and agrees
with the name: an ELF executable for each Linux, a Mach-O for macOS, a PE32+ for Windows. Nothing here was
emulated or installed for the other targets; the compiler and the standard library know how to produce
each format.

**Look at the two Linux lines again.** The `arm64` binary is `statically linked`. The `amd64` one, built
for this very machine, is `dynamically linked`, with an interpreter, `/lib64/ld-linux-x86-64.so.2`. The
same code, built two ways, and the difference decides whether the binary will run in the image of
section 06. The next section is why.
