---
title: Fazendo faxina
version: 1
---

**O Docker não apaga nada sozinho.** Toda imagem baixada, todo passo de build em cache, todo container
parado e todo volume ficam até alguém removê-los, e num notebook ou num runner de CI é assim que um
disco enche em um mês.

## Para onde foi o espaço

```
ana@vm:~$ docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          6         3         1.967GB   1.905GB (96%)
Containers      3         2         12.29kB   4.096kB (33%)
Local Volumes   2         0         39.99MB   39.99MB (100%)
Build Cache     31        0         1.575GB   8.741MB
```

O `docker system df` é o primeiro comando a rodar. As **imagens** são quase tudo aqui, 1.97 GB, e a
coluna `RECLAIMABLE` conta o que nenhum container usa. O **cache de build**, o da aula 12, é o segundo
maior. Os **volumes locais** guardam dados, e essa é a linha para ler duas vezes.

## Containers

```
ana@vm:~$ docker container prune -f
Deleted Containers:
43190281ecae32609adfd2f08e67847352f242a657aafb7a58d004007b11a59c

Total reclaimed space: 4.096kB
ana@vm:~$ docker image ls --format "{{.Repository}}:{{.Tag}}" | sort
alpine:3.22
gcr.io/distroless/static-debian12:nonroot
golang:1.25
postgres:17
shelf:1.0.0
shelf:1.0.1
```

**O `docker container prune` remove todo container parado**, aqui o `once`, que tinha rodado `echo` e
saído. Os que estão rodando nunca são tocados. Um container parado ocupa pouco disco, mas segura a
imagem dele, que aí não pode ser removida.

## Imagens

```
ana@vm:~$ docker rm -f web-old >/dev/null; docker image rm shelf:1.0.0
Untagged: shelf:1.0.0
Deleted: sha256:fe2860a0e74c3df182f423b734a85ac41c9686dc1dd730939a598061597ee387
ana@vm:~$ docker image prune -f
Total reclaimed space: 0B
```

O `docker image rm` não recusou nada aqui porque o `web-old` foi removido antes; com ele ainda lá, a
imagem estaria em uso. **O `docker image prune` sozinho só remove imagens órfãs**, as sobras sem nome de
tags reconstruídas, e não havia nenhuma. O `docker image prune -a` remove toda imagem que nenhum
container usa, inclusive a `golang:1.25` e as outras bases. Ele não foi executado aqui, porque o
próximo build baixaria tudo de novo; num runner de CI que constrói do zero de qualquer jeito, é um job
noturno comum.

## Volumes: o que perde dados

```
ana@vm:~$ docker volume ls --format "{{.Name}}"
pgdata
scratch
ana@vm:~$ docker volume prune -f
Total reclaimed space: 0B
ana@vm:~$ docker volume prune -af
Deleted Volumes:
pgdata
scratch

Total reclaimed space: 39.99MB
```

**O `docker volume prune` não removeu nada, e o `docker volume prune -a` removeu os dois volumes.**
Desde o Docker Engine 23, o `prune` sozinho só remove volumes anônimos, e o `-a` estende isso aos
nomeados que nenhum container usa. O `pgdata` guardava o banco que a Ana tinha removido um minuto
antes, mantido num volume nomeado justamente para sobreviver ao container; um banco parado também não
está usando o volume, então o `-a` o leva. **Nunca rode `docker volume prune -a` numa máquina cujos dados
você não conferiu**, e nunca num script que roda sem ninguém olhando.

## Cache de build

```
ana@vm:~$ docker builder prune -f | tail -1
Total:	30.6MB
ana@vm:~$ docker builder prune -af | tail -1
Total:	1.545GB
ana@vm:~$ docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          5         1         1.946GB   1.917GB (98%)
Containers      1         1         4.096kB   0B (0%)
Local Volumes   0         0         0B        0B
Build Cache     0         0         0B        0B
```

O `docker builder prune` sozinho removeu o cache a que nenhuma imagem se refere; **o `-a` removeu tudo,
1.5 GB**. O próximo build do `shelf` vai baixar os módulos e compilar tudo de novo, como a aula 12
mediu. Essa é a troca em todos estes comandos: disco agora contra tempo na próxima execução.

| comando | remove | risco |
| --- | --- | --- |
| `docker container prune` | containers parados | os logs e as camadas graváveis deles |
| `docker image prune` | imagens órfãs | nenhum |
| `docker image prune -a` | imagens que nenhum container usa | tempo de download |
| `docker builder prune -a` | todo o cache de build | tempo de build |
| `docker volume prune -a` | volumes que nenhum container usa | **dados** |
| `docker system prune` | containers, redes, imagens órfãs, cache | como acima; `--volumes` inclui volumes |
