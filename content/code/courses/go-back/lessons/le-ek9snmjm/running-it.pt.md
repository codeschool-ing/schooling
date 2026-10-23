---
title: O boxoffice num container
version: 1
---

Rode a imagem sem nada em volta:

```
ana@vm:~$ docker run --rm boxoffice:v0.16.0; echo "exit $?"
boxoffice: DATABASE_URL: not set
BOXOFFICE_MANAGER_TOKEN: not set, so no staff could sign in
exit 2
```

**A recusa da aula 14, de dentro de um container**: sem banco, sem token, status de saída 2, e o
`docker run` repassa o status. Tudo o que o boxoffice precisa de fora tem de ser entregue, e o `docker run`
tem uma flag para cada tipo:

| o boxoffice precisa | a flag | aqui |
|---|---|---|
| ser alcançável | `-p 8080:8080` | a porta 8080 do host encaminhada para a do container, onde o `BOXOFFICE_HTTP=:8080` escuta |
| o socket do banco | `-v /var/run/postgresql:/var/run/postgresql` | o diretório do socket do host montado no container, para a URL da aula 6 funcionar sem mudança |
| ser o usuário do banco | `--user "$(id -u):$(id -g)"` | a autenticação peer do PostgreSQL aceita a conexão quando o uid do processo é o seu |
| o token | `-v ~/.config/boxoffice/manager-token:/run/secrets/manager-token:ro` e `-e BOXOFFICE_MANAGER_TOKEN_FILE=…` | o arquivo da aula 14, montado só para leitura, e a variável dizendo onde ele está |
| o endereço do banco | `-e DATABASE_URL=…` | o valor do `~/.profile` |

```
ana@vm:~$ docker run -d --name boxoffice -p 8080:8080 --user "$(id -u):$(id -g)" -v /var/run/postgresql:/var/run/postgresql -v ~/.config/boxoffice/manager-token:/run/secrets/manager-token:ro -e BOXOFFICE_MANAGER_TOKEN_FILE=/run/secrets/manager-token -e DATABASE_URL="$DATABASE_URL" boxoffice:v0.16.0
3ada0d2cf0d3a143693eed29ab26d3039e5f7bc2aa2031c5e92dbbe2e28fd294
ana@vm:~$ docker logs boxoffice
{"time":"2026-10-22T23:01:17.965182027Z","level":"INFO","msg":"starting","version":"v0.16.0","config":{"http":":8080","grpc":":9090","max_conns":10,"write_timeout":"10s","origin":"https://tickets.example.com","database_url":"[hidden]","staff_tokens":1}}
{"time":"2026-10-22T23:01:17.966783473Z","level":"INFO","msg":"database: migrating: failed to initialize: failed to connect to `user= database=boxoffice`: /var/run/postgresql/.s.PGSQL.5432 (/var/run/postgresql): server error: FATAL: no PostgreSQL user name specified in startup packet (SQLSTATE 28000)"}
```

O `-d` o roda em segundo plano e imprime o id do container; o `docker logs` imprime o que ele escreveu. A
configuração chegou: `:8080`, `:9090`, um token de equipe, a versão. **Depois a conexão falhou com `user=`
vazio.** O pgx tira o usuário do banco da URL e, quando a URL não tem nenhum, do nome de usuário que o
sistema operacional dá ao uid do processo. No container esse uid é o seu, e o `/etc/passwd` da imagem
nunca ouviu falar dele, então não há nome para mandar. Mais duas coisas aparecem nessas linhas: os
timestamps terminam em `Z`, porque a imagem não tem fuso horário local e o Go cai no UTC; e a linha do
`log.Fatalf` saiu como `INFO`, porque o `slog.SetDefault` da aula 12 transforma toda chamada antiga do
`log` numa linha nesse nível.

Remova o container que falhou:

```
ana@vm:~$ docker rm boxoffice
boxoffice
```

Depois rode de novo, com o usuário nomeado na URL e o fuso horário dado ao container:

```
ana@vm:~$ docker run -d --name boxoffice -p 8080:8080 --user "$(id -u):$(id -g)" -v /var/run/postgresql:/var/run/postgresql -v ~/.config/boxoffice/manager-token:/run/secrets/manager-token:ro -e BOXOFFICE_MANAGER_TOKEN_FILE=/run/secrets/manager-token -e DATABASE_URL="postgres://$USER@/boxoffice?host=/var/run/postgresql" -e TZ=America/Sao_Paulo boxoffice:v0.16.0
6ebd15d66036cc1bb9ecc404b0ffb974d1cfee3e7794f41f1af7c346afe73af1
ana@vm:~$ curl -s localhost:8080/events/1
{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0,"available":120}
ana@vm:~$ docker logs boxoffice
{"time":"2026-10-22T20:01:20.23046045-03:00","level":"INFO","msg":"starting","version":"v0.16.0","config":{"http":":8080","grpc":":9090","max_conns":10,"write_timeout":"10s","origin":"https://tickets.example.com","database_url":"[hidden]","staff_tokens":1}}
{"time":"2026-10-22T20:01:20.241474634-03:00","level":"INFO","msg":"boxoffice listening on :8080"}
{"time":"2026-10-22T20:01:20.241614259-03:00","level":"INFO","msg":"grpc listening on 0.0.0.0:9090"}
{"time":"2026-10-22T20:01:22.259173441-03:00","level":"INFO","msg":"request","request_id":"4f9400389f45a42c","method":"GET","path":"/events/1","status":200,"bytes":73,"duration_ms":3.755}
```

Ele serve. O log é o mesmo JSON que a aula 12 desenhou, agora lido com o `docker logs`, que é onde uma
plataforma de containers o recolhe. A porta gRPC também escuta em todas as interfaces, e nada a alcança,
porque nenhum `-p` a publicou.

## Parando

```
ana@vm:~$ time docker stop boxoffice
boxoffice

real	0m0.201s
user	0m0.015s
sys	0m0.008s
```

**Um quinto de segundo.** O `docker stop` manda `SIGTERM` ao processo principal, espera até dez segundos e
então manda `SIGKILL`. O boxoffice não faz nada com o `SIGTERM`, então vale o padrão do Go e o processo
termina na hora, com as requisições em andamento cortadas no meio da resposta. É rápido, e errado para um
servidor com clientes comprando ingressos. A aula 17 faz o boxoffice terminar o que começou antes de sair.
