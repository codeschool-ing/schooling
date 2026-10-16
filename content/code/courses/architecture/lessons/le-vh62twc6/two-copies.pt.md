---
title: Duas cópias do estoque
version: 1
---

O laboratório são dois servidores PostgreSQL: um **primário** que recebe toda escrita, e um **standby**
que mantém uma cópia recebendo o log de escrita antecipada (WAL) do primário, o registro de cada mudança, e
reaplicando-o. O standby pode responder leituras; recusa escritas. É o jeito mais comum de manter uma
segunda cópia de um banco relacional, e a aula 10 parte dele.

A aula trabalha em `~/lab/cap`:

```sh
mkdir -p ~/lab/cap && cd ~/lab/cap
```

`replication.sh`, que o primário roda uma vez quando cria o diretório de dados:

```schooling-example
{"language": "sh", "file": "replication.sh", "parts": [{"code": "#!/bin/bash\nset -e\npsql -v ON_ERROR_STOP=1 -U \"$POSTGRES_USER\" -c \"CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator'\"\necho \"host replication replicator all scram-sha-256\" >> \"$PGDATA/pg_hba.conf\"", "note": "Roda uma vez, quando o diretório de dados do primário é criado: um papel autorizado a transmitir o log de escrita antecipada, e uma linha no `pg_hba.conf` que o deixa se conectar para replicação a partir da rede do laboratório."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  primary:\n    image: postgres:17\n    environment:\n      POSTGRES_PASSWORD: quitanda\n    volumes:\n      - ./replication.sh:/docker-entrypoint-initdb.d/replication.sh:ro\n      - primary:/var/lib/postgresql/data", "note": "Dois servidores PostgreSQL 17. O primário recebe as escritas e roda `replication.sh` na primeira partida."}, {"code": "  standby:\n    image: postgres:17\n    user: postgres\n    environment:\n      PGPASSWORD: replicator\n    command: >\n      bash -c \"until pg_basebackup -h primary -U replicator -D /var/lib/postgresql/data -R -X stream;\n               do sleep 1; done; chmod 700 /var/lib/postgresql/data; exec postgres\"\n    volumes:\n      - standby:/var/lib/postgresql/data\n    depends_on:\n      - primary\nvolumes:\n  primary:\n  standby:", "note": "O standby começa vazio, copia o primário com `pg_basebackup`, e `-R` grava as configurações que o fazem seguir o primário dali em diante, recebendo cada mudança. Ele aceita leituras e recusa escritas."}]}
```

Inicie os dois, dê alguns segundos, e pergunte ao primário quem o está copiando:

```
ana@vm:~/lab/cap$ docker compose up -d
 Network cap_default Creating 
 Network cap_default Creating 
 Volume cap_standby Creating 
 Volume cap_standby Creating 
 Volume cap_primary Creating 
 Volume cap_primary Creating 
 Volume cap_standby Created 
 Volume cap_standby Created 
 Volume cap_primary Created 
 Volume cap_primary Created 
 Network cap_default Created 
 Network cap_default Created 
 Container cap-primary-1 Creating 
 Container cap-primary-1 Created 
 Container cap-standby-1 Creating 
 Container cap-standby-1 Created 
 Container cap-primary-1 Starting 
 Container cap-primary-1 Started 
 Container cap-standby-1 Starting 
 Container cap-standby-1 Started 
ana@vm:~/lab/cap$ docker compose exec primary psql -U postgres -c "SELECT client_addr, state, sync_state FROM pg_stat_replication"
 client_addr |   state   | sync_state 
-------------+-----------+------------
 172.18.0.3  | streaming | async
(1 row)
```

Um cliente, o standby, `streaming`, e `async`: por padrão o PostgreSQL replica de forma assíncrona, a que
a seção sobre disponibilidade volta. Duas variáveis de shell economizam digitação no resto da aula, uma
para o `psql` de cada servidor:

```sh
P="docker compose exec -T primary psql -U postgres"
S="docker compose exec -T standby psql -U postgres"
```

Crie a tabela de estoque no primário e leia do standby:

```
ana@vm:~/lab/cap$ $P -c "CREATE TABLE stock (sku text PRIMARY KEY, units int); INSERT INTO stock VALUES ('coffee', 12)"
CREATE TABLE
INSERT 0 1
ana@vm:~/lab/cap$ $S -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    12
(1 row)

ana@vm:~/lab/cap$ $S -c "UPDATE stock SET units = 0 WHERE sku = 'coffee'"
ERROR:  cannot execute UPDATE in a read-only transaction
```

A linha escrita no primário está no standby um instante depois, e o standby recusa uma escrita: **uma
cópia decide, a outra segue.** Agora separe as duas.
