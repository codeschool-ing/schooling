---
title: Docker's healthcheck, and what it does not do
version: 2
---

Docker can run a command inside a container on a schedule and record whether it passed. An
override gives `orders` one that asks `/ready`, using the Python already in the image, since the
image has no `curl`:

```
ana@obs:~/shop$ cat compose.override.yaml
services:
  orders:
    healthcheck:
      test: ["CMD", "python", "-c", "import http.client as h; c = h.HTTPConnection('localhost', 8081, timeout=3); c.request('GET', '/ready'); r = c.getresponse(); print(r.status, r.read().decode()); exit(r.status != 200)"]
      interval: 5s
      timeout: 4s
      retries: 3
      start_period: 10s
```

`interval` is how often, `timeout` how long one check may take, and `retries` how many failures in a
row make the container *unhealthy*. `start_period` is a grace time after a start in which failures
do not count, Docker's version of a startup probe. Save it as `~/shop/compose.override.yaml` and
recreate `orders` with it:

```sh
docker compose up -d orders
```

With the database up, it turns healthy:

```
ana@obs:~/shop$ docker compose ps orders --format '{{.Name}}  {{.Status}}'
shop-orders-1  Up 7 seconds (healthy)
```

Then the database is stopped:

```
ana@obs:~/shop$ docker compose stop postgres 2>&1 | tail -1
 Container shop-postgres-1 Stopped 
ana@obs:~/shop$ docker compose ps orders --format '{{.Name}}  {{.Status}}'
shop-orders-1  Up 21 seconds (unhealthy)
```

Three failures, fifteen seconds, and the status changes. Docker keeps the output of the last few
checks, so the reason is one command away:

```
ana@obs:~/shop$ docker inspect --format '{{json .State.Health}}' shop-orders-1 | jq -r '.Status, .FailingStreak, (.Log[-1].Output | sub("\\s+$"; ""))'
unhealthy
3
503 {"checks":{"postgres":"OperationalError","rabbitmq":"ok"},"ready":false}
```

**The check named the failing dependency, in the body `/ready` wrote for exactly this.** And the
last line is the surprise:

```
ana@obs:~/shop$ docker inspect --format '{{.RestartCount}}' shop-orders-1
0
```

**Docker restarts nothing for being unhealthy.** A restart policy reacts to the process exiting,
never to a failed healthcheck. Only Swarm, Docker's own orchestrator, replaces unhealthy containers.
On a single machine the status is information: `docker ps` shows it, Compose can make another
service wait for it with `depends_on` and `condition: service_healthy`, and a monitor can read it.
That is the right behaviour for a readiness check, since restarting `orders` would not bring the
database back, but it is not what people expect the first time.