---
title: O que o EXPLAIN imprime
version: 1
---

```sql
EXPLAIN SELECT * FROM orders WHERE customer_id = 42;
```

Ponha `EXPLAIN` na frente de uma consulta e o banco não a roda. Ele a **planeja** — decide como
buscaria as linhas — e imprime a decisão. Essa decisão é o plano, e toda pergunta desta aula se
responde lendo um.

Aqui está a tabela `orders` da loja, um milhão de linhas, com os índices que a aula 9 deixou nela:
uma chave primária e nada em `customer_id`.

```
shop=# EXPLAIN SELECT * FROM orders WHERE customer_id = 42;
                         QUERY PLAN                         
------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19966.00 rows=11 width=28)
   Filter: (customer_id = 42)
(2 rows)
```

Duas linhas. A primeira é um **nó**: um passo que o executor vai realizar, aqui uma varredura
sequencial de `orders`, que significa ler a tabela da primeira página à última. A segunda é um
detalhe desse nó: conforme lê, ele fica com as linhas em que `customer_id = 42` e descarta o
resto. É isso que `Filter` quer dizer — uma condição conferida contra cada linha **depois** de a
linha ter sido buscada.

## Os quatro números

```
(cost=0.00..19966.00 rows=11 width=28)
```

**`cost` são dois números, e nenhum deles é tempo.** Estão na unidade do próprio planejador, em
que ler uma página do disco em sequência custa 1 por definição e todo o resto é precificado em
relação a isso. O primeiro é o custo antes de o nó conseguir devolver a primeira linha; o segundo é
o custo de devolver todas. Uma varredura sequencial começa imediatamente — `0.00` — e termina
quando a tabela acaba. O planejador compara planos por esses números e escolhe o mais barato.
Então, quando um plano parece errado, o custo é a primeira coisa a perguntar: **o planejador achou
que este era o plano mais barato disponível**, e ou ele estava certo ou um dos números dele estava.

**`rows` é quantas linhas o nó espera devolver.** Não quantas ele lê — quantas sobrevivem para
serem passadas para cima. Onze, aqui, numa tabela de um milhão de linhas: o planejador sabe, pelas
estatísticas, mais ou menos quantos pedidos um cliente tem. Isso é uma estimativa, e a seção sobre
estimativas trata inteiramente do que acontece quando ela está errada.

**`width` é o tamanho médio de uma linha em bytes**, que decide quanta memória uma ordenação ou um
hash vai precisar. Vinte e oito bytes para `SELECT *` em `orders`; peça menos colunas e ele cai.

## A mesma consulta, com um índice para usar

`customers.email` tem um índice único, porque a restrição da aula 9 é um índice:

```
shop=# EXPLAIN SELECT * FROM customers WHERE email = 'user42@example.com';
                                      QUERY PLAN                                      
--------------------------------------------------------------------------------------
 Index Scan using customers_email_key on customers  (cost=0.42..8.44 rows=1 width=56)
   Index Cond: (email = 'user42@example.com'::text)
(2 rows)
```

Outro nó — `Index Scan` — e outra segunda linha. `Index Cond` é uma condição que o próprio índice
respondeu: a árvore foi descida até as entradas daquele endereço e só aquelas linhas foram
buscadas. `Filter`, acima, é uma condição aplicada a linhas já em mãos. A distinção é a coisa mais
útil para procurar num plano. É como "o índice não é usado" aparece na prática: **a coluna está
numa linha `Filter`, e não há `Index Cond` nomeando ela.**

Os custos dizem o resto. `0.42..8.44` contra `0.00..19966.00`: o index scan paga um pouco para
começar — descer a árvore — e termina depois de um punhado de páginas. A varredura é de graça para
começar e custa vinte mil para terminar.

## Um plano é uma árvore, lida de dentro para fora

A maioria das consultas precisa de mais de um passo, e os passos se aninham:

```
shop=# EXPLAIN SELECT c.name, o.id, o.total FROM customers c JOIN orders o ON o.customer_id = c.id WHERE c.email = 'user42@example.com';
                                             QUERY PLAN                                             
----------------------------------------------------------------------------------------------------
 Hash Join  (cost=8.45..20099.56 rows=10 width=23)
   Hash Cond: (o.customer_id = c.id)
   ->  Seq Scan on orders o  (cost=0.00..17466.00 rows=1000000 width=14)
   ->  Hash  (cost=8.44..8.44 rows=1 width=17)
         ->  Index Scan using customers_email_key on customers c  (cost=0.42..8.44 rows=1 width=17)
               Index Cond: (email = 'user42@example.com'::text)
(6 rows)
```

