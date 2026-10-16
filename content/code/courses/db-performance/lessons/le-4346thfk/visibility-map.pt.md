---
title: O mapa de visibilidade, e o que o apaga
version: 1
---

Toda tabela tem um pequeno arquivo companheiro chamado **mapa de visibilidade**: dois bits por página
da tabela. O que importa aqui diz "toda linha desta página é visível para toda transação". Quando um
index-only scan encontra uma entrada, ele procura a página dela no mapa. Se o bit está ligado, a linha
só pode estar visível e a entrada do índice é a resposta. Se não, o scan lê a página da tabela para
conferir, e isso é um **heap fetch**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um fluxo para cada entrada de índice num index-only scan. A entrada aponta para uma página da tabela. O scan pergunta ao mapa de visibilidade se a página está toda visível. Se sim, a linha é respondida só com a entrada do índice. Se não, o scan lê a página da tabela para conferir a linha, o que conta como um heap fetch. O VACUUM liga os bits do mapa; qualquer mudança numa linha de uma página desliga o bit dela.\"><rect x=\"14\" y=\"90\" width=\"150\" height=\"60\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"89\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">entrada do índice</text><text x=\"89\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">valores + nº da página</text><path d=\"M164 120 L214 120\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M214.0 120.0 L208.0 124.0 L208.0 116.0 Z\" fill=\"var(--wire)\"></path><rect x=\"214\" y=\"80\" width=\"210\" height=\"80\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"319\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">mapa de visibilidade:</text><text x=\"319\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">essa página está</text><text x=\"319\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">toda visível?</text><path d=\"M424 104 L470 104 L470 50 L500 50\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M494 50 L500 50\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M500.0 50.0 L494.0 54.0 L494.0 46.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"436\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sim</text><rect x=\"500\" y=\"26\" width=\"206\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"603\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">responde pelo índice</text><text x=\"603\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">Heap Fetches +0</text><path d=\"M424 136 L470 136 L470 190 L500 190\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M494 190 L500 190\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M500.0 190.0 L494.0 194.0 L494.0 186.0 Z\" fill=\"var(--amber)\"></path><text x=\"436\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">não</text><rect x=\"500\" y=\"166\" width=\"206\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"603\" y=\"184\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">lê a página da tabela</text><text x=\"603\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--amber)\">Heap Fetches +1</text><text x=\"214\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o VACUUM liga o bit da página;</text><text x=\"214\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">qualquer mudança numa linha o desliga</text></svg>", "caption": "O que um index-only scan faz com cada entrada. O índice é sempre lido; a tabela só é lida nas páginas pelas quais o mapa de visibilidade não responde."}
```

Duas regras decidem os bits, e a seção inteira decorre delas:

- **o `VACUUM` os liga.** Quando ele limpou uma página e achou todas as linhas dela visíveis para
  todos, marca a página como toda visível.
- **qualquer mudança numa linha os desliga.** Um `UPDATE`, um `DELETE` ou um `INSERT` numa página
  desliga o bit dela na hora, porque a página agora tem uma linha que alguma transação ainda não pode
  ver.

## Quanto de `orders` o mapa cobre

O `pg_class` guarda uma contagem das páginas que o mapa marca como todas visíveis, `relallvisible`,
ao lado da contagem de páginas, `relpages`:

```
market=# SELECT relpages, relallvisible FROM pg_class WHERE relname = 'orders';
 relpages | relallvisible 
----------+---------------
    16667 |         16667
(1 row)

Time: 1.473 ms
```

**16.667 páginas, 16.667 todas visíveis.** O `market.sql` terminou com `VACUUM ANALYZE`, nada mudou
`orders` desde então, e toda página está marcada. Por isso os dois index-only scans até aqui
mostraram `Heap Fetches: 0`.

## Um update

Os pedidos enviados no fim de dezembro são entregues. Uma instrução marca todos eles, o tipo de
tarefa que uma aplicação roda toda noite:

```
market=# UPDATE orders SET status = 'delivered' WHERE status = 'shipped';
UPDATE 43422
Time: 914.340 ms

market=# SELECT relpages, relallvisible FROM pg_class WHERE relname = 'orders';
 relpages | relallvisible 
----------+---------------
    16667 |         16667
(1 row)

Time: 1.232 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE placed_at >= '2025-12-01';
                                                                      QUERY PLAN                                                                      
