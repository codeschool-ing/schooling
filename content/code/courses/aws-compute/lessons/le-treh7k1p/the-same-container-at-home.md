---
title: "The same container, run at home"
version: 1
---

Nothing in moto runs a container, so a lesson about ECS against moto alone would teach the
paperwork and never the thing. **What a task does on an instance is start containers through
Docker, with the settings the task definition names**, and Docker is on your machine already.
This section runs the container of `web.json` for real, with the same image and the same settings,
and is the one part of the lesson where something serves a page.

## Once: Docker and the image

The `docker` course installs Docker Engine on Ubuntu and adds your user to the `docker` group, and
this section assumes that. The image comes from Docker Hub and is pulled once:

```sh
docker pull nginx:1.29-alpine
```

Once it is there, it takes this much of your disk:

```
ana@laptop:~/aws$ docker image ls nginx:1.29-alpine --format "{{.Repository}}:{{.Tag}}  {{.Size}}"
nginx:1.29-alpine  93.5MB
```

If `docker ps` answers with a permission error, your user is not in the `docker` group yet, or the
terminal was opened before it was; the `docker` course's setup lesson covers both. moto does not
need to be running for anything in this section.

## From the definition to the command

Each field of the container definition is a flag of `docker run`. The ECS agent makes the same
translation, through Docker's API rather than its command line:

| in `web.json` | on the command line |
|---|---|
| `"image": "nginx:1.29-alpine"` | the image, last |
| `"name": "web"` | `--name web` |
| `"portMappings"`, 8080 to 80 | `-p 8080:80` |
| `"environment"`, `SHOP_ENV` | `-e SHOP_ENV=staging` |
| `"cpu": 256` | `--cpu-shares 256` |
| `"memory": 512` | `--memory 512m` |
| `"logConfiguration"`, `awslogs` | nothing here: Docker keeps the logs itself |

The last row is the one real difference. On ECS the `awslogs` driver ships the output to
CloudWatch Logs with the execution role's permission; here Docker's default driver keeps it on
the machine, and `docker logs` reads it back.

```
ana@laptop:~/aws$ docker run -d --name web -p 8080:80 -e SHOP_ENV=staging --cpu-shares 256 --memory 512m nginx:1.29-alpine | cut -c1-12
43b7274123fe
ana@laptop:~/aws$ docker ps --format "{{.Names}}  {{.Image}}  {{.Ports}}"
web  nginx:1.29-alpine  0.0.0.0:8080->80/tcp
ana@laptop:~/aws$ curl -s localhost:8080 | grep -o "<title>.*</title>"
<title>Welcome to nginx!</title>
```

That is nginx, answering on the host's port 8080 exactly as the task would on its instance's.

## The settings, read back

```
ana@laptop:~/aws$ docker exec web printenv SHOP_ENV
staging
ana@laptop:~/aws$ docker inspect --format "{{.HostConfig.CpuShares}} {{.HostConfig.Memory}}" web
256 536870912
ana@laptop:~/aws$ docker logs web 2>/dev/null | tail -1 | cut -c1-80
172.17.0.1 - - [16/Oct/2026:16:30:29 +0000] "GET / HTTP/1.1" 200 896 "-" "curl/8
```

The environment variable is inside the container, the CPU weight is 256, and the memory limit is
536,870,912 bytes, which is 512 MiB. **`--cpu-shares` is a weight, not a cap**: with nothing else
running, this container may use every processor on the machine, and only when containers compete
does 256 against another's 1,024 give it a fifth of the time. That is also how the agent applies a
container's `cpu` on EC2. **Memory is the opposite, a hard limit**: past 512 MiB the kernel kills
the process, and on ECS the task stops with an out-of-memory reason. The last line is nginx's
access log for the `curl` above; on ECS that line would be in the log group `/ecs/web`.

## The port, a second time

The cluster in the previous section refused a second copy of this task on one instance. Docker
refuses it for the same reason:

```
ana@laptop:~/aws$ docker run -d --name web2 -p 8080:80 nginx:1.29-alpine > /dev/null
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint web2 (1a4ab521564d7986e218161edbfcdf7e0facc91e4e61ae6f44b3b5bee3e6fc83): Bind for 0.0.0.0:8080 failed: port is already allocated

Run 'docker run --help' for more information
ana@laptop:~/aws$ docker ps -a --filter name=web2 --format "{{.Names}}  {{.Status}}"
web2  Created
```

**This is the failure moto would not show.** The second container was created and never started,
because the host's port 8080 was already bound by the first. ECS sees it coming and does not try,
which is the `RESOURCE:PORTS` reason, and on your laptop you see what it would have been.

## Stopping it

```
ana@laptop:~/aws$ docker stop web
web
ana@laptop:~/aws$ docker ps -a --filter name=web --format "{{.Names}}  {{.Status}}"
web2  Created
web  Exited (0) Less than a second ago
```

`docker stop` sends the container's main process `SIGTERM` and, if it is still running after a
grace period, `SIGKILL`. Stopping an ECS task does the same thing to each container, waiting 30
seconds by default before the kill, which is the container definition's `stopTimeout` and lesson
9's subject when Fargate Spot takes a task back. nginx exited at once with status 0, a clean
shutdown. Because `web` is the task's essential container, its exit would have stopped the task,
and a service would now be starting a new one. Nothing here starts a new one; `docker rm web web2`
cleans both up.
