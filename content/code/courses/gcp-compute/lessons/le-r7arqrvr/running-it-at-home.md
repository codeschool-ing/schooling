---
title: Running it at home under the same contract
version: 1
---

The image from the last section is the one Cloud Run would run. **Started with `docker run` and
given a `PORT`, it behaves on your laptop as the contract says it will behave there**, which makes
the laptop the cheapest place to find out whether it keeps the contract at all. Every command in
this section runs from `~/gcp`.

## Answering

Start it in the background with the variable Cloud Run would set, and ask it something:

```
ana@laptop:~/gcp$ docker run -d --name orders -p 8080:8080 -e PORT=8080 orders:1
f71358e76cb6429f08b96a9599efb2a90b7663a02383feab47162de6317f58ca
ana@laptop:~/gcp$ curl -s localhost:8080/orders; echo
{"orders": [{"id": 1001, "item": "notebook", "quantity": 2}, {"id": 1002, "item": "pencil", "quantity": 12}], "revision": "local"}
ana@laptop:~/gcp$ curl -s localhost:8080/health; echo
{"status": "ok"}
ana@laptop:~/gcp$ curl -s -i localhost:8080/nothing; echo
HTTP/1.0 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.13
Date: Fri, 30 Oct 2026 18:27:19 GMT
Content-Type: application/json
Content-Length: 22

{"error": "not found"}
```

**`-p 8080:8080` stands in for Cloud Run's front end**: it carries requests from the laptop's port
to the container's, the way Google's front end carries them from the public HTTPS address to
`PORT`. The `404` came from the program, with a JSON body, which is the behaviour a client of a
real API expects; Cloud Run would pass it through unchanged.

Now the part of the contract most programs skip. Cloud Run is free to send a different port, so
start a second copy on 9090 and read its first log line:

```
ana@laptop:~/gcp$ docker run -d --name orders-9090 -p 9090:9090 -e PORT=9090 orders:1
af1f8ce7b68352110f279c2fc21741f46756e713417a54937f09619265ab2aa6
ana@laptop:~/gcp$ curl -s localhost:9090/health; echo
{"status": "ok"}
ana@laptop:~/gcp$ docker logs orders-9090
{"severity": "INFO", "message": "listening on 9090"}
{"severity": "INFO", "message": "\"GET /health HTTP/1.1\" 200 -"}
```

**The program listened where it was told**, and its log line says so in the JSON that Cloud
Logging would file as an `INFO` entry. The request log is the same shape.

## Two ways to break the contract

The first is the most common bug in a first Cloud Run deployment: a server that listens on the
loopback address only. Python's own `http.server` makes it easy to try:

```
ana@laptop:~/gcp$ docker run -d --name orders-local -p 8081:8081 orders:1 python3 -m http.server --bind 127.0.0.1 8081
f24c210cd3d194e45725958bc2f327fbbb197d678f9a6bfd22ef0abc45c4c2a2
ana@laptop:~/gcp$ curl -sS localhost:8081/; echo "exit status $?"
curl: (56) Recv failure: Connection reset by peer
exit status 56
```

**The container is running and its server is up, and nothing outside the container can reach
it.** Docker accepted the connection on the laptop's port and found nobody listening on the
container's outside interface, so the connection was reset. On Cloud Run the same image starts,
fails its startup probe because the port never answers from outside, and the deployment is
reported as failed with a message about the container not listening on `PORT`. The fix is one
word, `0.0.0.0`, and the orders service already has it.

The second is about stopping. Stop the orders service and time it:

```
ana@laptop:~/gcp$ time docker stop orders
orders

real	0m0.251s
user	0m0.010s
sys	0m0.022s
ana@laptop:~/gcp$ docker logs orders
{"severity": "INFO", "message": "listening on 8080"}
{"severity": "INFO", "message": "\"GET /orders HTTP/1.1\" 200 -"}
{"severity": "INFO", "message": "\"GET /health HTTP/1.1\" 200 -"}
{"severity": "INFO", "message": "\"GET /nothing HTTP/1.1\" 404 -"}
{"severity": "INFO", "message": "SIGTERM: shutting down"}
```

**A fraction of a second, and the last log line is the program's own**: Docker sent `SIGTERM`,
the handler logged it and exited. Now run the same image with the command written in the shell
form, so that `sh` starts first and `python3` runs under it:

```
ana@laptop:~/gcp$ docker run -d --name orders-sh -p 8080:8080 orders:1 sh -c 'python3 app.py'
8703e2ee0117a1fe9ff9920db4de53ab6434ff81eee7ca1260057e22bbb65246
ana@laptop:~/gcp$ time docker stop orders-sh
orders-sh

real	0m10.223s
user	0m0.014s
sys	0m0.019s
ana@laptop:~/gcp$ docker inspect orders-sh --format "{{.State.ExitCode}}"
137
```

**Ten seconds, and exit code 137**, which is 128 plus 9, the number of `SIGKILL`. `sh` was the
container's first process and received `SIGTERM`; as process 1 it ignores the signal and does
not pass it on, so Python never heard it, and Docker killed both when its ten seconds ran out.
Cloud Run gives a stopping instance the same ten seconds and then does the same thing. A request
in flight at that moment is cut off rather than finished, on every scale-in, which is why the
`CMD` of the last section is a list.

## Cleaning up

The containers stopped above are still listed by `docker ps -a`; remove them, and the two still
running, before the next lesson:

```sh
docker rm -f orders orders-sh orders-local orders-9090
```

The image `orders:1` stays: lessons 9 to 11 use it.
