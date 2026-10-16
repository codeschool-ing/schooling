---
title: Chaves e índices numa tabela particionada
version: 1
---

Uma tabela particionada parece uma tabela só para uma consulta, e é várias tabelas para tudo o que
impõe uma regra. Índices e restrições de unicidade são onde a diferença aparece, e as duas coisas
saem de um fato: **um índice numa tabela particionada é um índice por partição**, cada um
conhecendo só as próprias linhas.

## A chave primária tem de incluir a chave de partição

`events_by_month` tem `PRIMARY KEY (id, at)`, embora seja só o `id` que identifica um evento. Tente
a versão óbvia:

```
market=# CREATE TABLE events_wrong (id bigint PRIMARY KEY, at timestamptz NOT NULL) PARTITION BY RANGE (at);
ERROR:  unique constraint on partitioned table must include all partitioning columns
DETAIL:  PRIMARY KEY constraint on table "events_wrong" lacks column "at" which is part of the partition key.
Time: 3.570 ms
```

O servidor recusa, e a mensagem diz o motivo. Um índice único em `id` seriam quatro índices
separados, um por mês, e cada um só poderia conferir que nenhuma outra linha **do seu mês** tem o
mesmo `id`. Duas linhas com o mesmo `id` em outubro e novembro passariam as duas. O servidor só
aceita uma unicidade que consegue garantir de fato, e ele garante quando a chave de partição faz
parte das colunas únicas: linhas de meses diferentes nunca colidem, porque o mês de uma linha decide
em qual índice ela é conferida.

**O que você abre mão é real.** `(id, at)` promete que dois eventos não têm **ao mesmo tempo** o
mesmo id e o mesmo instante, o que é mais fraco que "dois eventos não têm o mesmo id". Em `events` a
coluna identity torna duplicatas impossíveis de qualquer jeito, então nada se perde; numa tabela
cujos ids vêm de fora, um `id` duplicado chegando com outro `at` agora é aceito. Se a aplicação
precisa de `id` único sozinho, ela precisa de uma chave que inclua o tempo, ou da unicidade conferida
em outro lugar.

Uma **chave estrangeira que aponta para** uma tabela particionada também tem de referenciar essa
chave completa, e é por isso que particionar uma tabela à qual muitas outras se referem é o caso
mais difícil: toda tabela que a referencia tem de carregar a chave de partição também. Particionar
uma tabela na ponta das referências — eventos, logs, leituras — evita isso, e é mais um motivo de
serem essas as tabelas particionadas de costume.

## Um índice declarado uma vez, construído muitas

`events_by_month` declarou um índice, em `customer_id`, no pai. O servidor construiu um em cada
partição e deu a eles o nome da partição:

```
market=# \di events_2025_1*
                            List of relations
 Schema |              Name              | Type  | Owner |     Table      
--------+--------------------------------+-------+-------+----------------
 public | events_2025_11_customer_id_idx | index | ana   | events_2025_11
 public | events_2025_11_pkey            | index | ana   | events_2025_11
 public | events_2025_12_customer_id_idx | index | ana   | events_2025_12
 public | events_2025_12_pkey            | index | ana   | events_2025_12
(4 rows)
```

`events_2025_11_customer_id_idx` e `events_2025_11_pkey`, o mesmo par para dezembro, e o mesmo para
toda partição anexada depois: o `ATTACH` confere se a tabela tem um índice equivalente, usa-o se
tiver e o constrói se não tiver. Esse último passo pode ser lento numa tabela grande, o que é mais um
motivo para preparar uma partição de antemão, índice incluído, antes de anexá-la.

**Ser separado também é a parte útil.** Cada índice cobre um mês, então reconstruir um com `REINDEX`
mexe num mês e não no histórico inteiro, e remover um mês remove os índices dele junto, sem custo.

## A única coisa que você não pode fazer no pai

Numa tabela comum, um índice numa tabela movimentada é construído com `CREATE INDEX CONCURRENTLY`,
que não bloqueia escritas enquanto roda. No pai de uma tabela particionada:

```
market=# CREATE INDEX CONCURRENTLY ON events_by_month (kind);
ERROR:  cannot create index on partitioned table "events_by_month" concurrently
Time: 0.778 ms
```

O caminho alternativo é mais longo e vale saber que existe: crie o índice só no pai com `CREATE
INDEX … ON ONLY events_by_month`, que não constrói nada e fica marcado como inválido; construa o
índice de cada partição com `CONCURRENTLY`; e anexe cada um ao do pai com `ALTER INDEX … ATTACH
PARTITION`. Quando o índice da última partição é anexado, o do pai fica válido. Vários comandos por
partição, e o motivo de existirem ferramentas que gerenciam partições.

## Deixando `market` como a aula 18 espera

A aula 18 começa de `market` como a aula 3 começa, mais `events_by_month` exatamente como o arquivo
da seção 03 a constrói. Esta aula terminou com outubro removido e uma partição padrão guardando uma
linha de teste, então ponha o banco de volta e construa a tabela mais uma vez:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 15.413 ms
CREATE INDEX
Time: 1458.838 ms (00:01.459)
ana@vm:~$ psql -q market -v ON_ERROR_STOP=1 -f events_by_month.sql
psql:events_by_month.sql:4: NOTICE:  table "events_by_month" does not exist, skipping
DROP TABLE
Time: 0.669 ms
CREATE TABLE
Time: 4.226 ms
CREATE TABLE
Time: 5.253 ms
CREATE TABLE
Time: 4.003 ms
CREATE TABLE
Time: 3.899 ms
CREATE TABLE
Time: 3.827 ms
INSERT 0 5000000
Time: 15204.206 ms (00:15.204)
CREATE INDEX
Time: 3045.838 ms (00:03.046)
VACUUM
Time: 2002.887 ms (00:02.003)
```

Se algum dia você rodar o `~/reset-market.sh` entre esta aula e a próxima, rode `psql market -f
events_by_month.sql` depois dele: o reset refaz `market` a partir da cópia, que nunca teve esta
tabela.
