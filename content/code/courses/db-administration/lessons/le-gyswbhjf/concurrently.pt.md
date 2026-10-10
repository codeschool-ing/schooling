---
title: REINDEX CONCURRENTLY, e o que um que falhou deixa para trás
version: 1
---

O `REINDEX CONCURRENTLY` chega ao mesmo resultado por um caminho mais longo. **Ele constrói um índice
novo ao lado do antigo, com um lock que deixa leituras e escritas continuarem, e troca os dois no
fim.** Quem lê continua usando o índice antigo o tempo todo, quem escreve mantém os dois em dia
assim que o novo existe, e ninguém entra em fila.

O preço é tempo e trabalho. Medidos um depois do outro no mesmo índice:

```
shop=# \timing on
Timing is on.

shop=# REINDEX INDEX orders_customer_id;
REINDEX
Time: 475.202 ms

shop=# REINDEX INDEX CONCURRENTLY orders_customer_id;
REINDEX
Time: 738.791 ms
```

739 ms contra 475 na máquina da gravação, metade a mais, porque a tabela é lida duas vezes e a
construção para várias vezes para esperar outras transações. Ele também não pode rodar dentro de
um bloco de transação, nem nos catálogos do sistema. Numa tabela em uso, quase sempre vale pagar.

## Ele espera pelos outros, e ninguém espera por ele

A espera é a parte a ver. O terminal 2 abre uma transação com um update dentro e a deixa aberta,
como faz uma aplicação com uma requisição lenta:

```
shop=# BEGIN;
BEGIN

shop=*# UPDATE orders SET total_cents = total_cents WHERE id = 1;
UPDATE 1
```

O terminal 1, com `\timing on`, começa a reconstrução, e ela trava:

```
shop=# REINDEX INDEX CONCURRENTLY orders_created_at;
REINDEX
Time: 5957.520 ms (00:05.958)
```

O terminal 3, enquanto isso, lê e escreve na tabela como se nada estivesse acontecendo, e depois
pergunta o que o terminal 1 está fazendo:

```
shop=# SELECT count(*) FROM orders WHERE customer_id = 42;
 count 
-------
    20
(1 row)

Time: 1.502 ms

shop=# UPDATE orders SET total_cents = total_cents WHERE id = 2;
UPDATE 1
Time: 2.347 ms

shop=# SELECT pid, wait_event_type, wait_event, pg_blocking_pids(pid) AS blocked_by, left(query, 50) AS query FROM pg_stat_activity WHERE datname = 'shop' AND pid <> pg_backend_pid();
 pid | wait_event_type | wait_event | blocked_by |                       query                        
-----+-----------------+------------+------------+----------------------------------------------------
 339 | Lock            | virtualxid | {343}      | REINDEX INDEX CONCURRENTLY orders_created_at;
 343 | Client          | ClientRead | {}         | UPDATE orders SET total_cents = total_cents WHERE 
(2 rows)

Time: 2.326 ms

shop=# SELECT phase FROM pg_stat_progress_create_index;
              phase               
----------------------------------
 waiting for writers before build
(1 row)

Time: 0.949 ms
```

A leitura e a escrita levaram milissegundos. O `REINDEX` está esperando um `Lock` do tipo
`virtualxid`, **que é a espera pelo fim de outra transação**, e `blocked_by` aponta o processo do
terminal 2. A `pg_stat_progress_create_index` diz em que passo ele está: esperando os escritores que
já rodavam antes da construção. Toda escrita que começou antes de o índice novo existir precisa
terminar primeiro, ou ficaria faltando no índice novo.

O terminal 2 confirma:

```
shop=*# COMMIT;
COMMIT
```

e o `REINDEX` no terminal 1 terminou na hora, com o `Time:` sendo todo o tempo que esperou. **O
perigo do `CONCURRENTLY` é o oposto do `REINDEX` comum: ele nunca bloqueia a aplicação, e a
aplicação pode segurá-lo indefinidamente**. Uma transação esquecida aberta numa sessão parada, o
`idle in transaction` da lição 10, segura uma reconstrução concorrente pelo tempo que ficar aberta.

