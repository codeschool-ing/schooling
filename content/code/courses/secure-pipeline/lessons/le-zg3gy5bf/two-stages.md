---
title: Two stages, and nothing in the second that the service does not run
version: 1
---

`docker` lesson 13 built a multi-stage image to make it smaller. Here the reason is the one the last
two sections found: **the tools that build an image are a liability in the image that runs.** pip
brought the only fixable findings of the slim base, and a shell is the first thing anybody who gets
code running in a container reaches for. A two-stage build keeps both on the side of the build,
where they are needed, and ships the result.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"sp-l08-stages\" aria-label=\"The two stages of linkbox's Dockerfile. The build stage, from python:3.13-slim, has pip, a shell and apt, and produces two directories, /packages and /data. Only those two cross into the run stage, from the distroless nonroot image, which adds app.py and settings.py in /app and runs python3 as user 65532. pip, the shell and apt stay behind.\"><defs><marker id=\"sp-l08-stages-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15\" y=\"15\" width=\"300\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">build stage</text><text x=\"30\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">python:3.13-slim</text><rect x=\"405\" y=\"15\" width=\"300\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"420\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">run stage</text><text x=\"420\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">distroless/python3:nonroot</text><rect x=\"35\" y=\"75\" width=\"80\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"75.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pip</text><rect x=\"125\" y=\"75\" width=\"80\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"165.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sh</text><rect x=\"215\" y=\"75\" width=\"80\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"255.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">apt</text><text x=\"165\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">stays behind</text><rect x=\"35\" y=\"150\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/packages</text><rect x=\"35\" y=\"210\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/data</text><rect x=\"425\" y=\"150\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/packages</text><rect x=\"425\" y=\"210\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/data</text><text x=\"555.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">owned by 65532</text><rect x=\"425\" y=\"75\" width=\"125\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"487.5\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">/app</text><text x=\"487.5\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">app.py settings.py</text><rect x=\"560\" y=\"75\" width=\"125\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"622.5\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">python3</text><text x=\"622.5\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">runs as 65532</text><path d=\"M295 170 L423 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l08-stages-ah-phosphor)\"></path><path d=\"M295 230 L423 230\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l08-stages-ah-phosphor)\"></path><text x=\"360\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">COPY</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">--from=build</text></svg>", "caption": "Two directories cross from the build to the image that ships. Everything that built them stays where it was used."}
```

### The Dockerfile

The new Dockerfile replaces lesson 1's whole. Save it as `Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "# Build: the pinned dependencies, installed into one directory by the pip\n# of an image that has one.\nFROM python:3.13-slim AS build", "note": "The build stage starts from slim, which has pip. Nothing in this stage reaches the final image unless a `COPY --from=build` below names it."}, {"code": "COPY requirements.txt /", "note": "Only the requirements file is copied in, so this layer and the next are rebuilt when a pin changes and reused when only the code does."}, {"code": "RUN pip install --no-cache-dir --target /packages -r /requirements.txt", "note": "`--target` installs the packages into one plain directory instead of into this image's Python. That directory is the whole result of the stage; pip stays behind."}, {"code": "RUN mkdir /data", "note": "The final image has no shell to run `mkdir` with, so the directory for the database is made here and copied across."}, {"code": "\n# Run: the same Python and nothing else. No shell, no package manager, no\n# pip, and a user that is not root.\nFROM gcr.io/distroless/python3-debian13:nonroot", "note": "The run stage: Google's distroless Python on the same Debian release, in its `nonroot` variant, whose default user is 65532."}, {"code": "COPY --from=build /packages /packages", "note": "The installed packages, as they are."}, {"code": "COPY --from=build --chown=nonroot:nonroot /data /data", "note": "The data directory belongs to the user the application runs as; everything else stays owned by root and cannot be changed by the application."}, {"code": "COPY app.py settings.py /app/", "note": "The two files the service needs. Not the tests, not `ci/`, not the Dockerfile: a `COPY . .` would have shipped all of them."}, {"code": "WORKDIR /app\nENV PYTHONPATH=/packages LINKBOX_DB=/data/linkbox.db", "note": "`PYTHONPATH` is how Python finds packages in a directory it did not install them into."}, {"code": "EXPOSE 8000\nENTRYPOINT [\"python3\", \"-m\", \"gunicorn\", \"--bind\", \"0.0.0.0:8000\", \"app:app\"]", "note": "`python3 -m gunicorn` rather than `gunicorn`: the script pip wrote in `/packages/bin` starts with the path of the build stage's Python, which does not exist in this image."}]}
```

**`pip install --target` is what makes the split work.** An ordinary `pip install` writes into the
build image's own Python, mixed with pip and everything else that image has, and there is no clean
way to copy out only what it added. `--target` puts the packages, and nothing else, in a directory
of their own; that directory crosses to the second stage, and pip does not. A package with compiled
parts is built for one minor version of Python, which is why both stages are 3.13 on the same
Debian release.

Three smaller decisions follow from the base. The image has no shell, so the data directory is
created in the first stage and copied. The application's files are owned by root and the
application runs as user 65532, so it can write its database and cannot change its own code.
And `COPY app.py settings.py` names files instead of copying the directory, so the tests, the
pipeline scripts and the `.git` directory stay out whatever `.dockerignore` says.

### Build it, and look inside

```
ana@vm:~/scans$ cd ~/linkbox
ana@vm:~/linkbox$ docker build -q -t linkbox:dev .
sha256:7eb384df9aef14b08f93b185dbba4cdf7bd0e11aa51d0e330dd1d215555aeeef
ana@vm:~/linkbox$ docker images --format "{{.Repository}}:{{.Tag}}  {{.Size}}" linkbox:dev
linkbox:dev  100MB
ana@vm:~/linkbox$ docker image inspect --format "{{.Config.User}}" linkbox:dev
65532
```

**100 MB, against 1.64 GB for lesson 1's image**, and the image declares user `65532`, which the
distroless `nonroot` variant sets for you. The surest way to see what is not in it is to ask for it:

```
ana@vm:~/linkbox$ docker run --rm --entrypoint sh linkbox:dev
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "sh": executable file not found in $PATH

