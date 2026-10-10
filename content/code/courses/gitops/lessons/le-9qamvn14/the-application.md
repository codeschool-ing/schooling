---
title: The application the course deploys
version: 1
---

**The course needs something to deploy, and the smaller it is the more clearly every change to it
shows.** So the application is a notice board called `bulletin`, and it does one thing: answer
every request with three lines saying which version it is, what message it was given, and whether
it holds a token. Each of the three is set by a different part of this course. The version comes
from the image, the message from configuration in Git, and the token from the secrets of lessons 9
to 11.

It is two files in a directory of its own. Make it with `mkdir ~/bulletin && cd ~/bulletin`.

## The program

Save this as `~/bulletin/index.cgi`:

```sh
#!/bin/sh
# Answers every request with what this copy of bulletin was given.
echo "Content-Type: text/plain"
echo
echo "bulletin $VERSION"
echo "message: ${MESSAGE:-none}"
if [ -r /secrets/token ]; then
  echo "token: sha256:$(sha256sum /secrets/token | cut -c1-12)"
else
  echo "token: none"
fi
```

It is a CGI script: the web server runs it once per request and sends what it prints. That matters
later. Because the script runs again for every request, a token file that changes under it is seen
on the very next one, and lesson 11 relies on that. **It never prints the token itself**, only the
first twelve characters of its SHA-256, which is enough to tell two tokens apart and useless to
anybody who reads the page.

## The image

Save this as `~/bulletin/Dockerfile`:

```dockerfile
FROM busybox:1.37
ARG VERSION=dev
ENV VERSION=$VERSION
COPY --chmod=0755 index.cgi /www/cgi-bin/index.cgi
USER 65534
EXPOSE 8080
CMD ["httpd", "-f", "-p", "8080", "-h", "/www"]
```

BusyBox carries a small web server, `httpd`, and when a directory has no `index.html` it runs
`cgi-bin/index.cgi` instead. The version is a **build argument baked into the image**, so
`bulletin:1.0` says `1.0` wherever it runs and cannot be talked out of it. `USER 65534` is the
`nobody` user: nothing here needs root.

Build it, try it and push it:

```
ana@laptop:~/bulletin$ docker build --quiet --build-arg VERSION=1.0 -t localhost:5001/bulletin:1.0 .
sha256:7528cb6ac23fab00f1a692e4cfd28c8e5c46c4fe68f785291b5ec67381533391
ana@laptop:~/bulletin$ docker run -d --rm --name try -p 127.0.0.1:9090:8080 -e MESSAGE="Hello from Docker." localhost:5001/bulletin:1.0
875a2b93f2d16c09968c1244c64bf6f5d814e4b9f8b93c25aa387b61c494fad2
ana@laptop:~/bulletin$ curl -s localhost:9090
bulletin 1.0
message: Hello from Docker.
token: none
ana@laptop:~/bulletin$ docker stop try
try
ana@laptop:~/bulletin$ docker push localhost:5001/bulletin:1.0
The push refers to repository [localhost:5001/bulletin]
be444a2440bf: Pushed
44136fa355b3: Pushed
68fe9bff2ad4: Pushed
791c5bdd85b8: Pushed
1.0: digest: sha256:7528cb6ac23fab00f1a692e4cfd28c8e5c46c4fe68f785291b5ec67381533391 size: 855
ana@laptop:~/bulletin$ curl -s localhost:5001/v2/_catalog
{"repositories":["bulletin"]}
```

The three lines came back as written: the version from the image, the message from the
environment of `docker run`, and `token: none` because nothing was mounted. The push put the image
in the registry of the last section, and the catalogue now lists it.

**From here on, a version of `bulletin` is an image in that registry, and nothing else.** Nobody
deploys from `~/bulletin` directly. That separation, between the thing that is built once and the
description of where it should run, is most of what the next two sections are about.
