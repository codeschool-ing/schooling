---
title: An image, built from the jar
version: 1
---

A **container image** is a filesystem and a command: everything a process needs to run, from the
operating system's libraries to the Java runtime to the bookshop, and the line that starts it. A
**container** is that image running, isolated from the machine around it. Lesson 19 ran PostgreSQL's
image for the tests; here the bookshop gets an image of its own, so that a server needs Docker and
nothing else. The file that describes how to build one is a **Dockerfile**, and the `docker` course
spends lessons 11 to 14 on it. This section writes the one the bookshop needs and reads it line by
line.

## Where the image starts

Every image starts from another. The tempting start is `ubuntu:24.04` and a line that runs
`apt-get install openjdk-25-jre`, the way lesson 1 installed Java. It works, and from then on keeping
that Java up to date is your job. The usual choice is an image somebody maintains with Java already
in it, and for this course it is **`eclipse-temurin:25-jre-noble`**: Eclipse Temurin, the OpenJDK
build of the Adoptium project, version 25, the runtime only (`jre`, so no `javac`), on Ubuntu 24.04,
whose name is `noble`.

```
ana@vm:~/bookshop$ docker run --rm eclipse-temurin:25-jre-noble java -version
Unable to find image 'eclipse-temurin:25-jre-noble' locally
25-jre-noble: Pulling from library/eclipse-temurin
0ec513ffc6c8: Pulling fs layer
f2b4ef06ff01: Pulling fs layer
13cfdcd96095: Pulling fs layer
4f4fb700ef54: Pulling fs layer
479ddbf8457f: Pulling fs layer
0ec513ffc6c8: Download complete
4f4fb700ef54: Download complete
f2b4ef06ff01: Download complete
13cfdcd96095: Download complete
eb0920420485: Download complete
479ddbf8457f: Download complete
f2b4ef06ff01: Pull complete
3f19f9376beb: Download complete
13cfdcd96095: Pull complete
0ec513ffc6c8: Pull complete
4f4fb700ef54: Pull complete
479ddbf8457f: Pull complete
Digest: sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
Status: Downloaded newer image for eclipse-temurin:25-jre-noble
openjdk version "25.0.4.1" 2026-08-18 LTS
OpenJDK Runtime Environment Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS)
OpenJDK 64-Bit Server VM Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS, mixed mode, sharing)
```