Indentação é estrutura. `Hash Join` é a raiz; os dois nós marcados com `->` embaixo dele são os
**filhos**, e o `Index Scan` é filho do `Hash`. Cada nó pede linhas aos nós abaixo dele, faz o
próprio trabalho, e entrega linhas ao nó acima. Então o primeiro ato do executor é no fundo do ramo
mais profundo, e o último é no topo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 316\" role=\"img\" aria-label=\"À esquerda, um plano como o EXPLAIN o imprime: um Hash Join no topo, com um Seq Scan em orders marcado por seta indentado embaixo dele e um Hash marcado por seta embaixo desse, e um Index Scan em customers indentado um nível a mais sob o Hash. À direita, o mesmo plano desenhado como uma árvore de caixas: a caixa Hash Join no topo, as caixas Seq Scan e Hash lado a lado abaixo dela, e a caixa Index Scan abaixo do Hash. Setas apontam para cima de cada caixa filha para a caixa pai, e uma nota diz que as linhas fluem para cima. Uma segunda nota ao lado da caixa Index Scan diz que ela é o primeiro nó a rodar, e uma terceira ao lado do Hash Join diz que ele é o último, e aquele cujas linhas o cliente recebe.\"><text x=\"14\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">como o EXPLAIN imprime</text>\n<text x=\"14\" y=\"52\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hash Join</text>\n<text x=\"14\" y=\"70\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">  Hash Cond: (o.customer_id = c.id)</text>\n<text x=\"14\" y=\"88\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">  -&gt;  Seq Scan on orders o</text>\n<text x=\"14\" y=\"106\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">  -&gt;  Hash</text>\n<text x=\"14\" y=\"124\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">        -&gt;  Index Scan on customers c</text>\n<text x=\"14\" y=\"142\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">              Index Cond: (email = ...)</text>\n<text x=\"14\" y=\"180\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a indentação é a árvore; -&gt; marca um filho</text>\n<line x1=\"340\" y1=\"12\" x2=\"340\" y2=\"304\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"366\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">o mesmo plano, como árvore</text>\n<rect x=\"446\" y=\"40\" width=\"150\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"521\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hash Join</text>\n<rect x=\"366\" y=\"134\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"431\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Seq Scan orders</text>\n<rect x=\"546\" y=\"134\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"611\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hash</text>\n<rect x=\"531\" y=\"228\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"611\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Index Scan customers</text>\n<path d=\"M431 134 L431 100 L521 100 L521 74\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M515 84 L521 74 L527 84\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M611 134 L611 100 L521 100\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M611 228 L611 168\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M605 178 L611 168 L617 178\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<text x=\"366\" y=\"100\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">as linhas sobem</text>\n<text x=\"366\" y=\"245\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">roda primeiro: o filho mais fundo</text>\n<text x=\"366\" y=\"290\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">roda por último: a raiz, cujas linhas o cliente recebe</text>\n</svg>", "caption": "O texto indentado e a árvore são uma estrutura só. Cada nó puxa linhas dos filhos e empurra para o pai, então o filho mais fundo roda primeiro e a raiz termina por último."}
```

A junção aqui é a da aula 5: um cliente, achado por email pelo índice, junto aos pedidos dele. E o
plano diz algo que a consulta não diz: para achar treze pedidos ele leu **o milhão inteiro** —
`Seq Scan on orders`, com `rows=1000000` — e casou todos contra um hash de um cliente. É o índice
que falta em `orders.customer_id`, da aula 9, visto do outro lado. Nada no SQL está errado; o
plano é como você descobre que o esquema está.

## Outras formas da mesma coisa

O `EXPLAIN` imprime texto porque uma pessoa o lê. Ferramentas também leem, e para elas há uma
forma estruturada:

```
shop=# EXPLAIN (FORMAT JSON) SELECT * FROM customers WHERE email = 'user42@example.com';
                         QUERY PLAN                         
------------------------------------------------------------
 [                                                         +
   {                                                       +
     "Plan": {                                             +
       "Node Type": "Index Scan",                          +
       "Parallel Aware": false,                            +
       "Async Capable": false,                             +
       "Scan Direction": "Forward",                        +
       "Index Name": "customers_email_key",                +
       "Relation Name": "customers",                       +
       "Alias": "customers",                               +
       "Startup Cost": 0.42,                               +
       "Total Cost": 8.44,                                 +
       "Plan Rows": 1,                                     +
       "Plan Width": 56,                                   +
       "Index Cond": "(email = 'user42@example.com'::text)"+
     }                                                     +
   }                                                       +
 ]
(1 row)
```

O mesmo plano, cada campo nomeado. `EXPLAIN (FORMAT JSON)` é o que um visualizador de planos
consome, e vale conhecer os nomes — `Plan Rows`, `Total Cost` — porque são as mesmas coisas do
texto, e um visualizador que desenha uma caixa vermelha está desenhando um desses números.

## O que o EXPLAIN sozinho não consegue dizer

Tudo acima é previsão. As linhas são estimadas, os custos são estimados, e a consulta nunca rodou.
Um plano pode parecer perfeito e ser lento, porque o planejador trabalhava com números errados — e
descobrir isso exige que a consulta execute de verdade, que é a próxima seção.
