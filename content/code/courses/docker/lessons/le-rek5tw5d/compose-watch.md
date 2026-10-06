---
title: Compose watch
version: 1
---

**A bind mount needs the container to have the tools to build or run the source, and the image you
ship has neither.** `docker compose watch` takes the other route: it watches files on the host and,
when one changes, does what the Compose file says, here rebuilding the real image and replacing the
container.

```yaml
services:
  web:
    build:
      context: .
      args:
        VERSION: dev
    image: shelf:dev-watch
    ports:
      - "127.0.0.1:8080:8080"
    develop:
      watch:
        - action: rebuild
          path: .
          include:
            - "*.go"
```

The `develop.watch` section names the files and the action. `rebuild` builds the image and recreates
the service; `sync` copies changed files into a running container instead, for programs that reload
themselves like the Node service of the previous section; `sync+restart` copies them and restarts
the container.

```
ana@vm:~$ cd shelf
ana@vm:~/shelf$ docker compose up -d --wait 2>&1 | grep -E "Healthy|Started"
 Container shelf-web-1 Started 
 Container shelf-web-1 Healthy 
ana@vm:~/shelf$ curl -s localhost:8080/books | jq length
3
ana@vm:~/shelf$ docker compose watch --no-up > watch.log 2>&1 &
ana@vm:~/shelf$ sed -i "s|{3, \"The Remains of the Day\", \"Kazuo Ishiguro\"},|&\n\t{4, \"Vidas Secas\", \"Graciliano Ramos\"},|" main.go
ana@vm:~/shelf$ grep -vE "^ *#|^$" watch.log | head -12
Watch enabled
Rebuilding service(s) ["web"] after changes were detected...
 Image shelf:dev-watch Building 
 Image shelf:dev-watch Built 
service(s) ["web"] successfully built
 Container shelf-web-1 Recreate 
 Container shelf-web-1 Recreated 
 Container shelf-web-1 Starting 
 Container shelf-web-1 Started 
ana@vm:~/shelf$ curl -s localhost:8080/books | jq -c ".[3]"
{"id":4,"title":"Vidas Secas","author":"Graciliano Ramos"}
ana@vm:~/shelf$ kill %1
```

**Ana saved `main.go`, and Compose rebuilt `shelf:dev-watch` and replaced the container**, which then
served the fourth book. The build is the production Dockerfile, multi-stage, distroless and all, so
what runs while she works is what will ship, and the build cache of lesson 12 keeps each rebuild to
the steps the change touched. The last command stops the watch that ran in the background.

**The trade between the two approaches** is speed against fidelity. A bind mount and a reloading
program answer in a second or two, in a container that is not the one that ships. A rebuild on change
takes as long as a build, and tests the real image every time. Many projects use both: the mount for
the inner loop of a single service, and `watch` with `rebuild` or the full `docker compose up --build`
before a commit.
