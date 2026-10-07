---
title: One machine, one file
version: 1
---

**A common picture of this course is that Kubernetes replaces Docker, as if Compose had been a
toy.** It is not one. For an application that lives on one machine, Compose does the job well, and
this lesson starts by watching it do so. What Kubernetes adds only makes sense once you have seen
where one machine stops.

Ana's shop is one service: the image `shop:1.0` from the previous section. The whole description of
how it runs is six lines, in `~/shop/compose.yaml`:

```yaml
services:
  web:
    image: shop:1.0
    ports:
      - "8080:8080"
    restart: always
```

`image` names what runs, `ports` publishes the container's port 8080 on the laptop's port 8080, and
`restart: always` tells the Docker daemon to start the container again whenever it stops. One
command brings it up:

```
ana@laptop:~/shop$ docker compose up -d
 Network shop_default Creating 
 Network shop_default Creating 
 Network shop_default Created 
 Network shop_default Created 
 Container shop-web-1 Creating 
 Container shop-web-1 Created 
 Container shop-web-1 Starting 
 Container shop-web-1 Started 
ana@laptop:~/shop$ curl -s localhost:8080
shop 1.0 on 7f1b64994482
ana@laptop:~/shop$ docker compose ps --format "table {{.Name}}\t{{.Image}}\t{{.Status}}"
NAME         IMAGE      STATUS
shop-web-1   shop:1.0   Up 2 seconds
```

The answer names the container's hostname, `7f1b64994482`, which is the start of its id. That will
matter in a moment, because it changes when the container is replaced.

## A crash is handled

The first thing an operator worries about is a process that dies. Here it is killed the hard way,
with `SIGKILL`, which no program can catch or clean up after:

```
ana@laptop:~/shop$ sudo kill -9 $(docker inspect -f "{{.State.Pid}}" shop-web-1)
ana@laptop:~/shop$ docker inspect -f "{{.RestartCount}} restart(s), running: {{.State.Running}}" shop-web-1
1 restart(s), running: true
```

**The restart policy brought it back, and nobody had to notice.** The daemon saw the process exit,
read `restart: always`, and started the container again. That is supervision, and on one machine it
is most of what you want: the same thing `systemd` does for a service, applied to a container.

## A second copy is refused

The second worry is load. One process on one port serves as many requests as one process can, so
the obvious move is to run three:

```
ana@laptop:~/shop$ docker compose up -d --scale web=3
 Container shop-web-1 Running 
 Container shop-web-3 Creating 
 Container shop-web-2 Creating 
 Container shop-web-3 Created 
 Container shop-web-2 Created 
 Container shop-web-3 Starting 
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint shop-web-3 (500b23a17f0fc16b32dec5866dae4c752bce1634a13b1c62102aec76ac39cf59): Bind for 0.0.0.0:8080 failed: port is already allocated
```

**Two containers cannot both own port 8080 of the same machine.** The first copy has it, the third
asked for it and was refused, and Compose stopped there with one replica running and two created
and stopped. On one machine the way out is to publish no port on the copies and put a proxy in
front of them, which is a second service you now configure, health-check and keep in step with the
first by hand.

## And the machine is the limit

Nothing above can survive the laptop itself going away. The restart policy is a rule kept by the
Docker daemon **on that machine**; if the machine loses power, the daemon, the policy and the
containers go together, and nothing anywhere knows that a shop should be running. No capture shows
that here, because there is no second machine to watch it from. That missing second machine is the
subject of the rest of this course.
