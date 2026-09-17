---
title: Funções de janela, que resumem sem colapsar
version: 1
---

Tudo até aqui destrói as linhas que resume. Agrupe por cliente e os pedidos sumiram; você tem os
totais e mais nada. Em geral é o que você quer, e isso torna impossível fazer uma classe inteira de
perguntas.

*"Me mostre cada pedido, e ao lado dele quanto aquele cliente gastou no total."*

Não existe `GROUP BY` para isso, porque a resposta tem uma linha por pedido **e** um número
calculado sobre a pilha inteira do cliente. Antes de as funções de janela existirem você escrevia
uma subconsulta correlacionada por coluna, ou rodava uma segunda consulta e juntava os resultados à
mão. Agora é uma palavra:

```sql
SELECT id, customer_id, total,
       sum(total) OVER (PARTITION BY customer_id) AS customer_total
FROM   orders;
```

Todo pedido volta. Ao lado de cada um está o total do cliente dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três tabelas lado a lado sobre os mesmos quatro pedidos, dois da Ana e dois do Bruno. A primeira são os pedidos em si, quatro linhas. A segunda é o resultado de GROUP BY por cliente, duas linhas contendo apenas os totais. A terceira é o resultado da mesma soma escrita com OVER PARTITION BY, quatro linhas, cada pedido original levando ao lado o total do seu cliente. Abaixo, uma faixa contrasta as duas: GROUP BY dá uma linha por grupo e o pedido individual não pode mais ser visto, enquanto OVER mantém toda linha e dá a cada uma o número do seu grupo, que é o que permite comparar uma linha com o próprio grupo numa consulta só.\"><text x=\"14\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">orders</text>\n<rect x=\"14\" y=\"30\" width=\"170\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"24\" y=\"43\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana     34.90</text>\n<rect x=\"14\" y=\"56\" width=\"170\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"24\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana     51.00</text>\n<rect x=\"14\" y=\"82\" width=\"170\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"24\" y=\"95\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bruno   69.80</text>\n<rect x=\"14\" y=\"108\" width=\"170\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"24\" y=\"121\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bruno   12.00</text>\n<text x=\"14\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4 linhas</text>\n<text x=\"224\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">GROUP BY customer_id</text>\n<rect x=\"224\" y=\"30\" width=\"200\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"234\" y=\"43\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana     85.90</text>\n<rect x=\"224\" y=\"56\" width=\"200\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"234\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bruno   81.80</text>\n<text x=\"224\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 linhas, e os pedidos sumiram</text>\n<text x=\"474\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">OVER (PARTITION BY customer_id)</text>\n<rect x=\"474\" y=\"30\" width=\"232\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"484\" y=\"43\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana     34.90    85.90</text>\n<rect x=\"474\" y=\"56\" width=\"232\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"484\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana     51.00    85.90</text>\n<rect x=\"474\" y=\"82\" width=\"232\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"484\" y=\"95\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bruno   69.80    81.80</text>\n<rect x=\"474\" y=\"108\" width=\"232\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"484\" y=\"121\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bruno   12.00    81.80</text>\n<text x=\"474\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">4 linhas, cada uma com seu total</text>\n<line x1=\"14\" y1=\"178\" x2=\"706\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"14\" y=\"202\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">A mesma soma, sobre a mesma partição</text>\n<text x=\"14\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">GROUP BY</text><text x=\"200\" y=\"228\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma linha por grupo, e nenhum pedido dá mais para ver</text>\n<text x=\"14\" y=\"250\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">OVER (...)</text><text x=\"200\" y=\"250\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">toda linha sobrevive, levando o número do seu grupo ao lado</text>\n<text x=\"14\" y=\"272\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">total - avg</text><text x=\"200\" y=\"272\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">por isso só a segunda compara uma linha com o seu grupo</text>\n</svg>", "caption": "A mesma soma sobre a mesma partição. GROUP BY devolve uma linha por cliente e perde os pedidos; OVER devolve todo pedido com o total do cliente ao lado."}
```

## `PARTITION BY` é `GROUP BY` que não colapsa

A mesma palavra para a mesma ideia, e a única diferença é o que sai:

| | linhas que entram | linhas que saem |
|---|---|---|
| `sum(total)` com `GROUP BY customer_id` | 1 000 | uma por cliente |
| `sum(total) OVER (PARTITION BY customer_id)` | 1 000 | **1 000** |

Deixe os parênteses vazios e a partição é o resultado inteiro:

```sql
SELECT id, total,
       sum(total)   OVER () AS grand_total,
       total * 100 / sum(total) OVER () AS percent_of_all
