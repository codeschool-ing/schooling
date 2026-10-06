---
title: O que o Compose não faz
version: 1
---

**O Compose roda uma aplicação numa máquina, e quando essa máquina cai, a aplicação cai junto.** A aula
19 disse isso. Tudo o que vai além, várias máquinas, um container substituído quando morre, uma versão
nova entrando sem parar a antiga, é trabalho de um **orquestrador**: um programa a quem se diz o estado
que deve existir e que continua tornando esse estado verdade.

O Docker Engine tem um embutido, o **modo Swarm**, e ele é o jeito mais rápido de ver o que um
orquestrador faz, porque recebe as mesmas imagens e quase os mesmos arquivos do Compose.

## Um swarm de um só

```
ana@vm:~$ docker swarm init --advertise-addr 127.0.0.1 | head -2
Swarm initialized: current node (88ypwtcrjv74msr85cm5fv3nc) is now a manager.

ana@vm:~$ docker node ls --format "table {{.Hostname}}\t{{.Status}}\t{{.ManagerStatus}}"
HOSTNAME   STATUS    MANAGER STATUS
vm         Ready     Leader
```

**A máquina da Ana agora é um swarm com um nó, que é ao mesmo tempo o gerente e o único trabalhador.** Um
swarm de verdade acrescenta máquinas com `docker swarm join` e o token que o `init` imprime; tudo abaixo
funciona igual com mais nós, e espalha os containers entre eles.

## Um serviço, e não um container

```
ana@vm:~$ ls /proc/net/ip_vs
ls: cannot access '/proc/net/ip_vs': No such file or directory
ana@vm:~$ docker network create --driver overlay --attachable shopnet
kpi0msj33bzsrnh2hltucg2rw
ana@vm:~$ docker service create --name shelf --replicas 3 --network shopnet --endpoint-mode dnsrr --detach shelf:1.0.0
image shelf:1.0.0 could not be accessed on a registry to record
its digest. Each node will access shelf:1.0.0 independently,
possibly leading to different nodes running different
versions of the image.

6q4a1ctydh780l7f1omrygg6w
ana@vm:~$ docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"
NAME      REPLICAS   IMAGE
shelf     3/3        shelf:1.0.0
ana@vm:~$ docker service ps shelf --format "table {{.Name}}\t{{.Image}}\t{{.CurrentState}}"
NAME      IMAGE         CURRENT STATE
shelf.1   shelf:1.0.0   Running 9 seconds ago
shelf.2   shelf:1.0.0   Running 9 seconds ago
shelf.3   shelf:1.0.0   Running 9 seconds ago
ana@vm:~$ docker run --rm --network shopnet alpine:3.22 nslookup shelf | grep Address | sort
Address:	127.0.0.11:53
Address: 10.0.1.2
Address: 10.0.1.3
Address: 10.0.1.4
ana@vm:~$ docker run --rm --network shopnet alpine:3.22 wget -qO- shelf:8080/version
1.0.0
```

**Um serviço é uma descrição: esta imagem, três cópias.** O Swarm a transforma em três **tarefas**, cada
uma um container, e mantém a contagem em três. Duas coisas para ler na saída:

- **O aviso sobre o digest.** O Swarm tenta resolver a tag num digest num registry, para todo nó rodar
  os mesmos bytes, que é o argumento da aula 16 feito pela própria ferramenta. O `shelf:1.0.0` só existe
  nesta máquina, então cada nó resolveria a tag por conta própria. Um deploy de verdade nomeia uma
  imagem num registry, pelo digest.
- **O kernel do laboratório não tem IPVS**, o módulo que o Swarm usa para dar a um serviço um endereço
  virtual e para rotear uma porta publicada a qualquer nó. É isso que o primeiro comando confere. Então
  este serviço usa `--endpoint-mode dnsrr`: na rede overlay `shopnet`, o nome `shelf` responde com os
  endereços das três tarefas, e um cliente escolhe um. Num host Linux normal, o padrão, um IP virtual, e o
  `--publish 8080:8080` funcionam, e a porta responde em todo nó.

## Ele repõe o que morre

```
ana@vm:~$ docker kill $(docker ps -q --filter name=shelf.2) > /dev/null
ana@vm:~$ docker service ps shelf --format "table {{.Name}}\t{{.CurrentState}}\t{{.Error}}"
NAME          CURRENT STATE            ERROR
shelf.1       Running 25 seconds ago   
shelf.2       Running 4 seconds ago    
 \_ shelf.2   Failed 15 seconds ago    "task: non-zero exit (137)"
shelf.3       Running 25 seconds ago   
ana@vm:~$ docker service ls --format "table {{.Name}}\t{{.Replicas}}"
NAME      REPLICAS
shelf     3/3
```

**A Ana matou o container de uma tarefa, e o Swarm iniciou outro no lugar**: o `shelf.2` falhou com
código 137, o `SIGKILL` da aula 17, e um `shelf.2` novo estava rodando em segundos. Ninguém rodou
comando nenhum. O serviço dizia três, havia dois, e o gerente agiu sobre a diferença. Esse ciclo,
**estado desejado contra estado real**, é a ideia inteira de um orquestrador, o Kubernetes inclusive.
