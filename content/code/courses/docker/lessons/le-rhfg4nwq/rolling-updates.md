---
title: Rolling updates and rollback
version: 1
---

**Deploying a new version to an orchestrator means changing the description and letting it converge.**
How it converges is configurable, and the useful setting replaces one task at a time:

```
ana@vm:~$ docker service update --image shelf:1.0.1 --update-parallelism 1 --update-delay 5s --detach shelf
shelf
ana@vm:~$ docker service ps shelf --filter desired-state=running --format "table {{.Name}}\t{{.Image}}\t{{.CurrentState}}"
NAME      IMAGE         CURRENT STATE
shelf.1   shelf:1.0.0   Running 33 seconds ago
shelf.2   shelf:1.0.0   Running 12 seconds ago
shelf.3   shelf:1.0.1   Starting 4 seconds ago
ana@vm:~$ docker service ps shelf --filter desired-state=running --format "table {{.Name}}\t{{.Image}}\t{{.CurrentState}}"
NAME      IMAGE         CURRENT STATE
shelf.1   shelf:1.0.1   Running 25 seconds ago
shelf.2   shelf:1.0.1   Running 12 seconds ago
shelf.3   shelf:1.0.1   Running 39 seconds ago
ana@vm:~$ docker run --rm --network shopnet alpine:3.22 wget -qO- shelf:8080/version
1.0.1
```

**Eight seconds in, one task runs 1.0.1 and two still run 1.0.0; forty seconds later, all three run
1.0.1.** `--update-parallelism 1` replaces one task at a time and `--update-delay 5s` waits between
them. Because the image has a health check (lesson 18), Swarm waits for each new task to be healthy
before moving on, so a version that does not start stops the rollout after the first task instead of
the last. The service answered throughout, from whichever tasks were running.

## Going back

```
ana@vm:~$ docker service rollback --detach shelf
shelf
ana@vm:~$ docker service inspect shelf --format "{{.Spec.TaskTemplate.ContainerSpec.Image}}"
shelf:1.0.0
ana@vm:~$ docker run --rm --network shopnet alpine:3.22 wget -qO- shelf:8080/version
1.0.0
```

**`docker service rollback` returns the service to the description it had before the last update**,
`shelf:1.0.0`, and rolls it out the same careful way. Swarm can do this by itself, too:
`--update-failure-action rollback` reverts an update whose new tasks fail.

## The same Compose file, with a `deploy` section

Compose files describe services, and Swarm reads them with `docker stack deploy`. The `deploy` key,
which plain Compose reads only in part, is where the orchestrator's settings go:

```yaml
services:
  web:
    image: shelf:1.0.1
    networks:
      - shopnet
    deploy:
      replicas: 2
      endpoint_mode: dnsrr
      update_config:
        parallelism: 1
        delay: 5s
        failure_action: rollback
      resources:
        limits:
          memory: 64M

networks:
  shopnet:
    external: true
```

```
ana@vm:~$ docker stack deploy -c shelf/stack.yaml --detach=true shop 2>&1
Creating service shop_web
ana@vm:~$ docker stack services shop --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"
NAME       REPLICAS   IMAGE
shop_web   2/2        shelf:1.0.1
ana@vm:~$ docker run --rm --network shopnet alpine:3.22 wget -qO- shop_web:8080/version
1.0.1
ana@vm:~$ docker stack rm shop
Removing service shop_web
ana@vm:~$ docker swarm leave --force
Node left the swarm.
```

**A stack is a group of services from one file**, named after the stack, `shop_web` here, and removed
together. Replicas, the update policy, the rollback on failure and a memory limit (lesson 17) are all in
the file, reviewed like any other change.