FROM   orders;
```

Toda linha agora sabe o total de tudo, que é como se calcula uma fatia sem uma segunda consulta.
`count(*) OVER ()` é o mesmo truque para "quantas linhas há ao todo", e é o jeito usual de trazer
uma contagem total junto com uma página de resultados.

## A pergunta que ele realmente destrava

Qualquer uma da forma *"comparado com"*:

```sql
SELECT id, customer_id, total,
       avg(total) OVER (PARTITION BY customer_id)         AS usual,
       total - avg(total) OVER (PARTITION BY customer_id) AS versus_usual
FROM   orders;
```

Cada pedido contra a média do próprio cliente. Um `GROUP BY` não consegue expressar isso de jeito
nenhum, porque um dos dois números é propriedade da linha e o outro é propriedade do grupo — e uma
consulta com `GROUP BY` não tem mais linhas para segurar o primeiro.

Qualquer agregação funciona assim. `count`, `sum`, `avg`, `min`, `max`, `string_agg` — ponha `OVER`
depois e ela para de colapsar.

## Onde isso roda, que decide onde você pode escrever

Estenda a ordem de execução da aula 4 em um passo:

```
FROM → WHERE → GROUP BY → HAVING → funções de janela → SELECT → ORDER BY → LIMIT
```

Duas consequências, e a segunda é a que todo mundo encontra.

**Funções de janela veem as linhas que sobreviveram ao `WHERE` e ao `HAVING`.** Um `WHERE
customer_id = 7` faz `sum(total) OVER ()` ser o total do cliente 7, não o total de todo mundo. A
partição é calculada sobre o que sobrou, nunca sobre a tabela.

**E você não pode filtrar por uma função de janela.**

```sql
SELECT id, total, rank() OVER (ORDER BY total DESC) AS r
FROM   orders
WHERE  r <= 10;                      -- ERROR: column "r" does not exist
```

Quando o `WHERE` roda, nenhuma função de janela rodou. Nem `WHERE` nem `HAVING` ajudam, porque os
dois já terminaram. A resposta é calcular numa consulta e filtrar fora dela:

```sql
SELECT * FROM (
    SELECT id, total, rank() OVER (ORDER BY total DESC) AS r FROM orders
) t
WHERE t.r <= 10;
```

Esse envelope não é um contorno para uma funcionalidade que falta — é a ordem de execução, tornada
visível. A aula 7 dá a ele a sintaxe mais arrumada do `WITH`, e você vai escrever esse formato o
tempo todo.

## Janelas sobre agregações

As duas metades da aula numa consulta, o que é legal e lê como um erro:

```sql
SELECT   customer_id,
         sum(total)                  AS spent,
         sum(sum(total)) OVER ()     AS everyone,
         sum(total) * 100 / sum(sum(total)) OVER () AS percent
FROM     orders
GROUP BY customer_id;
```

`sum(sum(total))` não é erro de digitação. O `sum` de dentro é a agregação, rodada por grupo; o de
fora é uma função de janela, rodada sobre as linhas agrupadas — porque janelas vêm **depois** do
agrupamento, e a essa altura uma linha por cliente é tudo o que existe. A fatia de cada cliente no
todo, numa passada.

## Dar nome a uma janela que você usa mais de uma vez

Repetir um `OVER (…)` longo três vezes é como eles ficam fora de sincronia. Dê nome:

```sql
SELECT   customer_id, total,
         avg(total) OVER w,
         min(total) OVER w,
         max(total) OVER w
FROM     orders
WINDOW   w AS (PARTITION BY customer_id);
```

A cláusula `WINDOW` fica entre o `HAVING` e o `ORDER BY`. PostgreSQL, MySQL 8 e SQLite têm; não muda
nada no resultado e significa uma definição em vez de três.
