---
title: Build in one image, ship in another
version: 1
---

**A multi-stage Dockerfile has several `FROM` lines, and only the last stage becomes the image.**
The earlier stages hold whatever building needs, a compiler, source code, caches, and the last stage
copies out only the result. It is the single biggest improvement most images can get, and it costs a
few lines.

Ana keeps lesson 12's ordered Dockerfile as `Dockerfile.single` and writes a two-stage one beside it:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM golang:1.25 AS build\nWORKDIR /src\nCOPY go.mod go.sum ./\nCOPY vendor/ vendor/\nRUN go build net/http github.com/jackc/pgx/v5/pgxpool\nCOPY *.go ./\n", "note": "The first stage, named `build`, is lesson 12's ordered Dockerfile: the Go toolchain, the dependencies compiled first, then the code."}, {"code": "RUN CGO_ENABLED=0 go build -o /out/shelf .\n", "note": "`CGO_ENABLED=0` makes Go link everything into the binary, with no dependency on the C library. The next section shows what happens without it."}, {"code": "\nFROM gcr.io/distroless/static-debian12\n", "note": "A blank line and a second `FROM` start a new stage with a new base. Nothing from the first stage comes along unless it is asked for."}, {"code": "COPY --from=build /out/shelf /shelf\n", "note": "`COPY --from=build` takes one file out of the first stage. The compiler, the sources and the build cache stay behind."}, {"code": "CMD [\"/shelf\"]\n", "note": "The image's command, in exec form, with the full path, because this base has no shell to search a `PATH` with."}]}
```

She builds both:

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.single -t shelf:single .
sha256:5dda2a49c2b9dd76a3dd79c4d43998738ebd134733a4ea6fec877e96ab8bb83f
ana@vm:~/shelf$ docker build -q -t shelf:slim .
sha256:7cf63664c09b72351f9ead83d5568307c886e857676d48988987c6f1da32dbe1
```

```
ana@vm:~/shelf$ docker image ls shelf
IMAGE          ID             DISK USAGE   CONTENT SIZE   EXTRA
shelf:single   5dda2a49c2b9       1.44GB          343MB        
shelf:slim     7cf63664c09b         28MB         7.84MB        
```

**1.44GB against 28MB**, for the same program. The single-stage image carries the whole Go toolchain
and the build cache; the two-stage one carries a 14.7MB binary on top of a base of a few megabytes,
as its history shows:

```
ana@vm:~/shelf$ docker history shelf:slim
IMAGE          CREATED         CREATED BY                                      SIZE      COMMENT
7cf63664c09b   2 seconds ago   CMD ["/shelf"]                                  0B        buildkit.dockerfile.v0
<missing>      2 seconds ago   COPY /out/shelf /shelf # buildkit               14.7MB    buildkit.dockerfile.v0
<missing>      N/A             bazel build //common:cacerts_debian12_amd64_…   319kB     
<missing>      N/A             bazel build //common:os_release_debian12        16.4kB    
<missing>      N/A             bazel build //static:nsswitch                   12.3kB    
<missing>      N/A             bazel build //common:tmp                        8.19kB    
<missing>      N/A             bazel build //common:group                      12.3kB    
<missing>      N/A             bazel build //common:home                       16.4kB    
<missing>      N/A             bazel build //common:passwd                     12.3kB    
<missing>      N/A             bazel build //common:rootfs                     4.1kB     
<missing>      N/A             bazel build @bookworm//media-types/amd64:dat…   152kB     
<missing>      N/A             bazel build @bookworm//tzdata/amd64:data_sta…   4.24MB    
<missing>      N/A             bazel build @bookworm//netbase/amd64:data_st…   86kB      
<missing>      N/A             bazel build @bookworm//base-files/amd64:data…   582kB     
```

The two top rows are Ana's. Everything below is **distroless**, a family of base images from Google
built with Bazel rather than a Dockerfile, hence the `bazel build` lines and no creation dates. It
holds only what a static program might need from an operating system: CA certificates to check TLS
connections, time-zone data, `/etc/passwd` with a few users, and `/tmp`. No package manager, and no
shell.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two stages. On the left, the build stage, golang:1.25: the Go toolchain, the source and vendor directories, the build cache, and the compiled /out/shelf; the single-stage image with all of that is 1.44GB. An arrow labelled COPY --from=build carries only /out/shelf to the right, the final stage: distroless static with CA certificates, time zones and /etc/passwd, plus /shelf, 28MB on disk.\"><defs><marker id=\"l13stages-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"320\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"26\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">stage build · golang:1.25</text><rect x=\"26\" y=\"56\" width=\"288\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"71\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Go toolchain, Debian</text><rect x=\"26\" y=\"96\" width=\"288\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/src  vendor/  *.go</text><rect x=\"26\" y=\"136\" width=\"288\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">build cache</text><rect x=\"26\" y=\"176\" width=\"288\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">/out/shelf</text><text x=\"170\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kept as one image: 1.44GB</text><path d=\"M316 191 L436 191\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l13stages-ah-amber)\"></path><text x=\"376\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">COPY --from=build</text><rect x=\"440\" y=\"20\" width=\"270\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"456\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">final stage · distroless</text><rect x=\"456\" y=\"56\" width=\"238\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CA certificates, time zones</text><text x=\"470\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/etc/passwd  /tmp</text><rect x=\"456\" y=\"176\" width=\"238\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">/shelf</text><text x=\"575\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the image: 28MB</text></svg>", "caption": "Everything building needed stays in the first stage. The image is the last stage, and it receives one file."}
```

## Running it, and what is missing

```
ana@vm:~/shelf$ docker run -d --name slim -p 127.0.0.1:8080:8080 shelf:slim
dc7983dde1fea02af672268ace862bc294ae3f9de4456393b033664f8b717d8c
ana@vm:~/shelf$ curl -s localhost:8080/health
ok
ana@vm:~/shelf$ docker exec slim sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
ana@vm:~/shelf$ docker exec slim ls /
OCI runtime exec failed: exec failed: unable to start container process: exec: "ls": executable file not found in $PATH
```

The service answers exactly as before. The two `exec` commands are what changed: **there is no `sh`
and no `ls` in the image**, so nothing can be run inside it except `shelf`. That is a property, not
an accident. An attacker who gets a foothold through a bug in the program finds no shell to continue
with, and a scanner finds very few packages to report vulnerabilities in; lesson 20 measures the difference.
It costs debugging convenience, and lesson 22 shows how to look inside such a container from the
outside when something goes wrong.
