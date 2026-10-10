---
title: Lendo a árvore de dentro para fora
version: 1
---

Um plano é impresso de cima para baixo, e o natural é lê-lo assim, como uma receita cuja primeira
linha é o primeiro passo. **É o contrário: a primeira linha é a última coisa que acontece.** Os nós
mais fundos, os mais recuados, rodam primeiro, e as linhas sobem a partir deles até o topo, que é
por onde a resposta sai do servidor.

## O painel do vendedor

O painel do vendedor da aula 2 são os pedidos de dezembro de um vendedor, dia a dia. Depois do
índice em `seller_id` daquela aula ele deixou de ser o maior custo da carga. O plano dele continua
sendo a melhor árvore da carga para aprender: seis nós, e um deles tem dois filhos.

```
market=# EXPLAIN SELECT date_trunc('day', placed_at) AS day, count(*), sum(total_cents) FROM orders WHERE seller_id = 42 AND placed_at >= '2025-12-01' GROUP BY 1 ORDER BY 1;
                                                      QUERY PLAN                                                      
----------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=2287.58..2289.36 rows=79 width=24)
   Group Key: (date_trunc('day'::text, placed_at))
   ->  Sort  (cost=2287.58..2287.78 rows=79 width=12)
         Sort Key: (date_trunc('day'::text, placed_at))
         ->  Bitmap Heap Scan on orders  (cost=1984.02..2285.09 rows=79 width=12)
               Recheck Cond: ((seller_id = 42) AND (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone))
               ->  BitmapAnd  (cost=1984.02..1984.02 rows=79 width=0)
                     ->  Bitmap Index Scan on orders_seller_id_idx  (cost=0.00..19.61 rows=1491 width=0)
                           Index Cond: (seller_id = 42)
                     ->  Bitmap Index Scan on orders_placed_at_idx  (cost=0.00..1964.12 rows=106093 width=0)
                           Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
(11 rows)

Time: 2.460 ms
```

Leia a partir das linhas mais recuadas, para fora:

1. **`Bitmap Index Scan on orders_seller_id_idx`** percorre o índice que a aula 2 criou e marca
   cada página de `orders` que guarda algum pedido do vendedor 42. Cerca de 1491 entradas, ele
   espera.
2. **`Bitmap Index Scan on orders_placed_at_idx`**, o irmão no mesmo recuo, faz o mesmo para todo
   pedido feito desde primeiro de dezembro: 106093 entradas.
3. **`BitmapAnd`** é o pai dos dois. Fica só com as páginas marcadas duas vezes — vendedor 42 *e*
   dezembro — e espera que 79 linhas sobrevivam.
4. **`Bitmap Heap Scan on orders`** visita essas páginas, lê as linhas e confere a condição de novo
   em cada uma (`Recheck Cond`), porque uma marca numa página diz que a página tem uma linha que
   bate, e não qual linha é.
5. **`Sort`** põe as 79 linhas na ordem do dia.
6. **`GroupAggregate`** percorre as linhas ordenadas e emite uma linha por dia, com a contagem e a
   soma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"O plano do painel do vendedor desenhado como árvore. Embaixo, dois Bitmap Index Scans rodam primeiro: em orders_seller_id_idx, esperando 1491 linhas a um custo de 19.61, e em orders_placed_at_idx, esperando 106093 linhas a um custo de 1964.12, que é a maior parte do plano. Os dois alimentam um BitmapAnd, que espera 79 linhas; acima dele o Bitmap Heap Scan em orders, custo próprio 301.07; depois o Sort, custo próprio 2.69; e no topo o GroupAggregate, custo próprio 1.58, total 2289.36. As linhas sobem, e a ordem de execução está numerada de 1, embaixo, a 6, no topo.\"><text x=\"14\" y=\"16\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Roda de baixo para cima: os números são a ordem de execução</text><rect x=\"182\" y=\"36\" width=\"240\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><circle cx=\"168\" cy=\"57.0\" r=\"10\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"168\" y=\"57.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--ink)\">6</text><text x=\"192\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GroupAggregate</text><text x=\"192\" y=\"67\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">próprio 1.58 de 2289.36</text><rect x=\"182\" y=\"102\" width=\"240\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><circle cx=\"168\" cy=\"123.0\" r=\"10\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"168\" y=\"123.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--ink)\">5</text><text x=\"192\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Sort</text><text x=\"192\" y=\"133\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">próprio 2.69 de 2287.78</text><rect x=\"182\" y=\"168\" width=\"240\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><circle cx=\"168\" cy=\"189.0\" r=\"10\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"168\" y=\"189.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--ink)\">4</text><text x=\"192\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bitmap Heap Scan on orders</text><text x=\"192\" y=\"199\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">próprio 301.07 de 2285.09</text><rect x=\"182\" y=\"234\" width=\"240\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><circle cx=\"168\" cy=\"255.0\" r=\"10\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"168\" y=\"255.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--ink)\">3</text><text x=\"192\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BitmapAnd</text><text x=\"192\" y=\"265\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">próprio 0.29 de 1984.02</text><rect x=\"40\" y=\"300\" width=\"262\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><circle cx=\"26\" cy=\"321.0\" r=\"10\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"26\" y=\"321.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--ink)\">1</text><text x=\"50\" y=\"314\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bitmap Index Scan on orders_seller_id_idx</text><text x=\"50\" y=\"331\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">próprio 19.61 de 19.61</text><rect x=\"342\" y=\"300\" width=\"262\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"328\" cy=\"321.0\" r=\"10\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"328\" y=\"321.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--ink)\">2</text><text x=\"352\" y=\"314\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bitmap Index Scan on orders_placed_at_idx</text><text x=\"352\" y=\"331\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">próprio 1964.12 de 1964.12</text><path d=\"M302.0 102 L302.0 78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M302.0 78.0 L306.0 84.0 L298.0 84.0 Z\" fill=\"var(--wire)\"></path><text x=\"310.0\" y=\"90.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rows=79</text><path d=\"M302.0 168 L302.0 144\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M302.0 144.0 L306.0 150.0 L298.0 150.0 Z\" fill=\"var(--wire)\"></path><text x=\"310.0\" y=\"156.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rows=79</text><path d=\"M302.0 234 L302.0 210\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M302.0 210.0 L306.0 216.0 L298.0 216.0 Z\" fill=\"var(--wire)\"></path><text x=\"310.0\" y=\"222.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rows=79</text><path d=\"M171 300 L159 284 L272.0 284 L272.0 277\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M272.0 276 L268.0 282 L276.0 282 Z\" fill=\"var(--wire)\"></path><path d=\"M473 300 L461 284 L332.0 284 L332.0 277\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M332.0 276 L328.0 282 L336.0 282 Z\" fill=\"var(--wire)\"></path><text x=\"52\" y=\"276\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rows=1491</text><text x=\"488\" y=\"276\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rows=106093</text><text x=\"440\" y=\"57\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a primeira linha é o último passo,</text><text x=\"440\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e o custo dela é o do plano inteiro</text><text x=\"440\" y=\"189\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">custo próprio = total menos os filhos</text><text x=\"616\" y=\"312\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">86% do</text><text x=\"616\" y=\"326\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">plano</text></svg>", "caption": "O plano do painel como árvore. A execução começa nas folhas e as linhas sobem; cada caixa mostra o custo próprio do nó, o total menos o dos filhos."}
