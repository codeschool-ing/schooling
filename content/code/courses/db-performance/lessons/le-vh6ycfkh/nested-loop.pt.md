---
title: O nested loop, uma busca por linha
version: 1
---

A aula 5 de `sql-databases` disse o que uma junção significa: linhas de duas tabelas pareadas por
uma condição. Não disse nada sobre como o servidor acha os pares, e há três jeitos. Cada um tem um
formato no plano, um tipo de entrada em que é bom e um jeito de dar errado:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três painéis. Nested Loop: cada uma de quatro linhas externas busca as correspondências num índice da tabela interna, uma busca por linha externa, então o lado interno roda uma vez por linha. Hash Join: primeiro a entrada menor é lida inteira para uma tabela hash na memória, depois a entrada maior passa uma vez por ela e cada linha consulta a tabela. Merge Join: as duas entradas chegam ordenadas pela chave da junção, e dois ponteiros descem por elas juntos, cada lista lida uma vez.\"><rect x=\"10\" y=\"10\" width=\"220\" height=\"250\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"22\" y=\"28\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Nested Loop</text><rect x=\"250\" y=\"10\" width=\"220\" height=\"250\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"262\" y=\"28\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hash Join</text><rect x=\"490\" y=\"10\" width=\"220\" height=\"250\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"502\" y=\"28\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Merge Join</text><rect x=\"24\" y=\"56\" width=\"56\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">o1</text><path d=\"M80 68 L138 68\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M138.0 68.0 L132.0 72.0 L132.0 64.0 Z\" fill=\"var(--phosphor)\"></path><rect x=\"24\" y=\"96\" width=\"56\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">o2</text><path d=\"M80 108 L138 108\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M138.0 108.0 L132.0 112.0 L132.0 104.0 Z\" fill=\"var(--phosphor)\"></path><rect x=\"24\" y=\"136\" width=\"56\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"148\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">o3</text><path d=\"M80 148 L138 148\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M138.0 148.0 L132.0 152.0 L132.0 144.0 Z\" fill=\"var(--phosphor)\"></path><rect x=\"24\" y=\"176\" width=\"56\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"188\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">o4</text><path d=\"M80 188 L138 188\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M138.0 188.0 L132.0 192.0 L132.0 184.0 Z\" fill=\"var(--phosphor)\"></path><rect x=\"140\" y=\"56\" width=\"76\" height=\"144\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">índice</text><text x=\"178\" y=\"134\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">do interno</text><text x=\"24\" y=\"232\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">uma busca por linha externa</text><rect x=\"264\" y=\"52\" width=\"80\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"304\" y=\"67\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">lado menor</text><path d=\"M304 82 L304 104\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M304.0 104.0 L300.0 98.0 L308.0 98.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"352\" y=\"67\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">1 monta</text><rect x=\"264\" y=\"106\" width=\"80\" height=\"82\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"272\" y=\"114\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"296\" y=\"114\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320\" y=\"114\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"272\" y=\"132\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"296\" y=\"132\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320\" y=\"132\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"272\" y=\"150\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"296\" y=\"150\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320\" y=\"150\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"272\" y=\"168\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"296\" y=\"168\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320\" y=\"168\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"360\" y=\"106\" width=\"58\" height=\"140\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"389\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">lado</text><text x=\"389\" y=\"184\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">maior</text><path d=\"M360 150 L346 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M346.0 150.0 L352.0 146.0 L352.0 154.0 Z\" fill=\"var(--amber)\"></path><text x=\"372\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">2 consulta</text><text x=\"264\" y=\"232\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">memória para um lado</text><rect x=\"510\" y=\"50\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"530\" y=\"61\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1</text><rect x=\"510\" y=\"78\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"530\" y=\"89\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">2</text><rect x=\"510\" y=\"106\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"530\" y=\"117\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">3</text><rect x=\"510\" y=\"134\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"530\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">5</text><rect x=\"620\" y=\"50\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640\" y=\"61\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1</text><rect x=\"620\" y=\"78\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640\" y=\"89\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1</text><rect x=\"620\" y=\"106\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640\" y=\"117\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">2</text><rect x=\"620\" y=\"134\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">3</text><rect x=\"620\" y=\"162\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640\" y=\"173\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">4</text><rect x=\"620\" y=\"190\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640\" y=\"201\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">5</text><path d=\"M552 61 L618 61\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M552 61 L618 89\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M552 89 L618 117\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M552 117 L618 145\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M552 145 L618 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><text x=\"504\" y=\"232\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">as duas ordenadas, lidas uma vez</text></svg>", "caption": "Os três algoritmos de junção. O nested loop paga por linha externa, o hash join paga memória por um lado, o merge join precisa dos dois lados em ordem."}
```

O planejador escolhe um por junção, a partir das contagens de linhas que espera de cada lado. Esta
seção e as duas seguintes pegam um de cada vez nas tabelas do `market`, com os planos paralelos
desligados na sessão como nas aulas 3 e 4, para que cada plano seja uma árvore só.

## O formato

Um nested loop (laço aninhado) é a junção que qualquer pessoa escreveria à mão:

```
for each row in the outer input:
    for each row in the inner input that matches it:
        emit the pair
