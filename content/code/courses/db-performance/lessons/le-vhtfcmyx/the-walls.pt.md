---
title: As paredes, e a que distância está cada uma
version: 1
---

Folga é uma ladeira; uma parede é um penhasco. O banco está perfeitamente bem até o momento em que
não está, e esse momento chega sem uma consulta lenta para avisar. Cinco paredes respondem pela
maior parte das quedas que não são um disco quebrado, e cada uma pode ser lida de dentro do banco
muito antes de chegar:

```
market=# SELECT count(*) AS connections, current_setting('max_connections') AS max FROM pg_stat_activity WHERE backend_type = 'client backend';
 connections | max 
-------------+-----
           1 | 100
(1 row)

Time: 4.286 ms

market=# SELECT datname, age(datfrozenxid) AS xid_age, current_setting('autovacuum_freeze_max_age') AS freeze_max FROM pg_database WHERE datname = 'market';
 datname | xid_age | freeze_max 
---------+---------+------------
 market  |  526533 | 200000000
(1 row)

Time: 1.294 ms

market=# SELECT sequencename, data_type, last_value, max_value, round(100.0 * last_value / max_value, 4) AS pct_used FROM pg_sequences ORDER BY pct_used DESC;
   sequencename   | data_type | last_value |      max_value      | pct_used 
------------------+-----------+------------+---------------------+----------
 customers_id_seq | integer   |     200000 |          2147483647 |   0.0093
 products_id_seq  | integer   |      50000 |          2147483647 |   0.0023
 sellers_id_seq   | integer   |       1000 |          2147483647 |   0.0000
 orders_id_seq    | bigint    |    2016623 | 9223372036854775807 |   0.0000
 events_id_seq    | bigint    |    5000000 | 9223372036854775807 |   0.0000
(5 rows)

Time: 3.251 ms

market=# SELECT max(total_cents) AS largest_order, 2147483647 AS integer_limit FROM orders;
 largest_order | integer_limit 
---------------+---------------
         50499 |    2147483647
(1 row)

Time: 113.434 ms
```

## Conexões

**1 de 100**: este `psql`, numa máquina quieta. O `max_connections` é fixado na partida, e um cliente
que pede a centésima primeira conexão é recusado com um erro, não colocado numa fila. A aula 16 trata
de por que aumentar o número é a resposta errada, e a aula 10 do `db-administration`, da própria
configuração. Como parede, é a mais próxima numa aplicação movimentada: uma queda do pooler de
conexões, um deploy que dobra o número de processos da aplicação, ou uma consulta lenta que mantém
todas as conexões ocupadas, e as cem acabam em segundos.

## O contador de transações

Toda transação que muda algo pega um número de um contador de 32 bits, e esse contador dá a volta
depois de uns quatro bilhões. A resposta do PostgreSQL é **congelar** linhas antigas — marcá-las como
mais velhas que qualquer transação ainda rodando —, o que o `VACUUM` faz pelo caminho. O
`age(datfrozenxid)` diz há quantas transações foi gravada a linha não congelada mais antiga do banco:
**526533** aqui. Quando ele chega a `autovacuum_freeze_max_age`, 200 milhões, o autovacuum força uma
passada de congelamento nas tabelas que precisam, haja ou não outro motivo. E se algum dia chegasse a
poucos milhões de dois bilhões, o servidor se recusaria a começar qualquer transação nova até um
vacuum manual alcançar.

É a parede que quase nunca chega, porque o autovacuum é feito para impedi-la, e a de pior
consequência quando chega, porque a cura leva o tempo de ler o banco inteiro. O que a faz chegar é
algo impedindo o `VACUUM` de congelar: uma transação esquecida aberta por dias, de que trata a aula
15, ou um slot de replicação que ninguém está lendo.

## Sequências

As colunas identity do `market` tiram números de sequências, e cada uma tem um teto:

- `customers`, `products` e `sellers` usam `integer`, cujo teto é 2147483647;
- `orders` e `events` usam `bigint`, cujo teto é nove quintilhões.

Um `pct_used` de `0.0093` para clientes está longe de tudo, e o `orders_id_seq` em 2016623 está acima
dos dois milhões de pedidos que o `market.sql` fez — as compras das execuções da carga desta própria
aula, na seção anterior, também pegaram números, e uma sequência nunca devolve um número, nem quando
a linha é apagada ou a transação é desfeita. Uma tabela que insere e apaga muito gasta a sequência
bem mais depressa do que a contagem de linhas sugere, e é assim que uma chave `integer` chega ao
teto numa tabela com alguns milhares de linhas.

O conserto, trocar uma chave de `integer` para `bigint`, reescreve a tabela e todo índice que a
menciona, e numa tabela grande essa é a queda que você queria evitar. **É uma mudança para fazer
com anos de antecedência**, e por isso vale ler o teto agora.

## O limite da própria coluna

`total_cents` é `integer`, então nenhum pedido sozinho pode passar de 2147483647 centavos — 21
milhões de reais. O maior é **50499**, então essa é uma parede que a loja não vai encontrar. A mesma
conta feita numa coluna que soma em vez de registrar, como um total acumulado por vendedor, dá um
resultado bem diferente, e uma coluna `integer` que estoura faz falhar o `INSERT` que a cruzou, com um
erro, em produção.

## O disco

A única parede que o banco não enxerga de dentro. O `pg_database_size` diz quanto ele usa, não
quanto sobra, e o espaço que ele divide com o log, o log de escrita antecipada e o sistema
operacional só é visível ao `df`. Quando o disco enche, o PostgreSQL para de aceitar escritas, e se o
log de escrita antecipada não puder ser gravado, para de vez. A previsão da primeira seção é a
primeira defesa; o alerta da próxima seção é a segunda.
