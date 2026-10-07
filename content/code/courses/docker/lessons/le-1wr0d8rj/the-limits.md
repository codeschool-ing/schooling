---
title: Where the trick stops working
version: 1
---

**A containerised tool sees only what it is given: the files you mount, the environment variables
you pass, the network Docker connects it to.** That is its strength, and every limit of the trick
comes from it. Each one is easy to work around once you can recognise it.

## Files outside the mount do not exist

The wrapper mounts the current directory and nothing else. A path that leaves it fails, with a
message that says the file is missing, not that it is outside the mount:

```
ana@vm:~/ops$ echo "x: 1" > ../other.yaml
ana@vm:~/ops$ yq ".x" ../other.yaml
Error: open ../other.yaml: no such file or directory
```

The file is right there, one directory up, on the host. Inside the container `../other.yaml` is
`/other.yaml`, which does not exist. **When a containerised tool says a file you can see does not
exist, check whether the path leaves the mounted directory.** The fix is to run the tool from a
directory that contains everything it needs, or to mount the other directory too.

## Every run starts a container

```
ana@vm:~/ops$ time yq --version
yq (https://github.com/mikefarah/yq/) version v4.54.1

real	0m0.318s
user	0m0.015s
sys	0m0.025s
```

**About a third of a second for `yq --version`**, almost all of it Docker setting up and tearing
down the container. Nobody notices that once. A shell loop that calls the wrapper for each of a
thousand files spends minutes on start-up alone, and there the right move is to give the tool all
the files in one run, or to install it.

## Credentials have to be handed in

The AWS command-line tool is published as an image too:

```
ana@vm:~/ops$ docker run --rm amazon/aws-cli:latest --version
aws-cli/2.37.9 Python/3.14.6 Linux/6.18.44-fc-v70 docker/x86_64.amzn.2023
```

The version came back, and nothing else will work yet: the tool looks for credentials in
`~/.aws` and in environment variables, and the container has neither. Mounting the host's
configuration read-only, `-v "$HOME/.aws":/root/.aws:ro`, or passing the variables with `-e`, makes
it work, **and also hands those credentials to whatever is in that image**. For a tool from its own
vendor's official image that is the same trust as installing it; for an image of unknown origin it
is giving your cloud account to a stranger. Lesson 20 shows how to check an image's origin. This
lesson's lab has no AWS account, so that step was not run here.

## Other things a container does not reach

- **A graphical program** needs a display, which a container does not have without extra work.
  Tools for a terminal are the ones this trick suits.
- **The host's network services** on `localhost` are the host's, not the container's: inside a
  container, `localhost` is the container itself. Lesson 23 explains, and shows how to reach the
  host when you need to.
- **On Docker Desktop, mounted files cross into a VM**, as lesson 5 drew, and a tool that reads
  thousands of small files is noticeably slower than on Linux.
