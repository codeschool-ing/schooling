---
title: A varredura sequencial, e por que ela não é a inimiga
version: 1
---

Todo plano termina em nós que leem uma tabela, e o PostgreSQL tem três jeitos principais de fazer
isso. Esta aula pega um de cada vez em `orders` e depois faz a pergunta que decide entre eles:
quantas linhas da tabela a consulta quer, e quão longe umas das outras elas estão?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"Três jeitos de ler as mesmas doze páginas de uma tabela, quatro delas com linhas que batem. O Seq Scan lê as doze páginas da esquerda para a direita. O Index Scan segue seis entradas do índice, na ordem do índice, até as páginas, pulando para a frente e para trás e visitando duas páginas duas vezes. O Bitmap Heap Scan primeiro transforma as entradas numa marca por página e depois visita as quatro páginas marcadas uma vez cada, da esquerda para a direita.\"><text x=\"14\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Seq Scan</text><text x=\"14\" y=\"88\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">toda página, em ordem</text><text x=\"14\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">12 páginas lidas</text><rect x=\"230\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"245.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1</text><rect x=\"268\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"283.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2</text><rect x=\"306\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"321.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">3</text><rect x=\"344\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"359.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">4</text><rect x=\"382\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"397.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">5</text><rect x=\"420\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"435.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">6</text><rect x=\"458\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"473.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">7</text><rect x=\"496\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">8</text><rect x=\"534\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"549.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">9</text><rect x=\"572\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"587.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">10</text><rect x=\"610\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"625.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">11</text><rect x=\"648\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"663.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">12</text><path d=\"M235.0 118 L673.0 118\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M673.0 118.0 L667.0 122.0 L667.0 114.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"14\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Index Scan</text><text x=\"14\" y=\"216\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">entrada por entrada, na ordem do índice</text><text x=\"14\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">6 visitas, 2 páginas duas vezes</text><rect x=\"230\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"245.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1</text><rect x=\"268\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"283.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2</text><rect x=\"306\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"321.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">3</text><rect x=\"344\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"359.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">4</text><rect x=\"382\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"397.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">5</text><rect x=\"420\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"435.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">6</text><rect x=\"458\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"473.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">7</text><rect x=\"496\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">8</text><rect x=\"534\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"549.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">9</text><rect x=\"572\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"587.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">10</text><rect x=\"610\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"625.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">11</text><rect x=\"648\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"663.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">12</text><rect x=\"270\" y=\"156\" width=\"36\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"288\" y=\"165\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">1</text><path d=\"M288 174 L587.0 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M587.0 201.0 L580.7 204.4 L581.4 196.5 Z\" fill=\"var(--phosphor)\"></path><rect x=\"320\" y=\"156\" width=\"36\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"338\" y=\"165\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">2</text><path d=\"M338 174 L321.0 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M321.0 201.0 L320.8 193.8 L327.6 198.1 Z\" fill=\"var(--phosphor)\"></path><rect x=\"370\" y=\"156\" width=\"36\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"388\" y=\"165\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">3</text><path d=\"M388 174 L473.0 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M473.0 201.0 L466.1 203.0 L468.5 195.4 Z\" fill=\"var(--phosphor)\"></path><rect x=\"420\" y=\"156\" width=\"36\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"438\" y=\"165\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">4</text><path d=\"M438 174 L321.0 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M321.0 201.0 L325.9 195.8 L327.7 203.5 Z\" fill=\"var(--phosphor)\"></path><rect x=\"470\" y=\"156\" width=\"36\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"488\" y=\"165\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">5</text><path d=\"M488 174 L435.0 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M435.0 201.0 L438.5 194.7 L442.2 201.8 Z\" fill=\"var(--phosphor)\"></path><rect x=\"520\" y=\"156\" width=\"36\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"538\" y=\"165\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">6</text><path d=\"M538 174 L587.0 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M587.0 201.0 L579.8 201.6 L583.7 194.6 Z\" fill=\"var(--phosphor)\"></path><text x=\"14\" y=\"326\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bitmap Heap Scan</text><text x=\"14\" y=\"344\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">marca as páginas, depois visita</text><text x=\"14\" y=\"362\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">4 páginas, uma vez cada, em ordem</text><rect x=\"230\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"245.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1</text><rect x=\"268\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"283.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2</text><rect x=\"306\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"321.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">3</text><rect x=\"344\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"359.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">4</text><rect x=\"382\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"397.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">5</text><rect x=\"420\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"435.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">6</text><rect x=\"458\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"473.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">7</text><rect x=\"496\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">8</text><rect x=\"534\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"549.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">9</text><rect x=\"572\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"587.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">10</text><rect x=\"610\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"625.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">11</text><rect x=\"648\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"663.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">12</text><text x=\"245.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"283.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"321.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">1</text><text x=\"359.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"397.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"435.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">1</text><text x=\"473.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">1</text><text x=\"511.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"549.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"587.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">1</text><text x=\"625.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"663.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><path d=\"M321.0 308 L321.0 329\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M321.0 329.0 L317.0 323.0 L325.0 323.0 Z\" fill=\"var(--phosphor)\"></path><path d=\"M435.0 308 L435.0 329\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M435.0 329.0 L431.0 323.0 L439.0 323.0 Z\" fill=\"var(--phosphor)\"></path><path d=\"M473.0 308 L473.0 329\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M473.0 329.0 L469.0 323.0 L477.0 323.0 Z\" fill=\"var(--phosphor)\"></path><path d=\"M587.0 308 L587.0 329\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M587.0 329.0 L583.0 323.0 L591.0 323.0 Z\" fill=\"var(--phosphor)\"></path><path d=\"M321.0 374 L587.0 374\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M593.0 374 L587.0 370 L587.0 378 Z\" fill=\"var(--phosphor)\"></path></svg>", "caption": "Os três caminhos de acesso sobre as mesmas páginas. As páginas contornadas têm uma linha que bate."}
```

A crença a largar primeiro é a de que uma varredura sequencial num plano é um erro. As pessoas
aprendem "crie um índice" antes de aprender qualquer outra coisa sobre desempenho, e daí em diante
um `Seq Scan` parece o índice que alguém esqueceu. **Para uma consulta que quer uma parte grande de
uma tabela, ler a tabela inteira em ordem é o plano mais rápido que existe**, e o planejador
costuma acertar ao escolhê-lo.

## O que ela faz

Uma varredura sequencial lê as páginas da tabela da primeira à última, na ordem em que estão no
arquivo, e confere cada linha contra a condição. A aula 3 calculou o preço: um `seq_page_cost` por
página e um `cpu_tuple_cost` por linha, mais um `cpu_operator_cost` por condição por linha. Não há
índice envolvido e nada a preparar.

Conte os pedidos acima de 400 reais, com os planos paralelos desligados na sessão para que o nó
simples apareça:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.411 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE total_cents > 40000;
                                                      QUERY PLAN                                                      
----------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=42725.62..42725.63 rows=1 width=8) (actual time=237.817..237.819 rows=1 loops=1)
   Buffers: shared hit=2208 read=14459
   ->  Seq Scan on orders  (cost=0.00..41667.00 rows=423449 width=0) (actual time=0.032..212.163 rows=419881 loops=1)
         Filter: (total_cents > 40000)
         Rows Removed by Filter: 1580119
         Buffers: shared hit=2208 read=14459
 Planning:
   Buffers: shared hit=111
 Planning Time: 0.571 ms
 Execution Time: 237.956 ms
(10 rows)

Time: 240.535 ms
```

