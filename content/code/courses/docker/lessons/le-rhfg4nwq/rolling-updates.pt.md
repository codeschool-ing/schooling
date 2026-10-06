---
title: Atualizações graduais e rollback
version: 1
---

**Fazer deploy de uma versão nova num orquestrador é mudar a descrição e deixá-lo convergir.** Como ele
converge é configurável, e o ajuste útil troca uma tarefa de cada vez:

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

**Oito segundos depois, uma tarefa roda a 1.0.1 e duas ainda rodam a 1.0.0; quarenta segundos depois, as
três rodam a 1.0.1.** O `--update-parallelism 1` troca uma tarefa de cada vez e o `--update-delay 5s`
espera entre elas. Como a imagem tem health check (aula 18), o Swarm espera cada tarefa nova ficar
saudável antes de seguir, então uma versão que não inicia para a atualização depois da primeira tarefa,
e não da última. O serviço respondeu o tempo todo, pelas tarefas que estivessem rodando.

## Voltando atrás

```
ana@vm:~$ docker service rollback --detach shelf
shelf
ana@vm:~$ docker service inspect shelf --format "{{.Spec.TaskTemplate.ContainerSpec.Image}}"
shelf:1.0.0
ana@vm:~$ docker run --rm --network shopnet alpine:3.22 wget -qO- shelf:8080/version
1.0.0
```

**O `docker service rollback` devolve o serviço à descrição que ele tinha antes da última atualização**,
`shelf:1.0.0`, e a aplica do mesmo jeito cuidadoso. O Swarm também consegue fazer isso sozinho: o
`--update-failure-action rollback` desfaz uma atualização cujas tarefas novas falham.

## O mesmo arquivo do Compose, com uma seção `deploy`

Arquivos do Compose descrevem serviços, e o Swarm os lê com `docker stack deploy`. A chave `deploy`,
que o Compose comum só lê em parte, é onde ficam os ajustes do orquestrador:

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

**Uma stack é um grupo de serviços de um arquivo**, com o nome da stack, `shop_web` aqui, e removidos
juntos. Réplicas, a política de atualização, o rollback em caso de falha e um limite de memória (aula 17)
estão todos no arquivo, revisados como qualquer outra mudança.
