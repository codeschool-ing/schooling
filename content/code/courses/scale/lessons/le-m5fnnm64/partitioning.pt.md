---
title: Particionando uma tabela grande
version: 1
---

**O particionamento divide uma tabela em várias, pelo valor de uma coluna, enquanto o programa
continua vendo uma tabela só.** Ele não acrescenta servidor e não divide a carga entre máquinas. O
que ele divide é o trabalho de cada consulta, e o trabalho de jogar dados fora.

A tabela `tickets` da bilheteria cresce a cada venda e nunca diminui. Depois de dois anos, a maior
parte das linhas descreve shows que já acabaram, e a maior parte das consultas pergunta pelas
últimas semanas. Todo índice dela cobre os dois anos, e toda consulta que não é respondida por um
índice lê os dois anos inteiros.

O **particionamento declarativo** do PostgreSQL declara uma tabela pai com uma **chave de
partição**, e tabelas filhas que são donas, cada uma, de uma faixa dessa chave. Uma linha inserida
na pai vai para a filha cuja faixa a contém; uma consulta na pai lê só as filhas que poderiam ter
linhas que batem. Essa segunda parte é a **poda de partições** (*partition pruning*), e ela é a
maior parte da graça.

Aqui está uma tabela de vendas particionada por mês, de janeiro a junho de 2026, com 1,2 milhão de
linhas geradas espalhadas por esses seis meses:

```sql
-- partitions.sql
CREATE TABLE sales (
  event_id int         NOT NULL,
  sold_at  timestamptz NOT NULL,
  cents    int         NOT NULL
) PARTITION BY RANGE (sold_at);

CREATE TABLE sales_2026_01 PARTITION OF sales FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE sales_2026_02 PARTITION OF sales FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE sales_2026_03 PARTITION OF sales FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE sales_2026_04 PARTITION OF sales FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE sales_2026_05 PARTITION OF sales FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE sales_2026_06 PARTITION OF sales FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

INSERT INTO sales (event_id, sold_at, cents)
SELECT 1 + n % 100,
       '2026-01-01'::timestamptz + (n % 181) * interval '1 day' + (n % 86400) * interval '1 second',
       5000 + n % 20000
FROM generate_series(1, 1200000) AS n;
```

Cada `CREATE TABLE … PARTITION OF` nomeia uma faixa, do primeiro instante do mês ao primeiro instante
do mês seguinte, e o limite de cima fica de fora, então os meses não se sobrepõem. **Uma linha cuja
data não cai em nenhuma partição é recusada**: inserir uma venda de julho antes de `sales_2026_07`
existir é um erro, e é por isso que uma tabela particionada precisa de alguém, ou de uma tarefa
agendada, que crie a partição do mês seguinte antes de o mês começar.

## Carregando

O arquivo entra no contêiner e roda lá:

```
ana@lab:~/tickets$ docker compose cp partitions.sql db:/tmp/partitions.sql
 tickets-db-1 Copying partitions.sql to tickets-db-1:/tmp/partitions.sql
 tickets-db-1 Copied partitions.sql to tickets-db-1:/tmp/partitions.sql
ana@lab:~/tickets$ docker compose exec db psql -U tickets -f /tmp/partitions.sql
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 1200000
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT tableoid::regclass AS partition, count(*) FROM sales GROUP BY 1 ORDER BY 1'
   partition   | count  
---------------+--------
 sales_2026_01 | 205529
 sales_2026_02 | 185640
 sales_2026_03 | 205530
 sales_2026_04 | 198900
 sales_2026_05 | 205530
 sales_2026_06 | 198871
(6 rows)

ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "EXPLAIN (COSTS OFF) SELECT count(*) FROM sales WHERE sold_at >= '2026-06-01'"
                                         QUERY PLAN                                          
---------------------------------------------------------------------------------------------
 Finalize Aggregate
   ->  Gather
         Workers Planned: 1
         ->  Partial Aggregate
               ->  Parallel Seq Scan on sales_2026_06 sales
                     Filter: (sold_at >= '2026-06-01 00:00:00+00'::timestamp with time zone)
(6 rows)
```

A pai e seis filhas, 1 200 000 linhas, e a contagem por partição mostra para onde elas foram:
`tableoid::regclass` nomeia a tabela filha onde cada linha está guardada. Fevereiro tem menos
porque tem 28 dias.

O plano de uma consulta sobre junho é o ponto do exercício inteiro. **Ele lê `sales_2026_06` e mais
nada.** O filtro em `sold_at` deixou o planejador descartar cinco das seis partições antes de ler
uma linha, então a consulta faz um sexto do trabalho que faria numa tabela única, e os índices que
ela usaria têm um sexto do tamanho.

## Escolhendo a chave

A poda só acontece quando a consulta filtra pela chave de partição. Uma consulta por "toda venda do
show 42", numa tabela particionada por mês, precisa ler as seis partições, e fica um pouco mais
lenta que numa tabela única, porque são seis planos em vez de um. Então a chave é escolhida pelo
**filtro que a maioria das consultas já carrega**:

- **Tempo** (particionamento por faixa) para tudo o que é consultado principalmente no recente e
  guardado por um período fixo: vendas, logs, eventos, medições. É de longe o mais comum.
- **Uma lista de valores** (particionamento por lista) quando uma coluna tem poucos valores que
  dividem as consultas: um país, uma região, um cliente da plataforma.
- **Um hash de um valor** (particionamento por hash) para dividir uma tabela em pedaços iguais
  quando nenhum filtro é comum, o que ajuda mais a manutenção que as consultas.

O particionamento continua sendo um servidor. Ele deixa uma tabela grande mais barata de consultar
e de manter; não deixa que ela cresça além do que uma máquina consegue guardar ou gravar. Isso é o
sharding, na seção 09.
