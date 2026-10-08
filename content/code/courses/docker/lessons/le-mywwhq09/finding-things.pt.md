---
title: Achando as coisas
version: 2
---

**Uma máquina que rodou Docker por uma semana tem mais containers, imagens e volumes do que alguém
lembra de ter iniciado.** Três hábitos deixam isso administrável: filtrar em vez de rolar a tela,
formatar em vez de ler tabelas inteiras, e perguntar ao comando certo pelo campo que você quer.

As transcrições desta aula leem uma máquina com um pouco de história: duas versões do `shelf`,
construídas a partir do Dockerfile da aula 15, alguns containers, um deles encerrado, um volume que
ninguém usa e algum cache de build. Para deixar a sua igual, rode isto antes:

```sh
cd ~/shelf
docker build -q --build-arg VERSION=1.0.0 -t shelf:1.0.0 .
docker build -q --build-arg VERSION=1.0.1 -t shelf:1.0.1 .
cd ~
docker run -d --name web -p 127.0.0.1:8080:8080 shelf:1.0.1
docker run -d --name web-old shelf:1.0.0
docker run --name once alpine:3.22 echo done
docker run -d --name db -e POSTGRES_PASSWORD=lab-only -v pgdata:/var/lib/postgresql/data postgres:17
docker volume create scratch
sleep 4; docker rm -f db
```

## `ps` com filtros e formato

```
ana@vm:~$ docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
NAMES     IMAGE         STATUS
once      alpine:3.22   Exited (0) 4 seconds ago
web-old   shelf:1.0.0   Up 4 seconds
web       shelf:1.0.1   Up 5 seconds
ana@vm:~$ docker ps -a --filter status=exited --format "{{.Names}}"
once
ana@vm:~$ docker ps --filter ancestor=shelf:1.0.0 --format "{{.Names}}"
web-old
ana@vm:~$ docker ps -q
84626c4c1aa9
b0176fabef01
```

**O `--format` com um template Go escolhe as colunas**, a mesma sintaxe do `docker inspect --format`
desde a aula 3. O `--filter` estreita as linhas: `status=exited` para o que parou, `ancestor=` para
todo container iniciado a partir de uma imagem, que é a pergunta a fazer antes de apagar uma. **O `-q`
imprime só ids**, um por linha, que é o que outros comandos recebem como entrada: `docker rm $(docker ps
-aq --filter status=exited)` remove exatamente os parados.

## `inspect` para um campo

```
ana@vm:~$ docker inspect web --format "{{.State.Status}} since {{.State.StartedAt}}"
running since 2026-10-06T20:41:29.902926698Z
ana@vm:~$ docker inspect web --format "{{json .NetworkSettings.Ports}}" | jq -c
{"8080/tcp":[{"HostIp":"127.0.0.1","HostPort":"8080"}]}
ana@vm:~$ docker inspect web --format "{{.Config.User}} {{json .Config.Cmd}}"
65532:65532 ["/shelf"]
```

O `docker inspect` imprime tudo o que o Docker sabe sobre um objeto como JSON, centenas de linhas. **O
`--format` com um caminho escolhe um campo**, e o `{{json …}}` mantém uma estrutura como JSON para o
`jq`. Os três acima respondem a perguntas de todo dia: desde quando ele roda, onde está publicado, e com
que usuário e comando ele roda. O `StartedAt` está em UTC, seja qual for o fuso da máquina.

## `logs` e as duas saídas

```
ana@vm:~$ docker logs --timestamps --tail 2 web
2026-10-06T20:41:30.030172671Z 2026/10/06 20:41:30 catalogue: built in, 3 books
2026-10-06T20:41:30.031007731Z 2026/10/06 20:41:30 shelf 1.0.1 listening on :8080
ana@vm:~$ docker logs --since 1h web | wc -l
2026/10/06 20:41:30 catalogue: built in, 3 books
2026/10/06 20:41:30 shelf 1.0.1 listening on :8080
0
ana@vm:~$ docker logs --since 1h web 2>&1 | wc -l
2
```

O `--timestamps` põe na frente de cada linha a hora em que o daemon a recebeu, e o `--tail` e o
`--since` cortam o histórico. **E a contagem dá 0, depois 2.** O `docker logs` reproduz a saída padrão
de um container na saída padrão e a saída de erro na saída de erro, e o pacote `log` do Go, que o
`shelf` usa, escreve na saída de erro. Então as linhas passaram direto pelo `wc` até o terminal. O
`2>&1` junta as duas antes do pipe; qualquer `grep` no log de um container precisa dele pelo mesmo
motivo.