```

A entrada **externa** é o nó impresso primeiro embaixo do `Nested Loop`; a entrada **interna** é o
segundo, e roda uma vez para cada linha que a externa produz. Esse lado interno é quase sempre uma
busca em índice — "ache as linhas cuja chave é igual à chave desta linha externa" — e, quando é, o
custo da junção é o número de linhas externas vezes o preço de uma busca.

## Os pedidos de um cliente e as linhas deles

Os pedidos do cliente 4242, cada um com as suas linhas:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.670 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT o.id, o.placed_at, l.product_id, l.quantity FROM orders AS o JOIN order_lines AS l ON l.order_id = o.id WHERE o.customer_id = 4242;
                                                               QUERY PLAN                                                                
-----------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=4.95..179.97 rows=27 width=24) (actual time=0.075..0.354 rows=24 loops=1)
   Buffers: shared hit=17 read=36
   ->  Bitmap Heap Scan on orders o  (cost=4.51..47.80 rows=11 width=16) (actual time=0.044..0.118 rows=10 loops=1)
         Recheck Cond: (customer_id = 4242)
         Heap Blocks: exact=10
         Buffers: shared hit=2 read=11
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.032..0.032 rows=10 loops=1)
               Index Cond: (customer_id = 4242)
               Buffers: shared read=3
   ->  Index Scan using order_lines_pkey on order_lines l  (cost=0.43..11.98 rows=3 width=16) (actual time=0.022..0.023 rows=2 loops=10)
         Index Cond: (order_id = o.id)
         Buffers: shared hit=15 read=25
 Planning:
   Buffers: shared hit=313 read=6
 Planning Time: 1.175 ms
 Execution Time: 0.448 ms
(16 rows)

Time: 2.904 ms
```

Leia de dentro para fora, como a aula 3 ensinou. O lado externo é a varredura bitmap de `orders` que
a aula 3 leu sozinha: dez pedidos deste cliente. Para cada um deles o lado interno, uma varredura
de índice em `order_lines_pkey`, acha as linhas daquele pedido: **`loops=10`**, e `rows=2` por loop,
uma média — a junção devolveu 24 linhas no total, que é o que a linha do `Nested Loop` diz. O
`actual time=0.022..0.023` da varredura interna também é por loop, então dez buscas levaram cerca
de um quarto de milissegundo juntas.

Um número nessa linha **não** é por loop: `Buffers`. As 40 páginas da varredura interna (15 hit, 25
read) são o total das dez buscas, quatro páginas cada — alguns níveis do índice e a página da tabela
que guarda as linhas do pedido. A regra da aula 3, multiplicar por `loops`, vale para os tempos e as
linhas, que são médias, e não para os buffers, que já vêm somados.

**Meio milissegundo para a junção inteira.** Para dez linhas externas nada chega perto: um hash join
teria de ler uma das duas tabelas inteira antes de produzir qualquer coisa.

## Quando dá errado

O custo do nested loop cresce com o número de linhas externas, e o planejador o escolheu aqui porque
esperava onze. Cada busca custou uns 0,022 milissegundo; cem mil delas seriam dois segundos de
buscas, mais as páginas que tocam espalhadas pela tabela, como a aula 4 mostrou que faz uma varredura
de índice numa coluna sem correlação. O formato a reconhecer num plano lento é, portanto:

- um **`Nested Loop`** cujo filho interno tem **`loops`** na casa das dezenas de milhares ou mais,
- e um filho externo cujas linhas **estimadas** eram poucas, contra linhas **reais** que não eram.

A segunda linha é a parte perigosa. Um nested loop escolhido para 10 linhas externas que recebe
100000 é o plano ruim mais comum que existe, e a junção não é a causa — a estimativa é. A aula 6
reproduz exatamente isso, e a seção 05 desta aula mostra o planejador abandonando o nested loop
conforme o lado externo esperado cresce.

O outro formato ruim é um lado interno sem índice para usar: um nested loop sobre uma varredura
sequencial lê a tabela interna inteira uma vez por linha externa. O planejador o evita sempre que
há alternativa, então, quando você vê um, o que costuma faltar é um índice na coluna da junção.
