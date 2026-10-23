---
title: Base images by digest, and a build with no network
version: 1
---

The lock pins the Python packages. Two other inputs still float. **The base images are named by
tag**, and lesson 14 showed what a tag is worth: `python:3.13-slim` is rebuilt upstream whenever
Debian or Python publishes a fix, and the same Dockerfile builds on different bytes from one week to
the next. And **the build reaches the network**: `pip install` inside `docker build` talks to PyPI,
so what the image contains depends on what PyPI answered during the build, checked by nobody after.

### Base images by digest

A digest names the bytes, so the Dockerfile names the base images by digest, with the tag kept in
front for the reader. The registry tells you the digest a tag points at today. The first command asks
Google's mirror of Docker Hub, which serves Docker Hub's names and digests; the second asks the
local copy of the distroless image:

```
ana@vm:~/linkbox$ docker buildx imagetools inspect mirror.gcr.io/library/python:3.13-slim | head -n 3
Name:      mirror.gcr.io/library/python:3.13-slim
MediaType: application/vnd.oci.image.index.v1+json
Digest:    sha256:57b29a7c050c4e679e4bea572e14b3965cf4b5839de2da49d55e49ffc4024f39
ana@vm:~/linkbox$ docker image inspect --format "{{index .RepoDigests 0}}" gcr.io/distroless/python3-debian13:nonroot
gcr.io/distroless/python3-debian13@sha256:727eccc5d83f11273c954652667b5b5a1c66120bd4cfb884e879ab77dcdf966a
```

**Updating a base image becomes a one-line diff**, reviewed like any other, instead of something that
happens to whoever builds next. Lesson 2's nightly rebuild still matters: it is now the place to
notice that the digest you pinned has a newer one with fixes, and lesson 18's bots can propose the
change.

### The build, offline

`docker build --network none` gives the build's `RUN` steps no network at all. Try it on lesson 8's
Dockerfile, which installs from PyPI:

```
ana@vm:~/linkbox$ docker build -q --network none -t linkbox:offline . 2>&1 | tail -n 4
   6 |     RUN mkdir /data
   7 |     
--------------------
ERROR: failed to build: failed to solve: process "/bin/sh -c pip install --no-cache-dir --target /packages -r /requirements.txt" did not complete successfully: exit code: 1
```

The step that runs `pip install` against PyPI did not complete: with no network there is no index
to reach, and the build failed. That failure is the point of the flag: **a build that cannot reach the network can only use what it was handed**, so everything it
uses has passed through a step somebody can check. The packages have to arrive some other way, and
the way is wheels downloaded before the build, each checked against its hash in the lock.

Save the build stage as `ci/build.sh`:

```sh
# The image, built with no network. The wheels come first, each checked
# against its hash in requirements.txt; then the build, which can read only
# what this directory hands it.
set -euo pipefail
rm -rf wheels
uv venv -q --seed .build
.build/bin/pip download -q --no-deps --only-binary=:all: --require-hashes \
  -r requirements.txt -d wheels
docker build -q --network none -t "linkbox:${CI_COMMIT:-dev}" .
```

`pip download --require-hashes` fetches exactly the files the lock names, refuses any whose hash is
not in it, and `--only-binary=:all:` asks for wheels, so no package's own build script runs here.
`--no-deps` is safe because the lock already lists every dependency. The pip that downloads lives
in `.build`, a virtual environment of its own, so the project's `.venv` is not touched.

Then the Dockerfile installs from that directory and nothing else. Save it as `Dockerfile`:

