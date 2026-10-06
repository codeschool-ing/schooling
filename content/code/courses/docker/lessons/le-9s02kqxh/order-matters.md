---
title: Order matters
version: 1
---

**Put what changes rarely at the top of the Dockerfile and what changes often at the bottom.**
Dependencies change once a month; source code changes every few minutes. A Dockerfile that copies
everything in one step makes every edit pay for the dependencies again.

## The price of `COPY . .` first

Ana changes one log message in `main.go` and rebuilds:

```
ana@vm:~/shelf$ sed -i "s/listening on/serving on/" main.go
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:dev . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#6 [2/4] WORKDIR /src
#6 CACHED
#7 [3/4] COPY . .
#7 DONE 0.2s
#8 [4/4] RUN go build -o /usr/local/bin/shelf .
#8 DONE 14.4s

real	0m20.272s
user	0m0.152s
sys	0m0.106s
```

**20 seconds.** `COPY . .` saw a changed file, so it ran again, and `go build` under it ran again
from scratch: 14.4 seconds compiling the standard library and pgx, which had not changed at all. It
gets worse. She adds a README, which the program never reads:

```
ana@vm:~/shelf$ echo "# shelf" > README.md
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:dev . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#6 [2/4] WORKDIR /src
#6 CACHED
#7 [3/4] COPY . .
#7 DONE 0.3s
#8 [4/4] RUN go build -o /usr/local/bin/shelf .
#8 DONE 13.9s

real	0m19.798s
user	0m0.149s
sys	0m0.101s
```

**Another 19.8 seconds**, for a file that does not even reach the binary. `COPY . .` copied it, its
checksum entered the key, and everything below was rebuilt.

## Dependencies first

The fix is to copy in the order things change. Ana rewrites the Dockerfile:

```dockerfile
FROM golang:1.25
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
RUN go build -o /usr/local/bin/shelf .
CMD ["shelf"]
```

The dependency description and the vendored code come first, and a `RUN` compiles the packages
`shelf` depends on, the standard library's `net/http` and pgx's connection pool, into Go's build
cache inside that layer. Only then are the `.go` files copied, and the final `go build` finds
everything else already compiled. The first build costs the same as before:

```
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:dev . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [1/7] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#5 [2/7] WORKDIR /src
#5 CACHED
#7 [3/7] COPY go.mod go.sum ./
#7 DONE 0.2s
#8 [4/7] COPY vendor/ vendor/
#8 DONE 0.1s
#9 [5/7] RUN go build net/http github.com/jackc/pgx/v5/pgxpool
#9 DONE 13.3s
#10 [6/7] COPY *.go ./
#10 DONE 0.0s
#11 [7/7] RUN go build -o /usr/local/bin/shelf .
#11 DONE 0.9s

real	0m19.754s
user	0m0.141s
sys	0m0.094s
```

The slow step is now step 5, 13.3 seconds, and the final build of `shelf` itself is 0.9. Then the
same edit to `main.go`:

```
ana@vm:~/shelf$ sed -i "s/serving on/listening on/" main.go
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:dev . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [1/7] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#6 [2/7] WORKDIR /src
#6 CACHED
#7 [3/7] COPY go.mod go.sum ./
#7 CACHED
#8 [4/7] COPY vendor/ vendor/
#8 CACHED
#9 [5/7] RUN go build net/http github.com/jackc/pgx/v5/pgxpool
#9 CACHED
#10 [6/7] COPY *.go ./
#10 DONE 0.2s
#11 [7/7] RUN go build -o /usr/local/bin/shelf .
#11 DONE 1.0s

real	0m2.340s
user	0m0.165s
sys	0m0.067s
```

**2.3 seconds instead of 20.** Steps 1 to 5 came from the cache, because nothing above `COPY *.go`
changed, and only the small final compile ran. And the README:

```
ana@vm:~/shelf$ echo "A bookshop catalogue over HTTP." >> README.md
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:dev . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [1/7] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#6 [4/7] COPY vendor/ vendor/
#6 CACHED
#7 [2/7] WORKDIR /src
#7 CACHED
#8 [3/7] COPY go.mod go.sum ./
#8 CACHED
#9 [5/7] RUN go build net/http github.com/jackc/pgx/v5/pgxpool
#9 CACHED
#10 [6/7] COPY *.go ./
#10 CACHED
#11 [7/7] RUN go build -o /usr/local/bin/shelf .
#11 CACHED

real	0m0.331s
user	0m0.136s
sys	0m0.074s
```

**Everything cached, 0.3 seconds**: `COPY *.go` copies only Go files, so a README changes no key at
all. Copying exactly what each step needs is the same habit lesson 11 recommended for keeping
secrets out, paying a second time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two Dockerfiles side by side, each a column of steps, after main.go changed. On the left, FROM and WORKDIR are cached, and COPY . . changed, so it and the go build below it run again, the slow step included. On the right, FROM, WORKDIR, COPY go.mod go.sum, COPY vendor and the step that compiles the dependencies are all cached; only COPY *.go and the final go build run.\"><text x=\"10\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">COPY . . first</text><rect x=\"10\" y=\"36\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">FROM golang:1.25</text><text x=\"250\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"10\" y=\"72\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">WORKDIR /src</text><text x=\"250\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"10\" y=\"108\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">COPY . .</text><text x=\"250\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">changed</text><rect x=\"10\" y=\"144\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">RUN go build …</text><text x=\"250\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">runs again</text><text x=\"370\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">dependencies first</text><rect x=\"370\" y=\"36\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">FROM golang:1.25</text><text x=\"610\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"370\" y=\"72\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">WORKDIR /src</text><text x=\"610\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"370\" y=\"108\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COPY go.mod go.sum ./</text><text x=\"610\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"370\" y=\"144\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COPY vendor/ vendor/</text><text x=\"610\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"370\" y=\"180\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RUN go build net/http …</text><text x=\"610\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"370\" y=\"216\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"380\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">COPY *.go ./</text><text x=\"610\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">changed</text><rect x=\"370\" y=\"252\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"380\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">RUN go build …</text><text x=\"610\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">runs again</text></svg>", "caption": "A step is reused only if it and every step above it are unchanged. The first changed step runs again, and so does everything after it, so what changes often belongs at the bottom."}
```

## The same pattern in other languages

The shape is always the same, whatever the language: the file that lists the dependencies, then
the command that installs them, then the code.

| language | first copy | then run | then copy |
| --- | --- | --- | --- |
| Go, with modules | `go.mod`, `go.sum` | `go mod download` | the source |
| Python | `requirements.txt` | `pip install -r requirements.txt` | the source |
| Node.js | `package.json`, `package-lock.json` | `npm ci` | the source |
| Java, with Maven | `pom.xml` | `mvn dependency:go-offline` | `src/` |

Those install commands download from the internet, which the lab's containers cannot reach, as
`lab.sh` explains; that is why `shelf` keeps its dependency vendored and compiles it instead. The
ordering argument does not change: the slow step sits above the code, keyed only on the files that
describe the dependencies.
