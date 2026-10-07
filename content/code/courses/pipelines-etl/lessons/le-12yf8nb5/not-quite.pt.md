---
title: O que nunca é igual duas vezes
version: 1
---

Alguns passos não podem ser idempotentes do jeito que estão escritos, porque o que eles registram é o
próprio ato de rodar. A primeira ideia da Ana para saber quando a tabela fato foi preenchida pela
última vez:

```
-- One row per load, so that somebody can ask when the fact table was last filled.
CREATE TABLE IF NOT EXISTS marts.load_log (loaded_day date, loaded_at timestamptz, lines bigint);
INSERT INTO marts.load_log
SELECT :'day', now(), count(*) FROM marts.fact_sales WHERE order_date = :'day';
```

```
ana@vm:~/etl$ sh twice.sh 'psql -q -d wh -v day=2026-03-16 -f load/load_log.sql' 'SELECT count(*) FROM marts.load_log'
psql:load/load_log.sql:2: NOTICE:  relation "load_log" already exists, skipping
after one run:  1
after two runs: 2
NOT idempotent
ana@vm:~/etl$ psql -d wh -c "TABLE marts.load_log"
 loaded_day |           loaded_at           | lines 
------------+-------------------------------+-------
 2026-03-16 | 2026-10-07 05:51:43.54519-03  |   448
 2026-03-16 | 2026-10-07 05:51:43.563843-03 |   448
(2 rows)
```

**Não é idempotente, e com razão.** Duas cargas aconteceram, e um registro de cargas deve dizer duas.
O `now()` torna cada linha diferente da anterior mesmo que as contagens fossem iguais. Um registro é o
único tipo de tabela em que acrescentar é o objetivo.

Toda tabela é de um tipo ou do outro, e os dois têm de ficar separados:

- **Uma tabela de fatos sobre o mundo** — vendas, clientes, preços — tem de sair igual quantas vezes
  for carregada. Nada nela pode depender de quando, ou de quantas vezes, o pipeline rodou: nada de
  `now()`, nada de `random()`, nenhum número de identidade distribuído na ordem de chegada e usado como
  chave em outro lugar.
- **Uma tabela de fatos sobre o pipeline** — cargas, execuções, alertas — é só de acréscimo por
  natureza, e nunca é o que um relatório sobre a loja lê.

Uma coluna como `loaded_at` numa tabela fato é o jeito comum de os dois se misturarem. Ela é útil, e
torna diferente a impressão digital de cada execução. A correção não é tirá-la, e sim saber que ela
está lá: a impressão digital de uma tabela idempotente deixa de fora as colunas que registram a
execução.

O mesmo vale fora do warehouse. Um e-mail, um arquivo enviado a um parceiro, uma cobrança num cartão:
cada um é um ato, e rodá-lo duas vezes age duas vezes. A lição 14 disse que eles ficam no fim; aqui
está o porquê. **Eles precisam de uma proteção escrita de propósito** — um registro de que o e-mail do
dia 16 foi enviado, conferido antes de enviar —, porque idempotência ali não é uma forma que uma carga
possa tomar.