```

## Como as linhas viajam

O executor não roda o nó de baixo até o fim e depois o próximo acima. Ele pede uma linha ao nó do
topo; esse nó pede uma ao filho, e assim por diante até uma varredura, que lê só o bastante para
produzi-la. As linhas são **puxadas**, uma de cada vez, a partir do topo. É por isso que o `Limit`
da seção anterior conseguiu parar uma varredura de índice depois de dez linhas: simplesmente parou
de pedir.

O puxar explica também os custos iniciais. Um `Sort` a quem se pede a primeira linha precisa puxar
todas as linhas de baixo antes de responder, então faz todo o trabalho dos filhos logo de início. O
`GroupAggregate` aqui começa em `2287.58`, o mesmo que a ordenação embaixo dele, porque não pode
fazer nada antes de a ordenação começar a entregar linhas.

## Os custos são acumulados, então subtraia

**O custo de cada nó inclui o custo de tudo o que está embaixo dele.** A linha do topo, `2289.36`,
é o preço da consulta inteira, não da agregação. Para achar qual nó é caro, pegue o total de cada
nó e subtraia os totais dos filhos:

| nó | total | os filhos | o próprio |
|---|---|---|---|
| `GroupAggregate` | 2289.36 | 2287.78 | 1.58 |
| `Sort` | 2287.78 | 2285.09 | 2.69 |
| `Bitmap Heap Scan` | 2285.09 | 1984.02 | 301.07 |
| `BitmapAnd` | 1984.02 | 19.61 + 1964.12 | 0.29 |
| varredura do índice em `seller_id` | 19.61 | — | 19.61 |
| varredura do índice em `placed_at` | 1964.12 | — | 1964.12 |

**Oitenta e seis por cento do custo do plano é um nó só**: percorrer as 106093 entradas de índice
de dezembro para jogar fora todas menos as 79 que também são do vendedor 42. O índice do próprio
vendedor custa 19.61. Nada acima do bitmap merece atenção. Um índice único nas duas colunas
deixaria o servidor ir direto ao dezembro do vendedor 42; as aulas 8 a 10 tratam de escolher
índices assim, e esta tabela é como você saberia para onde apontar um.

Subtrair é o hábito a guardar. Um plano lento tem a linha do topo alta por construção, então ela
não diz nada sobre onde o tempo foi gasto. O nó cuja parte **própria** é grande é o que merece o
olhar.

## As duas estimativas que fazem a terceira

O 79 no meio da árvore é uma conta, e mostra o que o planejador supõe. Ele esperava que 1491 dos
dois milhões de pedidos fossem do vendedor 42 e que 106093 fossem de dezembro. Tratando as duas
condições como não relacionadas, a fração que atende às duas é o produto das duas frações:

```
2000000 × (1491 / 2000000) × (106093 / 2000000) = 79.1
```

**O planejador supõe que as condições são independentes, a menos que alguém diga o contrário.**
Aqui isso é mais ou menos verdade — a fatia de dezembro de um vendedor é mais ou menos a fatia que
ele tem no ano — e a estimativa se sustenta. Para duas colunas que andam juntas, como a cidade e o
estado de um cliente, o produto sai pequeno demais; a aula 7 mostra essa falha e as estatísticas que
a curam.

## As linhas de detalhe

As linhas sem seta pertencem ao nó acima delas, e quatro tipos aparecem na maioria dos planos:

| linha | o que diz |
|---|---|
| `Index Cond` | a condição que o índice respondeu: só as entradas que batem foram lidas |
| `Filter` | uma condição conferida em cada linha **depois** de lida; as linhas que ela remove foram pagas |
| `Recheck Cond` | uma varredura bitmap conferindo de novo cada linha nas páginas para onde foi mandada |
| `Sort Key`, `Group Key` | pelo que o nó ordena ou agrupa |

A aula 10 de `sql-databases` apontou a linha a procurar primeiro: uma coluna que você esperava ver
tratada por um índice, sentada numa linha `Filter` sem nenhum `Index Cond` que a nomeie.
