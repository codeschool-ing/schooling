---
title: Quando o autovacuum analisa uma tabela sozinho
version: 1
---

Ninguém num servidor de verdade digita `ANALYZE` depois de cada mudança. **O autovacuum analisa as
tabelas além de fazer vacuum nelas**, e a lição 14 apresentou a metade que faz vacuum. A metade que
analisa tem o seu próprio gatilho, construído do mesmo jeito: um número fixo de linhas mais uma
fração da tabela.

```
shop=# SELECT name, setting FROM pg_settings WHERE name IN ('autovacuum_analyze_threshold', 'autovacuum_analyze_scale_factor', 'autovacuum_naptime');
              name               | setting 
---------------------------------+---------
 autovacuum_analyze_scale_factor | 0.1
 autovacuum_analyze_threshold    | 50
 autovacuum_naptime              | 60
(3 rows)

shop=# SELECT reltuples, 50 + 0.1 * reltuples AS analyze_after FROM pg_class WHERE relname = 'orders_copy';
 reltuples | analyze_after 
-----------+---------------
   1.3e+06 |        130050
(1 row)
```

**Uma tabela é analisada quando `n_mod_since_analyze` passa de 50 mais um décimo das suas
linhas.** Para a cópia, que tem 1,3 milhão de linhas desde a importação, isso dá 130.050 linhas
mudadas. Um insert, um update e um delete contam um cada. O launcher não vigia o tempo todo: ele
visita cada banco mais ou menos uma vez a cada `autovacuum_naptime`, 60 segundos, e põe um worker
nas tabelas que cruzaram a linha.

## Vendo acontecer

A importação foi processada, e todo pedido `pending` vira `paid`. São 300.000 linhas atualizadas,
bem além da linha. Então o autovacuum volta a valer para a cópia:

```
shop=# UPDATE orders_copy SET status = 'paid' WHERE status = 'pending';
UPDATE 300000

shop=# ALTER TABLE orders_copy RESET (autovacuum_enabled);
ALTER TABLE

shop=# SELECT now()::time(0), n_mod_since_analyze, last_analyze::time(0), last_autoanalyze::time(0) FROM pg_stat_user_tables WHERE relname = 'orders_copy';
   now    | n_mod_since_analyze | last_analyze | last_autoanalyze 
----------+---------------------+--------------+------------------
 04:27:00 |              300000 | 04:26:53     | 
(1 row)
```

O `RESET` devolve a tabela aos padrões do servidor; não sobra nenhuma configuração nela. Espere um
minuto e pergunte de novo:

```
shop=# SELECT now()::time(0), n_mod_since_analyze, last_analyze::time(0), last_autoanalyze::time(0) FROM pg_stat_user_tables WHERE relname = 'orders_copy';
   now    | n_mod_since_analyze | last_analyze | last_autoanalyze 
----------+---------------------+--------------+------------------
 04:27:42 |                   0 | 04:26:53     | 04:27:41
(1 row)

shop=# DROP TABLE orders_copy;
DROP TABLE
```

`last_autoanalyze` foi preenchido 41 segundos depois da primeira consulta, e `n_mod_since_analyze`
voltou a zero. As duas colunas distinguem quem fez: `last_analyze` é um `ANALYZE` que alguém
digitou, `last_autoanalyze` é o do launcher. A cópia cumpriu o seu papel e é apagada.

Na máquina da gravação a espera foi de 41 segundos. Na sua vai ser qualquer coisa até um minuto, e
mais num servidor ocupado, onde todos os workers já estão às voltas com uma tabela grande. **Essa
espera é a janela da seção anterior, e num servidor de verdade ninguém a mantém aberta de propósito:
ela simplesmente existe**, depois de toda mudança grande, pelo tempo que o autovacuum leva para
chegar.

## Onde o gatilho é grosso demais

Um décimo da tabela é uma linha sensata para uma tabela de um milhão de linhas. Numa de cem milhões
são dez milhões de linhas mudadas, e uma importação de cinco milhões nunca chega lá. Esses cinco
milhões podem ser exatamente os pedidos `pending` da seção anterior, um valor novo que o resumo
nunca viu. **Uma tabela grande que recebe lotes ganha um scale factor menor só dela**, definido na
tabela do jeito que a lição 14 definiu os limiares de vacuum:

```sql
ALTER TABLE orders SET (autovacuum_analyze_scale_factor = 0.02);
```

Isso não é rodado aqui, porque `orders` não precisa disso com um milhão de linhas. A outra correção
é a da seção anterior, que não depende de limiar nenhum: o job que fez a mudança roda o `ANALYZE`.

Dois tipos de tabela o autovacuum nunca analisa. **Uma tabela temporária** só é visível para a
sessão que a criou, então nenhum worker consegue lê-la, e uma sessão que carrega uma e depois faz
join com ela tem de analisá-la por conta própria. **A tabela-mãe de uma tabela particionada** também
não é analisada, só as partições, então as estatísticas da tabela como um todo vêm de um `ANALYZE`
que você roda; as lições 17 e 18 de `db-performance` tratam de particionamento.

Os contadores por trás de tudo isso vivem na memória e são gravados no disco num desligamento
limpo. Depois de um crash, como o que a lição 8 provoca de propósito, eles recomeçam do zero: o
`n_mod_since_analyze` de toda tabela esquece o que veio antes, e a próxima análise automática chega
mais tarde do que chegaria. O resumo em si, em `pg_statistic`, é uma tabela comum e sobrevive.
