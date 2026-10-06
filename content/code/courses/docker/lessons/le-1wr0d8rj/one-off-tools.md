---
title: A tool for one command
version: 1
---

**Any command-line tool that has an image can be used without installing it**: `docker run --rm`
starts it, it does its job on your files, and it is gone. Nothing lands in `/usr/bin`, nothing
conflicts with another version, and the next person runs exactly the same tool by typing the same
line.

Ana keeps the operations files of `shelf` in a directory called `ops`. One of them is a YAML
configuration:

```yaml
service: shelf
database:
  host: db
  port: 5432
  pool: 10
features:
  - search
  - loans
```

## Giving the tool your files

A container sees none of the host's files unless they are mounted, so a tool that works on files
needs the current directory mounted, and needs to be started in it:

```
ana@vm:~/ops$ docker run --rm -v "$PWD":/work -w /work mikefarah/yq:4 ".database.port" config.yaml
5432
ana@vm:~/ops$ cat config.yaml | docker run --rm -i mikefarah/yq:4 ".features | length"
2
```

The first command is the pattern every section of this lesson uses:

- **`--rm`** removes the container when the command ends. A tool run a hundred times would
  otherwise leave a hundred stopped containers.
- **`-v "$PWD":/work`** mounts the current directory at `/work`, a bind mount from lesson 8.
- **`-w /work`** starts the command in that directory, so `config.yaml` is found by its relative
  name.
- Everything after the image name, `".database.port" config.yaml`, is handed to the image's
  entrypoint, which for this image is `yq` itself.

The second command needs no mount at all: **`-i` keeps standard input open**, so a file can be
piped in, and the tool reads it from there. For a tool that reads one input and writes one output,
that is the simplest form of all.

## Two tools Ana does not have

Her machine has neither ShellCheck, which finds bugs in shell scripts, nor hadolint, which finds
them in Dockerfiles:

```
ana@vm:~/ops$ which shellcheck hadolint; echo "exit status $?"
exit status 1
```

`which` found neither, and said so with exit status 1. Here is a backup script with a bug in it:

```sh
#!/bin/sh
target=$1
tar -czf $target/backup.tar.gz /srv/data
echo "saved to $target"
```

```
ana@vm:~/ops$ docker run --rm -v "$PWD":/mnt koalaman/shellcheck:stable /mnt/backup.sh

In /mnt/backup.sh line 3:
tar -czf $target/backup.tar.gz /srv/data
         ^-----^ SC2086 (info): Double quote to prevent globbing and word splitting.

Did you mean:
tar -czf "$target"/backup.tar.gz /srv/data

For more information:
  https://www.shellcheck.net/wiki/SC2086 -- Double quote to prevent globbing ...
```

**SC2086, on line 3**: an unquoted `$target` is split into several words if the path has a space
in it, and `tar` would then write somewhere else. The fix is the quotes it suggests. And here is a
Dockerfile written in a hurry:

```dockerfile
FROM python:latest
RUN apt-get update && apt-get install curl
COPY . /app
CMD python /app/main.py
```

```
ana@vm:~/ops$ docker run --rm -i hadolint/hadolint hadolint --no-color - < Dockerfile
-:1 DL3007 warning: Using latest is prone to errors if the image will ever update. Pin the version explicitly to a release tag
-:2 DL3008 warning: Pin versions in apt get install. Instead of `apt-get install <package>` use `apt-get install <package>=<version>`
-:2 DL3015 info: Avoid additional packages by specifying `--no-install-recommends`
-:2 DL3009 info: Delete the apt lists (/var/lib/apt/lists) after installing something
-:2 DL3014 warning: Use the `-y` switch to avoid manual input `apt-get -y install <package>`
-:4 DL3025 warning: Use arguments JSON notation for CMD and ENTRYPOINT arguments
```

Six findings in four lines, and every one is a real problem. A `latest` tag changes under you; an
`apt-get install` would stop and ask a question in the middle of a build; a package list is left
inside the image; and the `CMD` is in a form that lesson 11 shows breaking `docker stop`. Lessons 11 to 16
explain each one. Hadolint read the file from standard input, so this time nothing was mounted.

**This is how CI pipelines run most of their checks**: a linter, a formatter or a security scanner
is a `docker run` of a pinned image, so the pipeline needs nothing installed but Docker, and the
same command on a laptop gives the same answer. Lesson 25 builds on exactly that.
