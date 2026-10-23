---
title: Go
version: 1
---

**Go was made at Google for servers and the tools around them**, and much of the infrastructure this
course's later tracks use is written in it: Docker, Kubernetes, Terraform. It compiles to one file
that runs with nothing else installed. It installs the way Node did in lesson 1, from a tarball on
its own site:

```sh
# Ubuntu and WSL: the tarball from go.dev, unpacked beside Node
curl -fsSLO https://go.dev/dl/go1.27.3.linux-amd64.tar.gz
mkdir -p ~/.local/go
tar -xzf go1.27.3.linux-amd64.tar.gz -C ~/.local/go --strip-components=1
ln -s ~/.local/go/bin/go ~/.local/bin/
brew install go                   # a Mac, with Homebrew
```

**Neither block was run for this course as written**: the course's machine could not reach go.dev,
and its Go 1.27.3 was unpacked from the same release served by Go's module proxy, into the same
folder. Ubuntu's own `golang-go` package works too, and is two years older. From there:

```
ana@dev:~/server/other/go$ go version
go version go1.27.3 linux/amd64
ana@dev:~/server/other/go$ go mod init hello
go: creating new go.mod: module hello
go: to add module requirements and sums:
	go mod tidy
```

`go mod init` is `npm init`: it writes `go.mod`, the file that names the module and, later, its
dependencies.

```schooling-example
{"language": "go", "file": "main.go", "parts": [
 {"code": "// main.go: the same server in Go, with nothing but the standard library.\npackage main\n\nimport (\n\t\"encoding/json\"\n\t\"log\"\n\t\"net/http\"\n\t\"os\"\n\t\"time\"\n)", "note": "**Every file belongs to a package, and a program starts in `main`.** The imports are all from the standard library, which has a production-grade HTTP server and JSON."},
 {"code": "func send(w http.ResponseWriter, status int, body any) {\n\tw.Header().Set(\"content-type\", \"application/json\")\n\tw.WriteHeader(status)\n\tjson.NewEncoder(w).Encode(body)\n}", "note": "**Types are written out**, after the name: `status int`. `any` is any type, which is how a map and a struct can both be sent."},
 {"code": "func main() {\n\tmux := http.NewServeMux()\n\tmux.HandleFunc(\"GET /hello\", func(w http.ResponseWriter, r *http.Request) {\n\t\tname := r.URL.Query().Get(\"name\")\n\t\tif name == \"\" {\n\t\t\tname = \"world\"\n\t\t}\n\t\tsend(w, http.StatusOK, map[string]string{\"hello\": name})\n\t})", "note": "**`\"GET /hello\"` is a method and a path in one pattern**, which Go's router has understood since 1.22. A missing query parameter is an empty string, not `undefined`."},
 {"code": "\tmux.HandleFunc(\"GET /slow\", func(w http.ResponseWriter, r *http.Request) {\n\t\ttime.Sleep(time.Second)\n\t\tsend(w, http.StatusOK, map[string]int{\"slept\": 1000})\n\t})\n\tmux.HandleFunc(\"/\", func(w http.ResponseWriter, r *http.Request) {\n\t\tsend(w, http.StatusNotFound, map[string]string{\"error\": \"nothing at \" + r.URL.Path})\n\t})", "note": "**`time.Sleep` blocks only this request**: Go runs each request in a *goroutine*, a thread so cheap that a server keeps one per connection."},
 {"code": "\tport := os.Getenv(\"PORT\")\n\tif port == \"\" {\n\t\tport = \"3000\"\n\t}\n\tlog.Println(\"go on :\" + port)\n\tlog.Fatal(http.ListenAndServe(\"127.0.0.1:\"+port, mux))\n}", "note": "**Errors are values, returned**, not thrown. `ListenAndServe` returns one only when it stops, and `log.Fatal` prints it and exits."}
]}
```

`go run .` compiles and runs it in one step:

```
ana@dev:~/server/other/go$ go run .
2026/10/22 20:11:22 go on :3000
signal: interrupt
^C
```

```
ana@dev:~/server/other/go$ curl -s 'http://127.0.0.1:3000/hello?name=ana'
{"hello":"ana"}

ana@dev:~/server/other/go$ curl -s -w ' %{http_code}\n' http://127.0.0.1:3000/nope
{"error":"nothing at /nope"}
 404
ana@dev:~/server/other/go$ time (for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/slow & done; wait)
200 200 200 200 200 200 200 200 200 200 
real	0m1.017s
user	0m0.020s
sys	0m0.036s
```

**The same answers.** `Encode` ends its JSON with a newline, which is why there is an empty line after
each one here. **Ten slow requests took one second**, each in its own goroutine.

## One file to deploy

```
ana@dev:~/server/other/go$ go build -o hello && ls -lh hello && file hello
-rwxr-xr-x 1 ana ana 9.4M Oct 22 20:11 hello
hello: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, Go BuildID=zke-3B9ap-ii_kGjHfvU/jY9QNojl_GW3-QZp088R/VnXH9NUs25NBglEMaOZN/Z98McU8tWfx86XqjRrR8, BuildID[sha1]=f948754fb3b2ac3c37346f35e7343c09c4fd9bb7, with debug_info, not stripped
```

**`go build` made one executable of about nine megabytes** with the runtime and the standard library
inside it. Copied to another Linux machine of the same processor type, it runs with no Go, no
`node_modules` and no runtime of a particular version installed. `file` says it is *dynamically
linked*: it uses the system's C library, which every Linux has, to look up host names, and
`CGO_ENABLED=0 go build` makes one that needs not even that. That is the property Go is most often
chosen for, and the reason so many command-line tools are written in it.

| what | in Node terms |
|---|---|
| the standard library's `net/http` | `node:http`, but used in production as it is |
| `chi`, `gin`, `echo`, when a router is not enough | Express |
| `go.mod` and `go.sum` | `package.json` and `package-lock.json` |
| `go get` | `npm install` |
| `go test` | `node --test` |