**Todas as 16667 páginas, 2208 achadas na memória e 14459 lidas**, e 1580119 linhas removidas pelo
filtro para ficar com 419881. Essas linhas removidas são o custo de uma linha `Filter`, e aqui são o
custo certo a pagar. A consulta quer um pedido em cada cinco, e os preços estão espalhados ao acaso
pela tabela, então, com uns 120 pedidos por página, quase toda página tem pelo menos um que bate.
Não existe conjunto menor de páginas que contenha a resposta.

Ler em ordem é o que a torna barata. O disco e o sistema operacional veem as páginas pedidas uma
depois da outra e leem adiantado; o anel de buffers próprio do PostgreSQL, que a aula 3 apresentou,
impede a varredura de empurrar as páginas de todo mundo para fora da memória. **Uma varredura
sequencial é o plano de menor custo por página**, e a fraqueza dela é só não poder pular nenhuma.

## A versão paralela

Agora a mesma contagem com os planos paralelos permitidos de novo, que é como o servidor vem:

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE total_cents > 40000;
                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28524.97..28524.98 rows=1 width=8) (actual time=88.653..92.648 rows=1 loops=1)
   Buffers: shared hit=2240 read=14427
   ->  Gather  (cost=28524.76..28524.97 rows=2 width=8) (actual time=88.478..92.636 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=2240 read=14427
         ->  Partial Aggregate  (cost=27524.76..27524.77 rows=1 width=8) (actual time=85.473..85.474 rows=1 loops=3)
               Buffers: shared hit=2240 read=14427
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=176437 width=0) (actual time=0.035..76.587 rows=139960 loops=3)
                     Filter: (total_cents > 40000)
                     Rows Removed by Filter: 526706
                     Buffers: shared hit=2240 read=14427
 Planning:
   Buffers: shared hit=114
 Planning Time: 0.518 ms
 Execution Time: 92.759 ms
