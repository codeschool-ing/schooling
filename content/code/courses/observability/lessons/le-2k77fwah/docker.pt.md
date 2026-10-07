---
title: O healthcheck do Docker, e o que ele não faz
version: 2
---

O Docker consegue rodar um comando dentro de um contêiner num horário e registrar se ele passou. Um
override dá ao `orders` um que pergunta ao `/ready`, usando o Python que já está na imagem, já que a
imagem não tem `curl`:

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

`interval` é a frequência, `timeout` quanto uma verificação pode levar, e `retries` quantas falhas
seguidas deixam o contêiner *unhealthy*. `start_period` é um tempo de tolerância depois de um início
em que as falhas não contam, a versão do Docker de uma sonda de startup. Salve-o como
`~/shop/compose.override.yaml` e recrie o `orders` com ele:

```sh
docker compose up -d orders
```

Com o banco no ar, ele fica saudável:

```
ana@obs:~/shop$ docker compose ps orders --format '{{.Name}}  {{.Status}}'
shop-orders-1  Up 7 seconds (healthy)
```

Então o banco é parado:

```
ana@obs:~/shop$ docker compose stop postgres 2>&1 | tail -1
 Container shop-postgres-1 Stopped 
ana@obs:~/shop$ docker compose ps orders --format '{{.Name}}  {{.Status}}'
shop-orders-1  Up 21 seconds (unhealthy)
```

Três falhas, quinze segundos, e o status muda. O Docker guarda a saída das últimas verificações, então
o motivo está a um comando de distância:

```
ana@obs:~/shop$ docker inspect --format '{{json .State.Health}}' shop-orders-1 | jq -r '.Status, .FailingStreak, (.Log[-1].Output | sub("\\s+$"; ""))'
unhealthy
3
503 {"checks":{"postgres":"OperationalError","rabbitmq":"ok"},"ready":false}
```

**A verificação nomeou a dependência com falha, no corpo que o `/ready` escreveu exatamente para
isso.** E a última linha é a surpresa:

```
ana@obs:~/shop$ docker inspect --format '{{.RestartCount}}' shop-orders-1
0
```

**O Docker não reinicia nada por estar unhealthy.** Uma política de reinício reage ao processo
terminar, nunca a um healthcheck que falhou. Só o Swarm, o orquestrador do próprio Docker, troca
contêineres unhealthy. Numa máquina só, o status é informação: o `docker ps` o mostra, o Compose
pode fazer outro serviço esperar por ele com `depends_on` e `condition: service_healthy`, e um
monitor pode lê-lo. Esse é o comportamento certo para uma verificação de readiness, já que reiniciar
o `orders` não traria o banco de volta, mas não é o que as pessoas esperam da primeira vez.