Run 'docker run --help' for more information
ana@vm:~/linkbox$ docker run --rm --entrypoint python3 linkbox:dev -m pip --version
/usr/bin/python3: No module named pip
ana@vm:~/linkbox$ docker run --rm --entrypoint python3 linkbox:dev -c "import os; print(os.getuid(), os.getgid())"
65532 65532
```

There is no `sh` to start, no pip to import, and the process is user 65532 in group 65532. **A
missing shell is not a security boundary on its own**: anybody able to run code in this container
can still run Python, which is a complete programming language. What it removes is the easy path,
the one-line commands that most automated attacks and most hands-on intrusions begin with, and it
removes every finding that belonged to the programs it left out.

It also changes how you debug. `docker exec -it linkbox sh` no longer works, so investigating a
running container means its logs, `docker exec` with `python3`, or a debugging container attached
to it; Kubernetes has `kubectl debug` for that, which lesson 10's cluster could use.

### It still does its job

```
ana@vm:~/linkbox$ docker run -d --name linkbox -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
53954fc514ab94fd54af98190061fc89fda6b2daac25b535e3b5777fab6f5336
ana@vm:~/linkbox$ curl -s -X POST -H "X-Token: local-only" -d url=https://example.org/handbook http://127.0.0.1:8000/links
{"code":"E7y0OA"}
ana@vm:~/linkbox$ docker logs linkbox 2>&1 | head -n 4
[2026-10-23 12:40:24 +0000] [1] [INFO] Starting gunicorn 22.0.0
[2026-10-23 12:40:24 +0000] [1] [INFO] Listening at: http://0.0.0.0:8000 (1)
[2026-10-23 12:40:24 +0000] [1] [INFO] Using worker: sync
[2026-10-23 12:40:24 +0000] [7] [INFO] Booting worker with pid: 7
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
```

**The service answers as before**, now from gunicorn started as `python3 -m gunicorn`. The token is
a placeholder for a local test, passed as an environment variable the way lesson 6 arranged it.

### And the scan

```
ana@vm:~/linkbox$ trivy image --quiet --format json linkbox:dev | jq -r -f ~/scans/count.jq
debian: 162 found (HIGH 26, LOW 49, MEDIUM 87), 0 with a fix
python-pkg: nothing found
```

**The same 162 findings as the bare distroless base, and nothing from linkbox's own packages.**
Every package in `/packages` was read, because each kept its `.dist-info/METADATA`, and the pins of
lesson 5 have no advisory in this database. Nothing the build stage held, pip included, appears.
That is the image the pipeline ships from now on.
