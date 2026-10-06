---
title: Source code mounted, not copied
version: 1
---

**An image is the right thing to ship and the wrong thing to edit.** Rebuilding it for every changed
line costs seconds each time, and lesson 12 made those seconds as few as possible. While writing code,
the faster loop is to leave the source on the machine and mount it into a container that has the
tools, the bind mount of lesson 8.

## A program that restarts itself

A small Node service shows the loop at its shortest. It has no dependencies, so nothing needs
installing:

```javascript
const http = require('node:http');

const greeting = 'hello from the container';

http.createServer((req, res) => {
  res.end(greeting + '\n');
}).listen(3000, () => console.log('listening on 3000'));
```

```
ana@vm:~$ docker run -d --name hello -v "$PWD/hello":/app -w /app -p 127.0.0.1:3000:3000 node:24-alpine node --watch server.js
f9fcef59aa6e2eccde0dcac2d50b9ef69595258fc66d3faffc1acfbda534de90
ana@vm:~$ curl -s localhost:3000
hello from the container
ana@vm:~$ sed -i "s/hello from the container/hello again, no rebuild/" hello/server.js
ana@vm:~$ curl -s localhost:3000
hello again, no rebuild
ana@vm:~$ docker logs hello
listening on 3000
Change detected in '/app/server.js'
Restarting 'server.js'
listening on 3000
```

**The file was edited on the host, and the container served the new text two seconds later, with no
build and no restart.** `node --watch` restarts the program when a file it loaded changes, and the
log says when it did. The image is the stock `node:24-alpine`; Ana's code only ever lived in her own
directory.

## A compiled program, mounted

`shelf` is compiled, so a change needs a new build, but not a new image. A Compose file for
development runs `go run` in the `golang:1.25` image, against the mounted source:

```yaml
services:
  web:
    image: golang:1.25
    working_dir: /src
    command: ["go", "run", "."]
    volumes:
      - .:/src
      - gocache:/root/.cache/go-build
    ports:
      - "127.0.0.1:8080:8080"

volumes:
  gocache:
```

```
ana@vm:~$ cd shelf
ana@vm:~/shelf$ docker compose -f compose.dev.yaml up -d 2>&1 | grep -E "Started|Created"
 Volume shelf_gocache Created 
 Volume shelf_gocache Created 
 Network shelf_default Created 
 Network shelf_default Created 
 Container shelf-web-1 Created 
 Container shelf-web-1 Started 
ana@vm:~/shelf$ curl -s localhost:8080/books | jq length
3
ana@vm:~/shelf$ sed -i "s|{3, \"The Remains of the Day\", \"Kazuo Ishiguro\"},|&\n\t{4, \"Vidas Secas\", \"Graciliano Ramos\"},|" main.go
ana@vm:~/shelf$ docker compose -f compose.dev.yaml restart web 2>&1 | grep Started
 Container shelf-web-1 Started 
ana@vm:~/shelf$ curl -s localhost:8080/books | jq -c ".[3]"
{"id":4,"title":"Vidas Secas","author":"Graciliano Ramos"}
ana@vm:~/shelf$ docker compose -f compose.dev.yaml logs web | tail -2
web-1  | 2026/10/06 20:52:48 catalogue: built in, 4 books
web-1  | 2026/10/06 20:52:48 shelf dev listening on :8080
ana@vm:~/shelf$ docker compose -f compose.dev.yaml down -v 2>&1 | grep -c Removed
3
ana@vm:~/shelf$ git checkout main.go
Updated 1 path from the index
ana@vm:~/shelf$ cd ..
```

The edit adds a fourth book to the built-in list, and a `restart` recompiles and serves it, as
`shelf dev`, the version a build with no `-ldflags` reports. **The named volume `gocache` keeps Go's
build cache between restarts**, so each one compiles only what changed. `git checkout` puts the file
back for the next section.

## A mount hides what the image put there

One way to get this wrong is common enough to show. A development image that builds the program into
the same directory as the source:

```dockerfile
FROM golang:1.25
WORKDIR /src
COPY . .
RUN go build -o shelf .
CMD ["./shelf"]
```

```
ana@vm:~$ cd shelf && docker build -q -f Dockerfile.dev -t shelf:dev . && cd ..
sha256:92f6f8b65bcef610f55a4e30287535f48b18ad11dca813532ed064e4463701de
ana@vm:~$ docker run --rm shelf:dev ls -l /src/shelf
-rwxr-xr-x 1 root root 14806104 Oct  6 20:53 /src/shelf
ana@vm:~$ docker run --rm -v "$PWD/shelf":/src shelf:dev
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "./shelf": stat ./shelf: no such file or directory

Run 'docker run --help' for more information
ana@vm:~$ docker run --rm -v "$PWD/shelf":/src shelf:dev ls /src | head -3
Dockerfile
Dockerfile.dev
compose.dev.yaml
```

**The image has `/src/shelf`; the container started with the mount cannot find it.** A bind mount
replaces the directory it lands on, for as long as the container runs: everything the image had under
`/src` is hidden behind Ana's directory, which has no binary in it. The last command lists what the
container actually sees.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Why ./shelf was not found. On the left, the image shelf:dev: its directory /src holds the source and the compiled binary shelf, built by RUN go build. On the right, Ana&#x27;s directory ~/shelf on the host: the source, with no binary. Mounting ~/shelf on /src lays the host directory over the image&#x27;s; the container sees only the host&#x27;s files, so the binary the image built is hidden, and CMD ./shelf fails.\"><defs><marker id=\"l24hidden-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"260\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">image shelf:dev, /src</text><rect x=\"36\" y=\"76\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main.go</text><rect x=\"36\" y=\"102\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">postgres.go</text><rect x=\"36\" y=\"128\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">vendor/</text><rect x=\"36\" y=\"154\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">shelf</text><text x=\"150\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">binary built by RUN go build</text><rect x=\"440\" y=\"30\" width=\"260\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"456\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">host ~/shelf, mounted on /src</text><rect x=\"456\" y=\"76\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"468\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main.go</text><rect x=\"456\" y=\"102\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"468\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">postgres.go</text><rect x=\"456\" y=\"128\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"468\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">vendor/</text><rect x=\"456\" y=\"154\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"468\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Dockerfile.dev</text><text x=\"570\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">what the container sees: no shelf</text><path d=\"M440 110 L280 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#l24hidden-ah-phosphor)\"></path><text x=\"360\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">laid over</text><text x=\"360\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">exec: \"./shelf\": no such file or directory</text></svg>", "caption": "A mount covers what was there; it does not merge with it. Keep build output outside the directory you mount."}
```

The same thing happens to `node_modules` installed in an image and then covered by a mount of the
project. **Put what the build produces outside the directory you mount**, `/usr/local/bin` or a
volume of its own, or run the tool that builds it inside the container, as `go run` did above.
