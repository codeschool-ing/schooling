---
title: Todo comando trava a tabela
version: 1
---

A imagem habitual de travas (locks) no PostgreSQL é que leitores nunca travam nada e escritores
travam as linhas que mudam. **Metade disso é verdade, e a outra metade causa quedas.** Leitores não
bloqueiam escritores nas linhas, e esse é o desenho multiversão que a aula 8 de `sql-databases`
descreveu. Mas todo comando, inclusive o `SELECT` mais simples, também pega uma trava em cada
tabela que toca, e a segura até a transação terminar. A maioria dessas travas nunca conflita com
nada, e é por isso que ninguém as percebe, até chegar um comando que precisa de um dos poucos modos
que conflitam com todos os outros.

## Olhando as travas de uma transação

Abra dois terminais e rode `psql market` em cada um. Esta aula os chama de **janela A** e **janela
B**, e cada transcrição abaixo é uma janela num momento: digite na janela que o texto indica, na
ordem que o texto dá. Na janela A, abra uma transação e leia alguns pedidos:

```
market=# BEGIN;
BEGIN
Time: 0.525 ms

market=*# SELECT count(*) FROM orders WHERE seller_id = 42;
 count 
-------
  1532
(1 row)

Time: 2.317 ms
```

A transação continua aberta. Na janela B, pergunte ao servidor que travas de tabela as outras
sessões seguram agora. O `pg_locks` é a view que a aula 13 lê direito; esta é uma primeira olhada:

```
market=# SELECT relation::regclass AS relation, mode, granted FROM pg_locks WHERE locktype = 'relation' AND pid <> pg_backend_pid() ORDER BY 1;
        relation        |      mode       | granted 
------------------------+-----------------+---------
 orders                 | AccessShareLock | t
 orders_pkey            | AccessShareLock | t
 orders_customer_id_idx | AccessShareLock | t
 orders_placed_at_idx   | AccessShareLock | t
 orders_seller_id_idx   | AccessShareLock | t
(5 rows)

Time: 2.104 ms
```

Um único `SELECT` segura **`AccessShareLock` em `orders` e em todos os seus quatro índices**: o
planejador abriu cada índice para decidir se o usaria, e cada um deles fica travado até a transação
da janela A terminar. De volta à janela A, mude uma linha, na mesma transação:

```
market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
UPDATE 1
Time: 1.173 ms
```

E olhe de novo pela janela B:

```
market=# SELECT relation::regclass AS relation, mode, granted FROM pg_locks WHERE locktype = 'relation' AND pid <> pg_backend_pid() ORDER BY 1;
        relation        |       mode       | granted 
------------------------+------------------+---------
 orders                 | RowExclusiveLock | t
 orders                 | AccessShareLock  | t
 orders_pkey            | AccessShareLock  | t
 orders_pkey            | RowExclusiveLock | t
 orders_customer_id_idx | RowExclusiveLock | t
 orders_customer_id_idx | AccessShareLock  | t
 orders_placed_at_idx   | RowExclusiveLock | t
 orders_placed_at_idx   | AccessShareLock  | t
 orders_seller_id_idx   | AccessShareLock  | t
 orders_seller_id_idx   | RowExclusiveLock | t
(10 rows)

Time: 0.932 ms
```

O `UPDATE` acrescentou **`RowExclusiveLock`** na tabela e em cada índice que precisou manter, ao
lado dos `AccessShareLock` de antes. Nada é liberado antes da hora: uma transação junta travas e
devolve todas de uma vez, no `COMMIT` ou no `ROLLBACK`. **Uma transação longa é uma lista longa de
travas**, e esse é o primeiro motivo para manter transações curtas.

## Oito modos, e quais pares conflitam

