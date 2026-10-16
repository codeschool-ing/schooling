---
title: Partições demais
version: 1
---

Se uma partição por mês é bom, uma por dia deve ser melhor: uma consulta sobre um dia leria um
trigésimo do que lê agora. É o raciocínio que termina em milhares de partições, e ele deixa de fora o
custo que a aula 17 nomeou e a seção 04 mostrou: **toda consulta que não consegue podar paga por
todas as partições**, e o planejador paga por elas mesmo quando a consulta consegue.

## Os mesmos eventos, uma partição por dia

Este arquivo cria `events_by_day`: as mesmas colunas, as mesmas linhas, cortadas em 365 partições, uma
para cada dia de 2025. Ninguém escreve 365 `CREATE TABLE` à mão, então um bloco `DO` os escreve num
laço. Salve como `~/events_by_day.sql`:

```sql
-- events_by_day.sql: the same events, one partition a day for all of 2025.
-- Run it on market after events_by_month.sql:  psql market -f events_by_day.sql
DROP TABLE IF EXISTS events_by_day;

CREATE TABLE events_by_day (LIKE events_by_month) PARTITION BY RANGE (at);

-- 365 partitions, named events_d20250101 to events_d20251231.
DO $$
BEGIN
    FOR d IN 0..364 LOOP
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF events_by_day FOR VALUES FROM (%L) TO (%L)',
            'events_d' || to_char(date '2025-01-01' + d, 'YYYYMMDD'),
            date '2025-01-01' + d, date '2025-01-01' + d + 1);
    END LOOP;
END $$;

INSERT INTO events_by_day SELECT * FROM events_by_month;
ALTER TABLE events_by_day ADD PRIMARY KEY (id, at);
CREATE INDEX ON events_by_day (customer_id);
VACUUM ANALYZE events_by_day;
```

Ele constrói as 365 tabelas, copia os cinco milhões de linhas de `events_by_month`, e acrescenta a
chave primária e o índice em `customer_id` depois, o que é mais rápido do que mantê-los atualizados
linha a linha durante a cópia:

```
ana@vm:~$ psql market -v ON_ERROR_STOP=1 -f events_by_day.sql
psql:events_by_day.sql:3: NOTICE:  table "events_by_day" does not exist, skipping
DROP TABLE
Time: 0.518 ms
CREATE TABLE
Time: 16.039 ms
DO
Time: 680.298 ms
INSERT 0 5000000
Time: 6046.334 ms (00:06.046)
ALTER TABLE
Time: 3257.952 ms (00:03.258)
CREATE INDEX
Time: 3254.463 ms (00:03.254)
VACUUM
Time: 9987.892 ms (00:09.988)
```

Menos de um segundo para as 365 tabelas vazias e uns vinte e três segundos ao todo. Noventa das
partições guardam as linhas, de 3 de outubro a 31 de dezembro; as outras 275 estão vazias, como fica
uma tabela quando as partições são criadas com um ano de antecedência.

## Quanto custa agora uma consulta que não poda

Os eventos do cliente 42, que a seção 04 mostrou que não podam, em cada tabela. `EXPLAIN (ANALYZE,
SUMMARY)` imprime os tempos de planejamento e de execução; com 365 partições o plano em si tem
centenas de linhas, então o `grep` fica com a linha do `Append` e os dois tempos. Duas vezes cada,
para ver que os números se repetem:

```
ana@vm:~$ psql market -c "EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_month WHERE customer_id = 42" | grep -E 'Append|Planning|Execution'
   ->  Append  (cost=0.43..13.76 rows=22 width=0) (actual time=0.045..0.125 rows=20 loops=1)
 Planning Time: 1.147 ms
 Execution Time: 0.232 ms
ana@vm:~$ psql market -c "EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_month WHERE customer_id = 42" | grep -E 'Append|Planning|Execution'
   ->  Append  (cost=0.43..13.76 rows=22 width=0) (actual time=0.026..0.067 rows=20 loops=1)
 Planning Time: 0.851 ms
 Execution Time: 0.159 ms
```

```
ana@vm:~$ psql market -c "EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_day WHERE customer_id = 42" | grep -E 'Append|Planning|Execution'
   ->  Append  (cost=0.00..389.50 rows=365 width=0) (actual time=1.114..2.874 rows=20 loops=1)
 Planning Time: 30.321 ms
 Execution Time: 5.702 ms
ana@vm:~$ psql market -c "EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_day WHERE customer_id = 42" | grep -E 'Append|Planning|Execution'
   ->  Append  (cost=0.00..389.50 rows=365 width=0) (actual time=1.133..2.411 rows=20 loops=1)
 Planning Time: 32.494 ms
 Execution Time: 5.009 ms
```

O plano mensal tem quatro filhos sob o `Append` e o diário **365**. O planejador gastou **cerca de 1
milissegundo** na tabela mensal e **30,3 e 32,5** na diária, umas trinta vezes mais, e a execução foi
de cerca de 0,2 milissegundo para 5, pelas mesmas 20 linhas. A maioria das partições diárias está
vazia, e a consulta ainda teve de planejar uma sondagem de índice ou uma leitura para cada uma delas
e rodá-la.

Trinta milissegundos de planejamento numa consulta que executa em cinco é o formato do problema: o
tempo vai para o plano, não para os dados, então discos mais rápidos e mais memória não fazem nada
por ele. Uma consulta rodada mil vezes por segundo gasta trinta segundos de processador por segundo
planejando, o que é mais processadores do que esta máquina tem.

## E uma consulta que poda

A consulta do dia da seção 02, na tabela diária, lê exatamente uma partição, a de 10 de novembro:

```
ana@vm:~$ psql market -c "EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_day WHERE at >= '2025-11-10' AND at < '2025-11-11'" | grep -E 'Scan|Planning|Execution'
   ->  Seq Scan on events_d20251110 events_by_day  (cost=0.00..1564.41 rows=55683 width=0) (actual time=0.022..9.242 rows=55694 loops=1)
 Planning Time: 3.173 ms
 Execution Time: 11.804 ms
```

**Uma leitura**, e execução em 11,8 milissegundos, mais rápida que os 48,3 da tabela mensal, porque lê
um dia em vez de um mês. Mas o planejamento levou **3,2 milissegundos**, contra 0,6 da versão mensal
na seção 02. A poda tira partições do plano. Ela não torna de graça o trabalho do planejador: achar
quais partições sobrevivem ainda exige olhar os limites delas, e parte do que o planejador faz por uma
tabela particionada cresce com a quantidade, quantas forem as que sobram.

## Quantas são demais

Não há número certo em todo lugar, e a medida acima é o jeito de achar o seu. O raciocínio são três
perguntas:

- **Qual é a fatia que envelhece?** O trabalho da aula 17 era descartar dados antigos. Se os dados
  são guardados por um ano e descartados por mês, uma partição por mês são doze, e uma por dia não
  compra nada de que o descarte precise.
- **Quanto custam as consultas que não podam?** Cada uma paga por partição, no planejamento e na
  execução. Uma tabela diária com uma consulta importante por `customer_id` paga trinta vezes por ela.
- **Quanto ganham as consultas que podam?** Ler um dia em vez de um mês é real, e é também o que um
  índice em `at` dá dentro de uma partição mensal.

Centenas são viáveis e milhares raramente valem a pena; versões recentes do PostgreSQL deixaram o
planejamento com muitas partições bem mais barato do que era, e este servidor, versão 16, ainda mostra
o custo com clareza. Deixe `events_by_day` onde está: a próxima seção a usa mais uma vez.