## Os passos, e onde uma falha deixa a sua marca

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 316\" role=\"img\" aria-label=\"O REINDEX INDEX CONCURRENTLY em oito passos: cria orders_created_at_ccnew marcado inválido; espera os escritores que já estão rodando; constrói a partir de um snapshot; espera os escritores de novo; acrescenta as linhas escritas durante a construção; espera snapshots mais antigos e o marca válido; troca os nomes e o índice antigo vira _ccold; espera e apaga o _ccold. O timeout desta seção bateu no passo 2. Uma falha nos passos 1 a 6 deixa orders_created_at_ccnew inválido: apague-o e rode o REINDEX de novo. Uma falha no 7 ou no 8 deixa o _ccold inválido: a reconstrução deu certo, então apague-o.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">REINDEX INDEX CONCURRENTLY orders_created_at</text><rect x=\"20\" y=\"40\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">1</text><text x=\"52\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cria orders_created_at_ccnew, marcado inválido</text><rect x=\"20\" y=\"74\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2</text><text x=\"52\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">espera os escritores que já estão rodando</text><text x=\"410\" y=\"87.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o timeout bateu aqui</text><rect x=\"20\" y=\"108\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"121.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">3</text><text x=\"52\" y=\"121.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">constrói o _ccnew a partir de um snapshot da tabela</text><rect x=\"20\" y=\"142\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">4</text><text x=\"52\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">espera os escritores de novo</text><rect x=\"20\" y=\"176\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">5</text><text x=\"52\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">acrescenta as linhas escritas durante a construção</text><rect x=\"20\" y=\"210\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">6</text><text x=\"52\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">espera snapshots mais antigos, marca _ccnew válido</text><rect x=\"20\" y=\"244\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">7</text><text x=\"52\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">troca os nomes: o índice antigo vira _ccold</text><rect x=\"20\" y=\"278\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"291.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">8</text><text x=\"52\" y=\"291.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">espera, depois apaga o _ccold</text><path d=\"M 434 40 L 442 40 L 442 236 L 434 236\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"452\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">uma falha nos passos 1 a 6</text><text x=\"452\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">deixa a cópia nova para trás:</text><text x=\"452\" y=\"146.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders_created_at_ccnew INVALID</text><text x=\"452\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">apague-o e rode o REINDEX de novo</text><path d=\"M 434 244 L 442 244 L 442 304 L 434 304\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"452\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">uma falha no 7 ou no 8</text><text x=\"452\" y=\"266.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">deixa o antigo para trás:</text><text x=\"452\" y=\"282.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">_ccold INVALID</text><text x=\"452\" y=\"298.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a reconstrução deu certo; apague-o</text></svg>", "caption": "Cada passo confirma por conta própria, que é o que deixa as outras sessões trabalharem, e também por que uma falha deixa alguma coisa para trás. Qual sobra depende de os nomes já terem sido trocados."}
```

Cada passo confirma antes de o próximo começar, que é o que deixa outras sessões trabalharem no
meio. É também por isso que pará-lo no meio não o desfaz: os passos já confirmados continuam
confirmados.

Para fazê-lo falhar de propósito, o terminal 2 segura de novo um update aberto, e o terminal 1 dá
cinco segundos à reconstrução:

```
shop=# BEGIN;
BEGIN

shop=*# UPDATE orders SET total_cents = total_cents WHERE id = 1;
UPDATE 1
```

```
shop=# SET statement_timeout = '5s';
SET

shop=# REINDEX INDEX CONCURRENTLY orders_created_at;
ERROR:  canceling statement due to statement timeout
```

O terminal 2 desiste da transação:

```
shop=*# ROLLBACK;
ROLLBACK
```

e o terminal 1 olha a tabela:

```
shop=# RESET statement_timeout;
RESET

shop=# \d orders
                                    Table "public.orders"
   Column    |           Type           | Collation | Nullable |           Default            
-------------+--------------------------+-----------+----------+------------------------------
 id          | bigint                   |           | not null | generated always as identity
 customer_id | bigint                   |           | not null | 
 status      | text                     |           | not null | 
 total_cents | integer                  |           | not null | 
 created_at  | timestamp with time zone |           | not null | 
Indexes:
    "orders_pkey" PRIMARY KEY, btree (id)
    "orders_created_at" btree (created_at)
    "orders_created_at_ccnew" btree (created_at) INVALID
    "orders_customer_id" btree (customer_id)
Foreign-key constraints:
    "orders_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customers(id)

shop=# SELECT indexrelid::regclass, indisvalid FROM pg_index WHERE NOT indisvalid;
       indexrelid        | indisvalid 
-------------------------+------------
 orders_created_at_ccnew | f
(1 row)

shop=# DROP INDEX CONCURRENTLY orders_created_at_ccnew;
DROP INDEX

shop=# SELECT count(*) FROM pg_index WHERE NOT indisvalid;
 count 
-------
     0
(1 row)
```

**`orders_created_at_ccnew ... INVALID` é a cópia nova, criada no passo 1 e abandonada no passo 2.**
O `orders_created_at` original está intacto e continua em uso. O inválido nunca é usado por consulta
nenhuma, e quando chegou ao ponto de ser mantido em dia custa alguma coisa em toda escrita, então
deixá-lo não é inofensivo. A consulta na `pg_index` acha todo índice inválido de um banco, e ela
pertence a uma verificação de rotina, porque uma reconstrução que falhou de madrugada só avisa num
log.

A cura depende do sufixo. **Um `_ccnew` é apagado e o `REINDEX CONCURRENTLY` rodado de novo.** Um
`_ccold` quer dizer que a falha veio depois da troca: o índice novo já está no lugar com o nome
original, a reconstrução deu certo, e só a cópia antiga sobra para apagar. O `DROP INDEX
CONCURRENTLY` remove qualquer um dos dois sem bloquear a tabela, e a última consulta diz que não
sobrou nada inválido.
