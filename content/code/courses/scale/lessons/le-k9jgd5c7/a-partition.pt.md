---
title: Uma partição, causada de propósito
version: 1
---

Para ver a escolha da seção 02 acontecer, a réplica precisa ser cortada do primário **enquanto os
clientes ainda alcançam os dois**. Uma rede só não consegue isso: a réplica chegaria ao primário
pelo mesmo caminho que todo mundo. Então o `compose.yaml` desta aula dá à replicação uma rede
própria. Aqui está o arquivo inteiro:

```yaml
# compose.yaml
services:
  db:
    image: postgres:16.15
    environment:
      POSTGRES_USER: tickets
      POSTGRES_PASSWORD: tickets
      POSTGRES_DB: tickets
    volumes:
      - ./schema.sql:/docker-entrypoint-initdb.d/1-schema.sql:ro
      - ./replication.sh:/docker-entrypoint-initdb.d/2-replication.sh:ro
    networks:
      default:
      replication:
        aliases: [primary]
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "tickets"]
      interval: 2s
      retries: 15

  replica:
    image: postgres:16.15
    user: postgres
    environment:
      PGPASSWORD: replicator
      PGDATA: /var/lib/postgresql/replica
      DELAY: ${DELAY:-0}
    command:
      - bash
      - -c
      - |
        until pg_basebackup -h primary -U replicator -D "$$PGDATA" -R -X stream; do sleep 1; done
        exec postgres -c recovery_min_apply_delay="$$DELAY"
    networks:
      - default
      - replication
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "tickets"]
      interval: 2s
      retries: 15
    depends_on:
      db:
        condition: service_healthy

  app:
    build: .
    environment:
      DATABASE_URL: postgresql://tickets:tickets@db/tickets
      REPLICA_URL: postgresql://tickets:tickets@replica/tickets
    cpus: 1
    depends_on:
      db:
        condition: service_healthy
      replica:
        condition: service_healthy

  lb:
    image: nginx:1.27.5
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "127.0.0.1:8080:80"
    depends_on:
      - app

networks:
  replication:
```

Três mudanças em relação à aula 2:

- uma segunda rede, **`replication`**, declarada no fim;
- o **`db`** entra nela com um segundo nome, `primary`, que só existe nessa rede;
- a **`replica`** entra nas duas, e copia e segue o `primary` em vez do `db`.

Então a réplica fala com o primário só pela `replication`, e com a bilheteria pela `default`. Tirar
a réplica da `replication` é uma partição entre os dois bancos que deixa intacto o caminho de todo
cliente. Reinicie a pilha com o arquivo novo antes de seguir: `docker compose down`, depois
`docker compose up -d`.

## Com uma réplica síncrona

A réplica é tornada síncrona como na última seção, e depois cortada. Uma venda, com o curl mandado
desistir depois de cinco segundos; a página do show; e duas perguntas ao primário:

```
ana@lab:~/tickets$ docker network disconnect tickets_replication tickets-replica-1
ana@lab:~/tickets$ curl -s -m 5 -X POST localhost:8080/events/1/tickets; echo "curl exit: $?"
curl exit: 28
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "60eeb0566861"}
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT wait_event, query FROM pg_stat_activity WHERE wait_event = 'SyncRep'"
 wait_event | query  
------------+--------
 SyncRep    | COMMIT
(1 row)

ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT sold FROM events WHERE id = 1'
 sold 
------
    0
(1 row)

ana@lab:~/tickets$ docker network connect tickets_replication tickets-replica-1
ana@lab:~/tickets$ sleep 10
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT sold FROM events WHERE id = 1'
 sold 
------
    1
(1 row)

ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 999999, "host": "60eeb0566861"}
```

**A venda não respondeu.** O curl desistiu depois de cinco segundos com o código de saída 28, o
código dele para tempo esgotado. O primário tinha a venda no próprio disco e estava esperando,
`SyncRep`, uma réplica que não podia ouvi-lo. Até ouvir, ele não diz que a venda aconteceu, **nem a
si mesmo**: uma consulta no primário ainda vê `sold = 0`. A página do show, lida na réplica, diz o
que dizia antes, que neste caso também é a verdade.

Essa é a escolha consistente: **nenhum cliente consegue ver uma venda que não está nas duas
máquinas**, e o preço é que nenhuma venda termina enquanto as duas não conseguem conversar. A
bilheteria ficou indisponível para escritas, por desenho.

Depois a rede volta. Dez segundos depois, `sold` é 1 e a página diz 999 999: o commit que esperava
chegou à réplica e terminou.

**Repare no que o comprador viveu.** O pedido dele esgotou o tempo, o que parece uma falha, e o
ingresso foi vendido mesmo assim, alguns segundos depois. Um tempo esgotado não diz nada sobre o
que aconteceu do outro lado; só diz que a resposta não chegou a tempo. Um comprador que tenta de
novo compra um segundo ingresso. A aula 10 trata de deixar uma nova tentativa segura exatamente
nesta situação.

## Com uma réplica assíncrona

A mesma partição, com a réplica como a aula 2 a deixou:

```
ana@lab:~/tickets$ docker network disconnect tickets_replication tickets-replica-1
ana@lab:~/tickets$ curl -s -m 5 -X POST localhost:8080/events/1/tickets; echo
{"event": 1, "seat": 1, "code": "cb5ad8d5b5fd9bea"}
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "8b97446b89dc"}
ana@lab:~/tickets$ sleep 5
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "8b97446b89dc"}
ana@lab:~/tickets$ docker network connect tickets_replication tickets-replica-1
ana@lab:~/tickets$ sleep 10
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 999999, "host": "8b97446b89dc"}
```

**A venda dá certo na hora.** O primário não espera ninguém. A página, lida na réplica, diz que
restam um milhão de lugares, e cinco segundos depois continua dizendo: a réplica não está recebendo
nada, então continua respondendo com o que sabia por último, enquanto a partição durar. Quando a
rede volta, a réplica alcança e a página fica certa de novo.

Essa é a escolha disponível: **todo pedido recebeu uma resposta, e algumas respostas estavam
desatualizadas**. Para a página de um show é uma boa troca. Para "quantos lugares restam" quando
restam três, é assim que dois compradores levam o mesmo lugar, a menos que a própria venda confira
no primário, como esta confere.
