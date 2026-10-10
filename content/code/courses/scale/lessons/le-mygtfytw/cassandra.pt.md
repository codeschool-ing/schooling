---
title: Cassandra, as leituras na portaria
version: 1
---

O Cassandra é o armazenamento de coluna larga da aula 4, e a tabela da seção 07 daquela aula é a
criada aqui. Um cluster Cassandra costuma ser várias máquinas, cada uma dona de trechos de um anel de
hash; o laboratório roda um nó só, o que basta para ver o modelo de dados e os números do anel, e não
basta para ver a replicação.

O arquivo, salvo como `scans.cql`: um **keyspace**, o nome do Cassandra para um banco, que também
define quantas cópias de cada linha guardar; a tabela; e seis leituras, cinco do show 1 e uma do show
7:

```
-- scans.cql
CREATE KEYSPACE IF NOT EXISTS tickets
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE TABLE IF NOT EXISTS tickets.scans (
  show_id    text,
  scanned_at timestamp,
  ticket     text,
  gate       text,
  PRIMARY KEY ((show_id), scanned_at, ticket)
) WITH CLUSTERING ORDER BY (scanned_at DESC);

INSERT INTO tickets.scans (show_id, scanned_at, ticket, gate) VALUES ('show-1', '2026-11-15 21:03:51-0300', 'T-128', 'A');
INSERT INTO tickets.scans (show_id, scanned_at, ticket, gate) VALUES ('show-1', '2026-11-15 21:03:58-0300', 'T-121', 'B');
INSERT INTO tickets.scans (show_id, scanned_at, ticket, gate) VALUES ('show-1', '2026-11-15 21:04:02-0300', 'T-114', 'A');
INSERT INTO tickets.scans (show_id, scanned_at, ticket, gate) VALUES ('show-1', '2026-11-15 21:04:07-0300', 'T-107', 'B');
INSERT INTO tickets.scans (show_id, scanned_at, ticket, gate) VALUES ('show-1', '2026-11-15 21:04:09-0300', 'T-100', 'A');
INSERT INTO tickets.scans (show_id, scanned_at, ticket, gate) VALUES ('show-7', '2026-11-15 20:31:12-0300', 'T-900', 'A');
```

`replication_factor: 1` guarda uma cópia, que é tudo o que um nó consegue guardar; um cluster de
verdade usa 3. As horas levam o fuso de São Paulo, `-0300`.

## Subindo

O Cassandra leva cerca de um minuto para subir, e recusa conexões até lá. O segundo comando abaixo
espera por ele, perguntando a cada cinco segundos:

```
ana@lab:~/tickets$ docker run -d --name cassandra --memory 1536m -e MAX_HEAP_SIZE=512M -e HEAP_NEWSIZE=128M cassandra:5.0.9
7651c264e50cfc586a767c877f0f1942df1c6850d72e358329fa36f5c11a62d3
ana@lab:~/tickets$ until docker exec cassandra cqlsh -e 'DESCRIBE KEYSPACES' >/dev/null 2>&1; do sleep 5; done
ana@lab:~/tickets$ docker cp scans.cql cassandra:/tmp/scans.cql
ana@lab:~/tickets$ docker exec cassandra cqlsh -f /tmp/scans.cql
ana@lab:~/tickets$ docker exec cassandra cqlsh -e "SELECT scanned_at, ticket, gate FROM tickets.scans WHERE show_id = 'show-1' LIMIT 3"

 scanned_at                      | ticket | gate
---------------------------------+--------+------
 2026-11-16 00:04:09.000000+0000 |  T-100 |    A
 2026-11-16 00:04:07.000000+0000 |  T-107 |    B
 2026-11-16 00:04:02.000000+0000 |  T-114 |    A

(3 rows)
```

`MAX_HEAP_SIZE` e `HEAP_NEWSIZE` limitam o heap do Java, e `--memory` limita o contêiner; sem eles o
Cassandra se dimensiona pela máquina e ocupa muito mais. O `cqlsh`, o shell, roda o arquivo, que não
imprime nada quando dá certo.

A consulta nomeia uma partição, `show_id = 'show-1'`, e o Cassandra devolve as linhas **já na ordem de
agrupamento**, da mais nova para a mais velha, parando depois de três: uma leitura, de um nó, sem
ordenar. As horas são impressas em UTC, então 21:04 em São Paulo aparece como 00:04 do dia seguinte.

## Onde as partições moram

O Cassandra põe cada partição no anel passando a chave de partição por um hash que dá um **token**, um
número entre −2⁶³ e 2⁶³ − 1. O anel da seção 11 da aula 2, no tamanho real:

```
ana@lab:~/tickets$ docker exec cassandra cqlsh -e 'SELECT show_id, token(show_id) FROM tickets.scans PER PARTITION LIMIT 1'

 show_id | system.token(show_id)
---------+-----------------------
  show-7 |  -9054864109681963144
  show-1 |   5471948530961257742

(2 rows)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 160\" role=\"img\" aria-label=\"A faixa de tokens do Cassandra desenhada como uma linha de menos dois elevado a sessenta e três a dois elevado a sessenta e três. O token do show 7, cerca de menos 9,05 vezes dez elevado a dezoito, fica perto da ponta esquerda; o do show 1, cerca de 5,47 vezes dez elevado a dezoito, fica na metade direita.\"><path d=\"M60 80 L660 80\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"60\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">−2⁶³</text><text x=\"660\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2⁶³−1</text><text x=\"360\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M360 74 L360 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"65.5\" cy=\"80\" r=\"7\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"65.5\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">show-7</text><text x=\"65.5\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">-9.05e18</text><circle cx=\"538.0\" cy=\"80\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"538.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">show-1</text><text x=\"538.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">5.47e18</text></svg>", "caption": "Cada chave de partição vira um token pelo hash. Um nó é dono de trechos desta linha, fechada num anel."}
```

O token do show 7 fica perto do fundo da faixa e o do show 1 na metade de cima. Num cluster de três
nós, cada um dono de muitos trechos do anel, esses dois muito provavelmente morariam em máquinas
diferentes, e acrescentar um quarto nó moveria só os trechos que ele tomasse.