```dockerfile
# Build: the pinned dependencies, installed from the wheels the pipeline
# downloaded and checked against requirements.txt. The build itself runs
# with no network, so it can read nothing it was not handed.
FROM python:3.13-slim@sha256:57b29a7c050c4e679e4bea572e14b3965cf4b5839de2da49d55e49ffc4024f39 AS build
COPY requirements.txt /
COPY wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links /wheels --require-hashes \
    --target /packages -r /requirements.txt
RUN mkdir /data

# Run: the same Python and nothing else. No shell, no package manager, no
# pip, and a user that is not root. Both images are named by digest, so a
# tag that moves upstream changes nothing here until somebody changes it.
FROM gcr.io/distroless/python3-debian13:nonroot@sha256:727eccc5d83f11273c954652667b5b5a1c66120bd4cfb884e879ab77dcdf966a
COPY --from=build /packages /packages
COPY --from=build --chown=nonroot:nonroot /data /data
COPY app.py settings.py /app/
WORKDIR /app
ENV PYTHONPATH=/packages LINKBOX_DB=/data/linkbox.db
EXPOSE 8000
ENTRYPOINT ["python3", "-m", "gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

`--no-index --find-links /wheels` means the wheels directory is the whole world as far as pip is
concerned, and `--require-hashes` checks every wheel a second time, inside the build. The second
stage is lesson 8's, unchanged apart from its digest.

Three small files follow from the new directories. Git must not track the wheels or the download
environment, as `.gitignore`:

```
.venv/
.build/
wheels/
__pycache__/
.pytest_cache/
*.db
*.pid
ci-logs/
```

Docker must not send the download environment into the build, while the wheels must go, as
`.dockerignore`:

```
.venv
.build
.git
*.db
ci-logs
```

And Bandit must not scan the packages inside `.build`, as `bandit.yaml`:

```yaml
# Bandit's settings for linkbox.
exclude_dirs:
  - .venv
  - .build
# B101 flags every assert, because Python drops them under -O. In a test an
# assert is the whole point, so it is skipped there and nowhere else.
assert_used:
  skips:
    - "*/tests/*.py"
```

### Build, commit, push

```
ana@vm:~/linkbox$ bash ci/build.sh
sha256:5166c06625b3d2996257a6f3104a23b77b5b974512b4f4bcdc97f3f11ae202ba
ana@vm:~/linkbox$ ls wheels
blinker-1.9.0-py3-none-any.whl
click-8.5.0-py3-none-any.whl
flask-3.1.3-py3-none-any.whl
gunicorn-26.2.0-py3-none-any.whl
itsdangerous-2.2.0-py3-none-any.whl
jinja2-3.1.6-py3-none-any.whl
markupsafe-3.0.4-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl
werkzeug-3.1.9-py3-none-any.whl
```

Eight wheels, one per package in the lock, and the image built from them alone. Then the commit and
the run:

```
ana@vm:~/linkbox$ git add -A
ana@vm:~/linkbox$ git status --short
M  .dockerignore
M  .gitignore
M  Dockerfile
M  bandit.yaml
M  ci/build.sh
M  ci/test.sh
A  requirements-dev.in
M  requirements-dev.txt
A  requirements.in
M  requirements.txt
ana@vm:~/linkbox$ git commit -q -m "dependencies compiled with their hashes, base images by digest, and a build with no network"
9:55AM INF 0 commits scanned.
9:55AM INF scanned ~17631 bytes (17.63 KB) in 263ms
9:55AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 0edaebf        
remote: secrets: passed in 0s        
remote: test: passed in 2s        
remote: sast: passed in 3s        
remote: sca: passed in 8s        
remote: build: passed in 2s        
remote: image: passed in 1s        
remote: push: passed in 1s        
remote: sbom: passed in 5s        
remote: sign: passed in 2s        
remote: pipeline passed with 0 warning(s)        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   f021bc5..0edaebf  main -> main
```

Every stage passed, including the scans of lesson 5 against the new lock and of lesson 8 against an
image whose base is now named by digest. The image in the registry was signed by lesson 14's stage
like every other.

### What left the image

The last check is the one lesson 13 asked for. The image has a Python and no shell, so Python itself
answers whether `packaging` is in it:

```
ana@vm:~/linkbox$ docker run --rm --entrypoint python3 linkbox:$(git rev-parse --short HEAD) -c "import importlib.util as u; print(u.find_spec(\"packaging\"), u.find_spec(\"gunicorn\").origin)"
None /packages/gunicorn/__init__.py
```

`None` for `packaging`, and gunicorn found where the first stage put it. **The image now holds what the
lock names and nothing else**, and the lock says why each package is there.
