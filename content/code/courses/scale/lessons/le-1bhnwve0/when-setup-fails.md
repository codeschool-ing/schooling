---
title: When the setup fails
version: 1
---

Setting up is where most people give up on a course like this, usually over one line of output
that looked like a catastrophe and was a small thing. These are the failures that come up while
following the last two sections, each with what it prints and what fixes it. **Every one of them
was produced on purpose**, on the machine the transcripts come from.

## `permission denied while trying to connect to the docker API`

The first `docker` command after installing, in the same session that ran `usermod`:

```
ana@lab:~/tickets$ docker compose up -d
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
ana@lab:~/tickets$ groups
ana
```

`groups` gives it away: the user is in the group `ana` and nothing else, so Docker's socket refuses
it. `usermod -aG docker` changed the account, but **a session reads its groups once, when it
starts**. Log out and in again, and `groups` lists `docker`. Putting `sudo` in front of every
command works too, and leaves files in `~/tickets` that belong to root, which is a second problem
later; the group is the fix.

## `address already in use`

Something else on the machine is already listening on port 8080:

```
ana@lab:~/tickets$ docker compose up -d
 Network tickets_default Creating 
 Network tickets_default Creating 
 Network tickets_default Created 
 Network tickets_default Created 
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint tickets-lb-1 (a7d4bc98cd3ba8a8a46466e58c0ef0d0a0e05b6bd344cc153b4148c7428dbd7c): failed to bind host port 127.0.0.1:8080/tcp: address already in use
ana@lab:~/tickets$ sudo ss -ltnp "sport = :8080"
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      5          127.0.0.1:8080      0.0.0.0:*    users:(("python3",pid=25519,fd=3))
```

Docker created the network and then could not publish the load balancer's port. `ss -ltnp` with a
filter on the port names the program holding it, here a Python process with its pid. Stop that
program, or change the left-hand side of `"127.0.0.1:8080:80"` in `compose.yaml` to a free port
and use that port everywhere the course says 8080. A box office left running from an earlier
lesson in another directory is the usual culprit, and `docker ps` lists it.

## `did not find expected key`

YAML reads structure from indentation, and one line of `compose.yaml` has three spaces where it
should have four:

```
ana@lab:~/tickets$ docker compose up -d
go-yaml load error in parser (while parsing a block mapping) at L3.C3-L20.C4: did not find expected key
```

The error points at a range, `L3.C3-L20.C4`, the block of lines that could not be read as one
mapping, and not at the guilty line. Inside that range, look for the line that does not line up
with its neighbours. Copying the file again with the button on its block is quicker than hunting.

## A `502 Bad Gateway` from nginx

Everything started, and the box office answers with nginx's error page:

```
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
<html>
<head><title>502 Bad Gateway</title></head>
<body>
<center><h1>502 Bad Gateway</h1></center>
<hr><center>nginx/1.27.5</center>
</body>
</html>

ana@lab:~/tickets$ docker compose logs app --no-log-prefix | tail -4
    DSN = os.environ["DATABASE_URL"]
          ~~~~~~~~~~^^^^^^^^^^^^^^^^
  File "<frozen os>", line 714, in __getitem__
KeyError: 'DATABASE_URL'
```

**502 is nginx saying that the thing behind it did not answer**, so the problem is never in nginx
itself. `docker compose logs app` shows what the box office printed before it stopped: a
`KeyError` for `DATABASE_URL`, because the variable in `compose.yaml` was misspelt as
`DATABASE_ULR` and the program found nothing under the name it asked for. Fix the name and run
`docker compose up -d` again; Compose recreates the containers whose configuration changed.

The same 502 appears for a few seconds after a restart, while the box office starts, and goes away
on its own. One that stays is a log to read.

## A build that cannot reach PyPI

`docker compose up --build` runs `pip install` inside the image, which needs to reach pypi.org.
On a network that blocks or intercepts that, a school's or a company's, the build stops at step
`[4/5]` with an error naming the address it could not reach or a certificate it did not trust.
There is no fix inside the course for a network you do not control: build once on a network that
works, and the image stays on the machine; later lessons rebuild only when `app.py` or
`requirements.txt` changes.

## Numbers very different from the ones printed

Your load test sells 60 tickets a second where the lesson printed about 120, or 300 where it
printed 140. **That is not a failure.** The numbers are a property of the machine, and yours is a
different machine. What the lessons argue from is the **shape**: how the number changes when a
processor or a copy is added. If the shape matches, the lesson works. If it does not, `docker
stats` in a second terminal while the test runs shows which container is busy, which is the first
question of section 06.