(16 rows)

Time: 94.262 ms
```

A aula 3 já leu este formato. O `Parallel Seq Scan` é dividido entre três processos, `loops=3`:
cada um pega o próximo bloco de páginas quando termina o anterior, de modo que os três, juntos, leem
cada página uma vez. Cada um contou a sua parte — `rows=139960` em média, 419880 no total, a mesma
resposta — e o `Partial Aggregate` acima deles é uma contagem por processo, que o `Finalize
Aggregate` soma. **93 milissegundos em vez de 238**, para as mesmas 16667 páginas.

Três processos não deixaram a consulta três vezes mais rápida. O `Gather` precisa iniciar os
workers e recolher as linhas deles, e os três disputam o mesmo disco e a mesma memória. O
planejador também precifica isso: a estimativa de custo da varredura caiu de `41667.00` para
`27083.67`, e não para um terço.

Dois ajustes decidem se isso acontece. `max_parallel_workers_per_gather` é quantos ajudantes um nó
pode ter — 2 por padrão, que é o que este plano lançou. E a tabela precisa ser grande o bastante
para compensar o custo de começar:

```
market=# SHOW min_parallel_table_scan_size;
 min_parallel_table_scan_size 
------------------------------
 8MB
(1 row)

Time: 0.508 ms

market=# SELECT pg_size_pretty(pg_relation_size('products'));
 pg_size_pretty 
----------------
 5192 kB
(1 row)

Time: 0.861 ms

market=# EXPLAIN SELECT count(*) FROM products WHERE price_cents > 20000;
                             QUERY PLAN                              
---------------------------------------------------------------------
 Aggregate  (cost=1351.25..1351.26 rows=1 width=8)
   ->  Seq Scan on products  (cost=0.00..1274.00 rows=30899 width=0)
         Filter: (price_cents > 20000)
(3 rows)

Time: 1.101 ms
```

`products` tem uns 5 MB, abaixo dos 8 MB do `min_parallel_table_scan_size`, então a varredura dela
fica num processo só, seja qual for a consulta. **O paralelismo é para varreduras grandes**; uma
pequena termina antes de os ajudantes começarem.

## Quando uma varredura sequencial está errada

O plano está errado quando a varredura lê uma tabela inteira para ficar com um punhado de linhas:
um `Seq Scan` com `Rows Removed by Filter` na casa dos milhões e um `rows` na casa das dezenas. A
contagem dos pedidos do vendedor 42 na aula 1 tinha esse formato — dois milhões de linhas lidas
para ficar com 1532 — e um índice foi o conserto. Distinguir esse formato do de cima é tudo o que
esta aula faz, e isso depende de um número que as duas próximas seções põem na tela: por quantas
**páginas**, e não linhas, a resposta está espalhada.
