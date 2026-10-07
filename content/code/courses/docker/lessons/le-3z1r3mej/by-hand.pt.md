---
title: Dois containers à mão
version: 1
---

**O `shelf` com um banco de verdade são dois containers que precisam se achar, iniciar na ordem certa
e guardar os dados.** Cada parte é algo que aulas anteriores fizeram; juntas, à mão, ficam assim:

```
ana@vm:~/shelf$ docker network create shelfnet
3ca58f4d539bce1ca0ce6d315e92dbf8cc658669448aa646665d11bf03717415
ana@vm:~/shelf$ docker run -d --name db --network shelfnet -e POSTGRES_USER=shelf -e POSTGRES_PASSWORD=lab-only-secret -e POSTGRES_DB=shelf postgres:17
b9a88b7db427e3fe1d748c9aecdc41539160285ad52410ac719e6ee95e1538b1
ana@vm:~/shelf$ docker run -d --name web --network shelfnet -p 127.0.0.1:8080:8080 -e DATABASE_URL=postgres://shelf:lab-only-secret@db:5432/shelf shelf:1.5.0
5707d575fe31820afea04956e985beceea6c8efd0065bb40661074a3ac414f52
ana@vm:~/shelf$ docker logs web
2026/10/06 18:12:12 database: failed to connect to `user=shelf database=shelf`:
	172.18.0.2:5432 (db): dial error: dial tcp 172.18.0.2:5432: connect: connection refused
	172.18.0.2:5432 (db): dial error: dial tcp 172.18.0.2:5432: connect: connection refused
ana@vm:~/shelf$ docker start web
web
ana@vm:~/shelf$ curl -s localhost:8080/books | jq -c ".[]"
{"id":1,"title":"The Left Hand of Darkness","author":"Ursula K. Le Guin"}
{"id":2,"title":"Dom Casmurro","author":"Machado de Assis"}
{"id":3,"title":"The Remains of the Day","author":"Kazuo Ishiguro"}
```

Três comandos, e o terceiro falhou. **`connection refused`: o `shelf` iniciou enquanto o Postgres ainda
inicializava o banco**, e a aula 17 mostrou que o `shelf` sai quando não alcança o banco. Alguns
segundos depois, o `docker start web` funcionou e o catálogo veio do Postgres, que criou e preencheu a
tabela no primeiro uso.

O primeiro comando criou uma **rede**, `shelfnet`, e os dois containers entraram nela. Numa rede que
alguém criou, containers se acham pelo nome: é por isso que o `db` no `DATABASE_URL` funciona. A aula
23 explica como. Repare também no que falta: nenhum `-p` no banco, então nada fora da rede o alcança.

## O que há de errado em fazer assim

- **A ordem é sorte.** Esperar alguns segundos funcionou na máquina da Ana hoje. Num disco mais lento,
  ou num banco restaurando um backup, não vai funcionar.
- **A montagem mora no histórico do shell de alguém.** A próxima pessoa a rodar o `shelf` precisa achar
  esses três comandos, com as flags, e digitá-los do mesmo jeito.
- **A senha está na linha de comando**, no arquivo de histórico e na lista de processos, como a aula 17
  avisou.
- **Desmontar tudo são mais quatro comandos**, e esquecer um deixa uma rede ou um volume para trás.

**O Docker Compose resolve os quatro**: os containers, a rede, os volumes e a ordem escritos num
arquivo, guardado no repositório ao lado do Dockerfile, e um comando para subir ou derrubar tudo.
