---
title: Uma réplica que segue o primário
version: 1
---

**Uma réplica é um segundo servidor de banco que mantém para si uma cópia do primeiro**, aplicando
cada mudança pouco depois de ela acontecer. O primeiro se chama **primário**: é o único que aceita
escritas. As réplicas aceitam leituras, e se o primário se perde, uma delas pode tomar o lugar
dele.

A replicação do PostgreSQL se apoia em algo que ele já faz pela própria segurança. Antes de uma
mudança ser gravada nos arquivos de uma tabela, ela é gravada no **log de escrita antecipada**, o
WAL (*write-ahead log*): um registro de toda mudança, em ordem, para que uma queda no meio de uma
gravação possa ser reparada ao reiniciar. Uma réplica se conecta ao primário e pede esse log à
medida que ele é escrito, e o aplica aos próprios arquivos. Isso é a **replicação por streaming**,
e a réplica termina igual ao primário, byte a byte, um pouco depois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A replicação por streaming, em ordem. No primário, a mudança de uma transação é gravada primeiro no log de escrita antecipada, depois o primário diz ao cliente que confirmou, depois a mudança chega aos arquivos da tabela. O log é enviado em fluxo à réplica, que o grava no próprio log e o aplica aos próprios arquivos de tabela, um pouco depois.\"><rect x=\"20\" y=\"30\" width=\"330\" height=\"170\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"185\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">primário</text><rect x=\"370\" y=\"30\" width=\"330\" height=\"170\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">réplica</text><rect x=\"40\" y=\"70\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">INSERT …</text><text x=\"105\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 · mudança</text><path d=\"M170 90 L210 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M210 90 L203.7 93.0 L203.7 87.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"210\" y=\"70\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WAL</text><text x=\"270\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 · no log</text><path d=\"M270 110 L270 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M270 140 L267.0 133.7 L273.0 133.7 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"210\" y=\"140\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivos</text><text x=\"270\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 · depois</text><path d=\"M210 90 L120 150\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M120 150 L123.6 144.0 L126.9 149.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"78\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3 · COMMIT ao</text><text x=\"78\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cliente</text><path d=\"M330 90 L390 90\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M390 90 L383.7 93.0 L383.7 87.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"360\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">fluxo</text><rect x=\"390\" y=\"70\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">WAL</text><text x=\"450\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">5 · recebido</text><path d=\"M510 90 L550 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M550 90 L543.7 93.0 L543.7 87.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"550\" y=\"70\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"615\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivos</text><text x=\"615\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 · aplicado</text><text x=\"535\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">leituras aqui veem o mundo</text><text x=\"535\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">como estava no passo 6</text></svg>", "caption": "A réplica aplica o log do primário depois de o cliente ouvir que a transação foi confirmada. O intervalo é o atraso."}
```

## Dois arquivos novos

O primário precisa de um usuário com permissão de pedir o log, e de uma linha nas regras de acesso
que deixe esse usuário se conectar para replicação. Os dois vão num script que a imagem do
PostgreSQL roda uma vez, quando o banco é criado, ao lado do `schema.sql`:

```sh
# replication.sh
set -e
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator'"
echo "host replication replicator all scram-sha-256" >> "$PGDATA/pg_hba.conf"
```

E o `compose.yaml` ganha um quarto serviço. Aqui está o arquivo inteiro como fica desta aula em
diante:

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
        until pg_basebackup -h db -U replicator -D "$$PGDATA" -R -X stream; do sleep 1; done
        exec postgres -c recovery_min_apply_delay="$$DELAY"
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
```

Três coisas mudaram:

- **`db`** roda os dois arquivos de `/docker-entrypoint-initdb.d` em ordem de nome, então o
  `1-schema.sql` cria as tabelas antes de o `2-replication.sh` criar o usuário.
- **`replica`** é a mesma imagem iniciada de outro jeito. O comando dela primeiro roda o
  `pg_basebackup`, que copia o diretório de dados inteiro do primário por uma conexão de
  replicação, tentando de novo até o primário ficar pronto; `-R` grava as configurações que mandam
  a cópia continuar seguindo o primário depois, e `-X stream` copia também o log escrito durante a
  cópia. Depois ele sobe o PostgreSQL nesse diretório. `DELAY` é para a seção 05 e vale zero até
  lá. O `$$` é como o Compose escreve um `$` que o shell dentro do contêiner deve ver.
- **`app`** espera os dois bancos e recebe um segundo endereço, `REPLICA_URL`, que a próxima seção
  usa.

## Subindo

Primeiro a imagem é reconstruída em silêncio, depois tudo sobe:

```
ana@lab:~/tickets$ docker compose build -q
 Image tickets-app Building 
 Image tickets-app Built 
ana@lab:~/tickets$ docker compose up -d
 Network tickets_default Creating 
 Network tickets_default Creating 
 Network tickets_default Created 
 Network tickets_default Created 
 Container tickets-db-1 Creating 
 Container tickets-db-1 Created 
 Container tickets-replica-1 Creating 
 Container tickets-replica-1 Created 
 Container tickets-app-1 Creating 
 Container tickets-app-1 Created 
 Container tickets-lb-1 Creating 
 Container tickets-lb-1 Created 
 Container tickets-db-1 Starting 
 Container tickets-db-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Starting 
 Container tickets-replica-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
 Container tickets-lb-1 Starting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ docker compose ps --format "table {{.Service}}\t{{.Status}}"
SERVICE   STATUS
app       Up Less than a second
db        Up 5 seconds (healthy)
lb        Up Less than a second
replica   Up 3 seconds (healthy)
```

Quatro contêineres. A réplica esperou o primário ficar saudável, copiou-o e ficou saudável também.

## Perguntando ao primário

O primário mantém uma linha por réplica que o está seguindo, em `pg_stat_replication`:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT client_addr, state, sync_state, replay_lag FROM pg_stat_replication'
 client_addr |   state   | sync_state |   replay_lag    
-------------+-----------+------------+-----------------
 172.18.0.3  | streaming | async      | 00:00:00.000128
(1 row)
```

Uma réplica, no endereço do contêiner da réplica, `streaming`: está recebendo o log à medida que
ele é escrito. `async` quer dizer que o primário não espera a réplica antes de dizer a um cliente
que uma transação foi confirmada; a aula 3 é inteira sobre essa palavra. `replay_lag` é quanto as
mudanças aplicadas na réplica estão atrasadas, aqui um oitavo de milissegundo, porque nada está
acontecendo.

## Uma réplica se recusa a escrever

```
ana@lab:~/tickets$ docker compose exec replica psql -U tickets -c 'SELECT pg_is_in_recovery()'
 pg_is_in_recovery 
-------------------
 t
(1 row)

ana@lab:~/tickets$ docker compose exec replica psql -U tickets -c "UPDATE events SET name = 'Show One' WHERE id = 1"
ERROR:  cannot execute UPDATE in a read-only transaction
```

`pg_is_in_recovery()` é verdadeiro numa réplica: tecnicamente ela é um servidor se recuperando
permanentemente a partir do log do primário. E qualquer escrita é recusada com um erro, antes de
tocar em qualquer coisa. **Dois servidores que aceitassem escritas nas mesmas linhas precisariam
concordar sobre o resultado**, que é um problema muito mais difícil; uma réplica o evita nunca
escrevendo.