------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=3383.39..3383.40 rows=1 width=8) (actual time=59.157..59.159 rows=1 loops=1)
   Buffers: shared hit=87265
   ->  Index Only Scan using orders_placed_at_idx on orders  (cost=0.43..3112.39 rows=108398 width=0) (actual time=0.051..53.396 rows=107780 loops=1)
         Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
         Heap Fetches: 87062
         Buffers: shared hit=87265
 Planning:
   Buffers: shared hit=20
 Planning Time: 0.212 ms
 Execution Time: 59.206 ms
(10 rows)

Time: 60.230 ms
```

O `UPDATE` mudou 43.422 linhas, todas das últimas semanas de dezembro. Duas coisas na saída merecem
leitura lenta.

**`relallvisible` continua dizendo 16.667.** Não está errado, está velho: o `pg_class` é atualizado
pelo `VACUUM` e pelo `ANALYZE`, não a cada mudança, então mostra o mapa como o último `VACUUM` o
deixou. O mapa em si mudou no momento em que as linhas mudaram. A coluna é um jeito barato de
acompanhar uma tabela entre um vacuum e outro, e um jeito enganoso logo depois de uma rajada de
escritas.

**`Heap Fetches: 87062`** onde não havia nenhum, e **87.265 acessos a páginas** em vez de 299. O mesmo
índice, a mesma consulta, as mesmas 107.780 linhas, e o plano continua dizendo `Index Only Scan`. Toda
página que o update tocou perdeu o bit: as páginas onde ficavam as versões antigas das linhas, e as
páginas novas no fim da tabela para onde foram as versões novas. E o índice agora tem **duas entradas
para cada pedido atualizado**, uma por versão, porque um update que não consegue ficar na sua página
grava uma versão nova em outro lugar e a indexa de novo. O scan precisa conferir as duas na tabela, a
antiga para descobri-la morta e a nova para descobri-la visível: 43.422 × 2 dá 86.844, quase todos os
87.062. Levou 59 milissegundos; o scan limpo levou 20.

## O `VACUUM` devolve

```
market=# VACUUM orders;
VACUUM
Time: 133.860 ms

market=# SELECT relpages, relallvisible FROM pg_class WHERE relname = 'orders';
 relpages | relallvisible 
----------+---------------
    17029 |         17029
(1 row)

Time: 1.110 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE placed_at >= '2025-12-01';
                                                                      QUERY PLAN                                                                      
------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=3314.25..3314.26 rows=1 width=8) (actual time=17.451..17.453 rows=1 loops=1)
   Buffers: shared hit=419
   ->  Index Only Scan using orders_placed_at_idx on orders  (cost=0.43..3049.02 rows=106091 width=0) (actual time=0.046..12.134 rows=107780 loops=1)
         Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
         Heap Fetches: 0
         Buffers: shared hit=419
 Planning:
   Buffers: shared hit=46
 Planning Time: 0.350 ms
 Execution Time: 17.513 ms
(10 rows)

Time: 18.833 ms
```

**Heap Fetches: 0** de novo, 419 páginas, 17,5 milissegundos. O `relpages` cresceu de 16.667 para
17.029: as linhas atualizadas foram gravadas como versões novas e as antigas ficaram para trás, que é
como o PostgreSQL faz updates, e o `VACUUM` marcou o espaço delas como livre para reúso em vez de
devolvê-lo. A aula 15 trata desse crescimento; o que importa aqui é que toda página está toda visível
de novo.

## O que isso quer dizer numa tabela real

Um index-only scan é tão bom quanto o mapa de visibilidade por trás dele, e o mapa é tão atual quanto
o último `VACUUM`. Numa tabela escrita o dia todo, as páginas sendo escritas são exatamente as páginas
cujos bits vivem sendo desligados, e se as consultas perguntam por linhas recentes, como a maioria
pergunta, elas perguntam exatamente por essas páginas.

O autovacuum é o que mantém o mapa atualizado na prática, e ele roda numa tabela quando linhas
suficientes mudaram. A aula 14 de `db-administration` é como ele decide quando, e como fazê-lo
visitar uma tabela movimentada com mais frequência. O `Heap Fetches` do plano é como você descobre se
ele está dando conta: um número perto de zero quer dizer que o mapa está atual, e um número perto da
contagem de linhas quer dizer que o seu index-only scan não é um.
