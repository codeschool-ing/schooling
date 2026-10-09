---
title: Getting the code there, and packaging it
version: 2
---

The server gets the code the same way anybody else would: through git. A **bare repository** on srv, one
with no working files, receives the push, and a clone beside it is what gets built:

```
ana@srv:~$ git init -q --bare -b main loanbook.git
ana@laptop:~/loanbook$ git remote add srv srv:loanbook.git
ana@laptop:~/loanbook$ git push -q srv main --tags
ana@srv:~$ git clone -q loanbook.git && git -C loanbook log --oneline -1
c40ef55 License under MIT
ana@laptop:~/loanbook$ git log --oneline -1
c40ef55 License under MIT
```

`-b main` names the bare repository's first branch: srv's git has never been told the default, and a
repository whose `HEAD` names a branch nobody pushed clones into nothing. The clone on srv is at
`c40ef55`, the same commit as laptop's `main`. That line is worth checking every time: **the most
common deploy bug is deploying something other than what you think.**

Then the package. A container image holds the code, its runtime and its settings, so the server needs
Podman and nothing else: no Python version to match, no packages to install. loanbook's recipe is eight
lines, and Podman builds it one step at a time:

```
ana@srv:~/loanbook$ cat Containerfile
FROM docker.io/library/python:3.12-slim
WORKDIR /app
COPY app.py seed.py ./
COPY static ./static
ENV LOANBOOK_DB=/data/loanbook.db LOANBOOK_PORT=8000
USER 1000
EXPOSE 8000
CMD ["python3", "app.py"]
ana@srv:~/loanbook$ sudo podman build -t loanbook .
STEP 1/8: FROM docker.io/library/python:3.12-slim
STEP 2/8: WORKDIR /app
--> 50bdc62e40b6
STEP 3/8: COPY app.py seed.py ./
--> 7e8f4e13c7d5
STEP 4/8: COPY static ./static
--> 071206b037d8
STEP 5/8: ENV LOANBOOK_DB=/data/loanbook.db LOANBOOK_PORT=8000
--> 3addbf254a5b
STEP 6/8: USER 1000
--> d8e1a05e372d
STEP 7/8: EXPOSE 8000
--> 82452a065492
STEP 8/8: CMD ["python3", "app.py"]
COMMIT loanbook
--> 008db3c598f0
Successfully tagged localhost/loanbook:latest
008db3c598f02dd8375e025d2997af35d65697f8ef4415e5a570434fc60a7059
```

Read the recipe from the top. It starts from Python's official slim image, copies in only what runs,
`app.py`, `seed.py` and the page, and **not** the tests, the README or the `.git` directory. It sets
the two variables of lesson 14, putting the database in `/data`, and then `USER 1000`: the program runs
as an ordinary user inside the container, so a bug in it cannot act as root. Each `-->` is a layer; the
last line is the finished image's ID.