O PostgreSQL tem oito modos de trava de tabela. Os nomes são históricos e dizem pouco; o que
importa é que comandos pegam cada um e quais pares não podem ser segurados ao mesmo tempo por duas
transações:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A matriz de conflitos das travas de tabela do PostgreSQL 16: oito modos, de ACCESS SHARE, pego pelo SELECT, a ACCESS EXCLUSIVE, pego por ALTER TABLE, DROP, TRUNCATE e VACUUM FULL. ACCESS SHARE só conflita com ACCESS EXCLUSIVE; ROW EXCLUSIVE, pego por INSERT, UPDATE e DELETE, conflita com SHARE e tudo o que é mais forte; ACCESS EXCLUSIVE conflita com todos os modos, inclusive ACCESS SHARE.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">seguro por uma transação (colunas), pedido por outra (linhas)</text><text x=\"280\" y=\"36\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">seguro</text><text x=\"390\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pego por</text><text x=\"196.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1</text><text x=\"220.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2</text><text x=\"244.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">3</text><text x=\"268.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">4</text><text x=\"292.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">5</text><text x=\"316.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">6</text><text x=\"340.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">7</text><text x=\"364.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">8</text><text x=\"14\" y=\"74.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1 ACCESS SHARE</text><rect x=\"186\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"74.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">SELECT</text><text x=\"14\" y=\"98.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2 ROW SHARE</text><rect x=\"186\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"98.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">SELECT … FOR UPDATE / FOR SHARE</text><text x=\"14\" y=\"122.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3 ROW EXCLUSIVE</text><rect x=\"186\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"122.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">INSERT, UPDATE, DELETE</text><text x=\"14\" y=\"146.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">4 SHARE UPDATE EXCLUSIVE</text><rect x=\"186\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"146.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">VACUUM, CREATE INDEX CONCURRENTLY</text><text x=\"14\" y=\"170.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">5 SHARE</text><rect x=\"186\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"170.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CREATE INDEX</text><text x=\"14\" y=\"194.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6 SHARE ROW EXCLUSIVE</text><rect x=\"186\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"194.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CREATE TRIGGER</text><text x=\"14\" y=\"218.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7 EXCLUSIVE</text><rect x=\"186\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"218.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">REFRESH MATERIALIZED VIEW CONCURRENTLY</text><text x=\"14\" y=\"242.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">8 ACCESS EXCLUSIVE</text><rect x=\"186\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"242.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ALTER TABLE, DROP, TRUNCATE, VACUUM FULL</text><rect x=\"14\" y=\"268\" width=\"16\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"38\" y=\"276\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">conflito: o segundo espera</text><rect x=\"250\" y=\"268\" width=\"16\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"274\" y=\"276\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sem conflito: os dois seguem</text></svg>", "caption": "Quais modos de trava de tabela conflitam. Um quadrado cheio quer dizer que um comando pedindo o modo da linha espera enquanto outro segura o da coluna."}
```

Leia linha por linha. Um `SELECT` pede `ACCESS SHARE`, a linha 1, e o único quadrado cheio dessa
linha é a coluna 8: **um leitor só espera por `ACCESS EXCLUSIVE`.** Um `INSERT`, `UPDATE` ou
`DELETE` pede `ROW EXCLUSIVE`, a linha 3: ele segue ao lado de qualquer número de leitores e de
outros escritores, e espera por `SHARE` e pelos quatro modos acima dele. A linha 8, `ACCESS
EXCLUSIVE`, é cheia de ponta a ponta: **enquanto ela está segura, ou enquanto espera para ser,
ninguém mais toca na tabela.** Essa última oração é o assunto da seção 04 desta aula.

Duas dessas linhas valem ser sabidas de cor. O `CREATE INDEX` pega `SHARE`, que conflita com `ROW
EXCLUSIVE`: ele deixa leitores passarem e **para toda escrita enquanto a construção durar**. O
`CREATE INDEX CONCURRENTLY` pega `SHARE UPDATE EXCLUSIVE` em vez disso, que não conflita com
escritas, e esse é todo o motivo de ele existir. O `DROP INDEX CONCURRENTLY` da aula 11 é a mesma
troca no caminho de saída.

## Um conflito, ao vivo

A janela A ainda está com a transação aberta, segurando `ROW EXCLUSIVE` por causa do update. Na
janela B, crie um índice em `orders`:

```
market=# CREATE INDEX orders_status_idx ON orders (status);
```

Nenhuma resposta e nenhum prompt. **A janela B está esperando**, e vai esperar enquanto a janela A
mantiver a transação aberta: não há tempo limite por padrão. O `SHARE` dela é a linha 5, e a coluna
3 dessa linha está cheia. Agora termine a transação da janela A; esta aula desfaz, para que
`orders` fique com a linha como o `market.sql` a escreveu:

```
market=*# ROLLBACK;
ROLLBACK
Time: 0.337 ms
```

No momento em que a janela A soltou, o comando da janela B seguiu:

```
market=# CREATE INDEX orders_status_idx ON orders (status);
CREATE INDEX
Time: 8985.359 ms (00:08.985)
```

**8985 milissegundos**, dos quais a construção em si foi cerca de um segundo, como as da aula 11;
o resto foi espera pela janela A. A linha `Time:` conta a partir de quando o comando foi enviado,
então uma espera aparece nela, e é assim que uma espera por trava costuma parecer de fora: um
comando normalmente rápido levando um tempo que não combina com nada do próprio trabalho. Apague o
índice de novo na janela B com `DROP INDEX orders_status_idx;` antes de seguir.

Nada nesse conflito foi um erro. Os dois comandos estavam corretos, e o servidor fez exatamente o
que a matriz diz. **Um problema de trava de tabela quase nunca é um defeito num comando; são dois
comandos corretos se encontrando na ordem errada**, e o resto desta aula é sobre os encontros que
vale esperar.
