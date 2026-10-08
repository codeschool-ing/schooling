---
title: A first Dockerfile
version: 2
---

**A Dockerfile is the written recipe for an image: a base to start from, then one instruction per
step, each read from top to bottom.** It replaces lesson 7's `docker commit` with something a person
can read, review and run again, and every image in the rest of this course is built from one.

Ana's project is `shelf`, as the previous section wrote it out, with pgx in `vendor/` so that it
builds without a network:

```
ana@vm:~/shelf$ ls -A
.git
go.mod
go.sum
main.go
main_test.go
postgres.go
postgres_test.go
vendor
```

She adds a Dockerfile of six lines:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM golang:1.25\n", "note": "The base image: Debian with the Go toolchain installed. Every later instruction adds to it."}, {"code": "WORKDIR /src\n", "note": "Sets the working directory for the instructions after it, and for the container. It is created if missing."}, {"code": "COPY . .\n", "note": "Copies the build context, here Ana's whole directory, into `/src` in the image."}, {"code": "RUN go build -o /usr/local/bin/shelf .\n", "note": "Runs a command at build time, inside the image being built. Its result, the compiled `shelf`, becomes a new layer."}, {"code": "EXPOSE 8080\n", "note": "Documents that the program listens on 8080. It publishes nothing; `docker run -p` does that."}, {"code": "CMD [\"shelf\"]\n", "note": "The default command when the container starts, in exec form: a JSON list, run directly with no shell."}]}
```

## Building it

`docker build` reads the Dockerfile in the given directory, `.`, and `-t` names the result:

```
ana@vm:~/shelf$ docker build -t shelf:dev .
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 141B done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/golang:1.25
#2 DONE 0.0s

#3 [internal] load .dockerignore
#3 transferring context: 2B done
#3 DONE 0.0s

#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 resolve docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80 0.0s done
#4 DONE 0.1s

#5 [internal] load build context
#5 transferring context: 10.03MB 0.1s done
#5 DONE 0.2s

#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 extracting sha256:1da3cb2f93f2ca3c5bdaf4c024a7f1ebd717938d20c858e4be4b9aa81fc8608c
#4 extracting sha256:1da3cb2f93f2ca3c5bdaf4c024a7f1ebd717938d20c858e4be4b9aa81fc8608c 1.4s done
#4 DONE 1.5s

#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 extracting sha256:68b64c51cda3d04397bcf5742a29a9a1ba7adcfd18a376bacb8d114ed64cbd5a
#4 extracting sha256:68b64c51cda3d04397bcf5742a29a9a1ba7adcfd18a376bacb8d114ed64cbd5a 0.6s done
#4 DONE 2.1s

#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 extracting sha256:ec935196e6a095bdd6ac865248321ea4fd33424071fe14264cd33900f8ae6212
#4 extracting sha256:ec935196e6a095bdd6ac865248321ea4fd33424071fe14264cd33900f8ae6212 1.8s done
#4 extracting sha256:cd6b31ea4633e156e104ba957c37e29f4e6d880222f0130b90108570442ad860
#4 extracting sha256:cd6b31ea4633e156e104ba957c37e29f4e6d880222f0130b90108570442ad860 2.5s done
#4 DONE 6.4s

#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 extracting sha256:2129e38f8eb91140cd022167d69ad764919cb78de3d2c70efd48c5e6b1b48f98
#4 extracting sha256:2129e38f8eb91140cd022167d69ad764919cb78de3d2c70efd48c5e6b1b48f98 2.5s done
#4 DONE 8.9s

#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 extracting sha256:547e989301353b555d27ccfb0e4081fa9ee30e43ce5c3e57100b4603676d58cd done
#4 extracting sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1 done
#4 DONE 8.9s

#6 [2/4] WORKDIR /src
#6 DONE 1.4s

#7 [3/4] COPY . .
#7 DONE 0.1s

#8 [4/4] RUN go build -o /usr/local/bin/shelf .
#8 DONE 14.2s

#9 exporting to image
#9 exporting layers
#9 exporting layers 4.3s done
#9 exporting manifest sha256:731b625606a0776dcf109033bbf89055cc76fe17440b72c5209b67abe432c646 done
#9 exporting config sha256:ee4e8a00f3ed1097f4b9dc52f84d045fef19429eb4bb1849c0a6b13feece833e done
#9 exporting attestation manifest sha256:444597349083ae88319778e30f5f0a02215a64acfe3c0094c6c4d5f028f004b2 done
#9 exporting manifest list sha256:5e29af317b039aa0ab1069f608efb3a0e9d4ae1277a260b35a1a24c50fa66e5e done
#9 naming to docker.io/library/shelf:dev done
#9 unpacking to docker.io/library/shelf:dev
#9 unpacking to docker.io/library/shelf:dev 1.0s done
#9 DONE 5.4s
```

The build prints one numbered step per piece of work, and it is worth reading once from top to
bottom:

- **`#1` to `#3`** load the Dockerfile and a `.dockerignore` (there is none yet, so `2B`).
- **`#4` is `FROM`**, pinned to the base image's digest. The `extracting` lines are the builder
  unpacking the base image's layers for its own use, a cost paid the first time it meets that image.
- **`#5` is the build context**: 10.03MB of Ana's directory, sent to the builder. The last section
  of this lesson is about that number.
- **`#6` to `#8` are her instructions**, in order. `go build` is the slow one, 14.2 seconds,
  because it compiles the standard library and pgx as well as `shelf`.
- **`#9` writes the image**, and names it `shelf:dev`.

## Running it

```
ana@vm:~/shelf$ docker run -d --name shelf -p 127.0.0.1:8080:8080 shelf:dev
62034944ecf304953a5ee2b5b4ebcc06198786c077aefba404acab193ea22b35
ana@vm:~/shelf$ curl -s localhost:8080/books | jq -c ".[]"
{"id":1,"title":"The Left Hand of Darkness","author":"Ursula K. Le Guin"}
{"id":2,"title":"Dom Casmurro","author":"Machado de Assis"}
{"id":3,"title":"The Remains of the Day","author":"Kazuo Ishiguro"}
ana@vm:~/shelf$ curl -s localhost:8080/health
ok
```

**The program built inside the image answers on Ana's machine.** The image carries everything it
needs, and nothing was installed on the host to get here. Its size is the problem lesson 13 solves:

```
ana@vm:~/shelf$ docker image ls shelf
IMAGE       ID             DISK USAGE   CONTENT SIZE   EXTRA
shelf:dev   5e29af317b03       1.45GB          345MB   U    
```

1.45GB on disk to run one program, because the image is the whole Go toolchain
with `shelf` added on top. Building in one image and shipping in another is the fix, and it needs
the next two lessons first.