The first `docker run` had to download it, layer by layer; later ones start at once. (The machine
these transcripts were recorded on pulled through `mirror.gcr.io`, Google's cache of Docker Hub. The
names and the digest are Docker Hub's, and yours come from Docker Hub directly.) The same 25.0.4.1 as
the JDK on your machine, built by a different project from the same source. And underneath:

```
ana@vm:~/bookshop$ docker run --rm eclipse-temurin:25-jre-noble bash -c 'grep PRETTY_NAME /etc/os-release; command -v java curl wget'
PRETTY_NAME="Ubuntu 24.04.5 LTS"
/opt/java/openjdk/bin/java
```

Ubuntu 24.04, `java` on the path, and neither `curl` nor `wget`. An image carries what its makers put
in it and nothing else, which is less to patch and less for an intruder to use; the section on
Compose has to work around the missing `curl`.

## What Docker is allowed to see

`docker build` sends a directory, the **build context**, to the Docker daemon, and the Dockerfile can
copy only what is in it. The bookshop's directory holds the source, `target/classes`, test reports,
and soon a file of passwords; none of that belongs in an image. Create `.dockerignore` in
`~/bookshop`:

```
*
!target/bookshop-0.1.0.jar
```

The first line excludes everything, and the `!` line lets one file back in: the jar. Whatever else is
added to the project later stays out of the image unless somebody adds a line here, which is the
safe way round.

## The Dockerfile

Create `Dockerfile`, with that name and no extension, in `~/bookshop`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM eclipse-temurin:25-jre-noble AS layers", "note": "The first of two **stages**. It starts from the same base as the final image and is given a name, `layers`, so the second stage can copy out of it. Nothing else of it reaches the image you run."}, {"code": "WORKDIR /build\nCOPY target/bookshop-0.1.0.jar app.jar\nRUN java -Djarmode=tools -jar app.jar extract --layers --launcher --destination extracted\n", "note": "Inside it, the jar is copied in and split with the command from the last section. `WORKDIR` creates `/build` and makes it the current directory for what follows. The jar never needs to be unpacked on your machine."}, {"code": "FROM eclipse-temurin:25-jre-noble", "note": "The second `FROM` starts again from a clean copy of the base. **This is the image that ships**: the JRE on Ubuntu 24.04, plus whatever the lines below add."}, {"code": "RUN useradd --uid 10001 --user-group --no-create-home bookshop\nUSER bookshop", "note": "A user with a fixed number, 10001, and a group of its own, with no home directory. Every instruction after `USER`, the running application included, is that user's, so a process that breaks out of the bookshop finds itself an ordinary user inside the container, not root."}, {"code": "WORKDIR /app", "note": "The directory the application runs in, created owned by root and readable by all."}, {"code": "COPY --from=layers /build/extracted/dependencies/ ./\nCOPY --from=layers /build/extracted/spring-boot-loader/ ./\nCOPY --from=layers /build/extracted/snapshot-dependencies/ ./\nCOPY --from=layers /build/extracted/application/ ./", "note": "The four directories, in the order of how rarely they change. Each `COPY` is a layer of the image, and the trailing `./` merges all four into `/app`, which is the layout the launcher expects."}, {"code": "EXPOSE 8080 8081", "note": "Documentation, nothing more: it says which ports the process listens on. Publishing them is the job of whoever runs the container."}, {"code": "ENTRYPOINT [\"java\", \"-XX:MaxRAMPercentage=75\", \"org.springframework.boot.loader.launch.JarLauncher\"]", "note": "The **exec form**, a JSON list, so Docker starts `java` itself as the container's first process. `-XX:MaxRAMPercentage=75` sizes the heap from the container's memory limit, and `JarLauncher` is the class the manifest named, now found in the merged directory rather than inside a jar."}]}
```

Two `FROM` lines make two **stages**. The first exists only to run `extract` on the jar, so that the
second can copy the four directories as four layers, in the order of the last section. Nothing of the
first stage reaches the image except what is copied out of it.

## Building it

```
ana@vm:~/bookshop$ docker build -t bookshop:0.1.0 .
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 696B done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/eclipse-temurin:25-jre-noble
#2 DONE 0.0s

#3 [internal] load .dockerignore
#3 transferring context: 69B done
#3 DONE 0.0s

#4 [layers 1/4] FROM docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
#4 resolve docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5 done
#4 extracting sha256:f2b4ef06ff01a67d4bed7657a4ae379a7d07934b7c3e743454a22a0d5275fb2b
#4 ...

#5 [internal] load build context
#5 transferring context: 69.15MB 0.3s done
#5 DONE 0.3s

#4 [layers 1/4] FROM docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
#4 extracting sha256:f2b4ef06ff01a67d4bed7657a4ae379a7d07934b7c3e743454a22a0d5275fb2b 0.6s done
#4 DONE 0.6s

#4 [layers 1/4] FROM docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
#4 extracting sha256:13cfdcd9609512facd4ae43fd438ea425882cf40c2066215115ddb298a0c37a7
#4 extracting sha256:13cfdcd9609512facd4ae43fd438ea425882cf40c2066215115ddb298a0c37a7 0.2s done
#4 DONE 0.9s

#4 [layers 1/4] FROM docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
#4 extracting sha256:479ddbf8457f67755f9a675ec6d41f7a08f32c7f59d2f4d4a202eaac9bd87161
#4 extracting sha256:479ddbf8457f67755f9a675ec6d41f7a08f32c7f59d2f4d4a202eaac9bd87161 1.1s done
#4 DONE 1.9s

#4 [layers 1/4] FROM docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
#4 extracting sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1 done
#4 extracting sha256:0ec513ffc6c8569ba27cb578c2444a31d6777663a1716122acbb2e83ab48101d done
#4 DONE 1.9s

#6 [layers 2/4] WORKDIR /build
#6 DONE 0.4s

#7 [stage-1 2/7] RUN useradd --uid 10001 --user-group --no-create-home bookshop
#7 DONE 0.5s

#8 [layers 3/4] COPY target/bookshop-0.1.0.jar app.jar
#8 DONE 0.1s

#9 [layers 4/4] RUN java -Djarmode=tools -jar app.jar extract --layers --launcher --destination extracted
#9 ...

#10 [stage-1 3/7] WORKDIR /app
#10 DONE 0.0s

#9 [layers 4/4] RUN java -Djarmode=tools -jar app.jar extract --layers --launcher --destination extracted
#9 DONE 0.7s

#11 [stage-1 4/7] COPY --from=layers /build/extracted/dependencies/ ./
#11 DONE 0.1s

#12 [stage-1 5/7] COPY --from=layers /build/extracted/spring-boot-loader/ ./
#12 DONE 0.0s

#13 [stage-1 6/7] COPY --from=layers /build/extracted/snapshot-dependencies/ ./
#13 DONE 0.0s

#14 [stage-1 7/7] COPY --from=layers /build/extracted/application/ ./
#14 DONE 0.0s

#15 exporting to image
#15 exporting layers
#15 exporting layers 1.5s done
#15 exporting manifest sha256:49ba9eace20ae8be4b53f18ed16ec47e2ce46f4c497d4c45c055375691376525 done
#15 exporting config sha256:92b6b2be0dfb76c73878e212907d3cb330c1f8c5de181025563d07be487ae0e3 done
#15 exporting attestation manifest sha256:7ec42d5dd6e3a7b14bf3f39bb5f085bac370d9a9845c43864c40a47f96966179 done
#15 exporting manifest list sha256:54854756e58d853a3e252a78b8bc4dad9986bef5522fd17d3cd95abba9ca524a done
#15 naming to docker.io/library/bookshop:0.1.0 done
#15 unpacking to docker.io/library/bookshop:0.1.0
#15 unpacking to docker.io/library/bookshop:0.1.0 0.5s done
#15 DONE 2.0s
```

Read the steps by their names: `[layers 1/4]` to `[layers 4/4]` are the first stage and
`[stage-1 2/7]` to `[stage-1 7/7]` the second. They are numbered in the order Docker *started* them,
and the two stages interleave: the second stage's `useradd` ran between the first stage's steps, and
`#9 ...` marks the `extract` left running while `#10` finished. Nothing connects the two stages until
the first `COPY --from`, so Docker runs them side by side. The build context was **69.15 MB**: the jar and nothing
else.

```
ana@vm:~/bookshop$ docker images bookshop
IMAGE            ID             DISK USAGE   CONTENT SIZE   EXTRA
bookshop:0.1.0   54854756e58d        562MB          166MB        
```

Two sizes, because an image is stored twice over: compressed, as it travels to and from a registry,
and unpacked on disk to run. Most of either is the base image; the bookshop's part shows in its
history, newest layer first:

```
ana@vm:~/bookshop$ docker history --format '{{.Size}}\t{{.CreatedBy}}' bookshop:0.1.0 | head -n 9
0B	ENTRYPOINT ["java" "-XX:MaxRAMPercentage=75"…
0B	EXPOSE [8080/tcp 8081/tcp]
319kB	COPY /build/extracted/application/ ./ # buil…
4.1kB	COPY /build/extracted/snapshot-dependencies/…
696kB	COPY /build/extracted/spring-boot-loader/ ./…
69.1MB	COPY /build/extracted/dependencies/ ./ # bui…
8.19kB	WORKDIR /app
0B	USER bookshop
57.3kB	RUN /bin/sh -c useradd --uid 10001 --user-gr…
```

The four `COPY` lines are four layers, **69.1 MB of libraries and 319 kB of bookshop**, the same two
numbers as the last section in the decimal megabytes Docker counts in (66 MiB is 69 MB). The `0B`
lines record settings rather than files. The user the image runs as:

```
ana@vm:~/bookshop$ docker run --rm --entrypoint id bookshop:0.1.0
uid=10001(bookshop) gid=10001(bookshop) groups=10001(bookshop)
```

`--entrypoint id` replaced the Dockerfile's command with `id`, so this container ran one command and
was removed, `--rm`, once it had answered.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The bookshop image as a stack of eleven layers, the base at the bottom. Five layers come from eclipse-temurin:25-jre-noble. Above them: the user, 57.3 kB; the working directory; the libraries, 69.1 MB; the launcher, 696 kB; the empty snapshot layer, 4.1 kB; and the bookshop's code, 319 kB, at the top. After a change to one line of code, every layer was reused except the top one.\"><defs><marker id=\"l23-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">layer, as Docker built it</text><text x=\"410\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">size</text><text x=\"490\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after a one-line change</text><rect x=\"20\" y=\"28\" width=\"370\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COPY …/application/</text><text x=\"410\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">319 kB</text><text x=\"490\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">rebuilt</text><rect x=\"20\" y=\"64\" width=\"370\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COPY …/snapshot-dependencies/</text><text x=\"410\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4.1 kB</text><text x=\"490\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reused</text><rect x=\"20\" y=\"100\" width=\"370\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COPY …/spring-boot-loader/</text><text x=\"410\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">696 kB</text><text x=\"490\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reused</text><rect x=\"20\" y=\"136\" width=\"370\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COPY …/dependencies/</text><text x=\"410\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">69.1 MB</text><text x=\"490\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reused</text><rect x=\"20\" y=\"194\" width=\"370\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">WORKDIR /app</text><text x=\"410\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8.19 kB</text><text x=\"490\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reused</text><rect x=\"20\" y=\"230\" width=\"370\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RUN useradd …</text><text x=\"410\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">57.3 kB</text><text x=\"490\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reused</text><rect x=\"20\" y=\"266\" width=\"370\" height=\"56\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">eclipse-temurin:25-jre-noble</text><text x=\"32\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">five layers: Ubuntu 24.04 and the Java 25 runtime</text><text x=\"490\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shared with every image on it</text><path d=\"M 700 316 L 700 34\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><text x=\"692\" y=\"316\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">rarest change</text><text x=\"692\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">most frequent</text></svg>", "caption": "Rarest change at the bottom, most frequent at the top. A changed layer invalidates everything above it, so the code goes last and a commit costs 319 kB."}
```

## A change of one line

The point of the order is the next build. Keep a list of the image's layers, change one word in a log
message, and build again. `grep` keeps each step's name and the line after it:

```
ana@vm:~/bookshop$ docker inspect --format '{{range .RootFS.Layers}}{{println .}}{{end}}' bookshop:0.1.0 > /tmp/layers-before.txt
ana@vm:~/bookshop$ sed -i 's/with {} books/with {} titles/' src/main/java/com/example/bookshop/catalogue/CatalogueReport.java
ana@vm:~/bookshop$ mvn -q package -DskipTests
ana@vm:~/bookshop$ docker build -t bookshop:0.1.0 . 2>&1 | grep --no-group-separator -A 1 -E '^#[0-9]+ \[(layers|stage-1)'
#4 [layers 1/4] FROM docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
#4 resolve docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5 0.0s done
#6 [layers 2/4] WORKDIR /build
#6 CACHED
#7 [layers 3/4] COPY target/bookshop-0.1.0.jar app.jar
#7 DONE 0.2s
#8 [layers 4/4] RUN java -Djarmode=tools -jar app.jar extract --layers --launcher --destination extracted
#8 DONE 0.7s
#9 [stage-1 2/7] RUN useradd --uid 10001 --user-group --no-create-home bookshop
#9 CACHED
#10 [stage-1 3/7] WORKDIR /app
#10 CACHED
#11 [stage-1 4/7] COPY --from=layers /build/extracted/dependencies/ ./
#11 CACHED
#12 [stage-1 5/7] COPY --from=layers /build/extracted/spring-boot-loader/ ./
#12 CACHED
#13 [stage-1 6/7] COPY --from=layers /build/extracted/snapshot-dependencies/ ./
#13 CACHED
#14 [stage-1 7/7] COPY --from=layers /build/extracted/application/ ./
#14 DONE 0.0s
```

Every step of the second stage before the last says `CACHED`: the user, the directory, and the three
library layers, the 69 MB among them. The first stage ran again, because the jar it copies had
changed, and its `extract` wrote the libraries out again. Docker compared what `COPY --from` was about
to copy, found the same bytes as last time, and kept the layer it had. Only `application` was built.

```
ana@vm:~/bookshop$ docker inspect --format '{{range .RootFS.Layers}}{{println .}}{{end}}' bookshop:0.1.0 > /tmp/layers-after.txt
ana@vm:~/bookshop$ diff /tmp/layers-before.txt /tmp/layers-after.txt
11c11
< sha256:7417e89dad3b8c1134e03ab69b9cf56c6a27b80640d57c051e9abab46bb59bfb
---
> sha256:4d3d02bfd69c8e8c915a7340e75e2627efa83366c07813d70f3f18c79310853e
```

The list of layers is eleven lines long, the base's and the bookshop's, and **one line changed**: the
eleventh, the bookshop's code. A registry that already holds the old image receives 319 kB for this
release, and a server that already runs it downloads the same.

Put the message back, and rebuild, so the image matches the code again. `-q` makes `docker build` print
only the new image's identifier:

```
ana@vm:~/bookshop$ sed -i 's/with {} titles/with {} books/' src/main/java/com/example/bookshop/catalogue/CatalogueReport.java
ana@vm:~/bookshop$ mvn -q package -DskipTests && docker build -q -t bookshop:0.1.0 .
sha256:776b429ca51b8fb081511777b886bc245c9825bb041a1ca456005f93d0ecc7cd
```
