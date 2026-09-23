---
title: HAVING filtra grupos, WHERE filtra linhas
version: 2
---

Duas aulas prometeram esta seção, então aqui está a frase que elas prometiam:

> **`WHERE` roda antes do agrupamento e decide quais linhas entram. `HAVING` roda depois dele e
> decide quais grupos saem.**

Todo o resto sobre o `HAVING` decorre disso, inclusive por que ele existe — quando você já tem uma
contagem, as linhas que foram contadas sumiram, e o `WHERE` terminou faz tempo.

A ordem de execução da aula 4, estendida com as duas cláusulas que esta aula acrescenta:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 160\" role=\"img\" aria-label=\"Sete etapas em fila, da esquerda para a direita, com setas entre elas: FROM, WHERE, GROUP BY, HAVING, SELECT, ORDER BY e LIMIT. WHERE e HAVING estão acesas como as duas peneiras, WHERE rotulada como joga linhas fora e HAVING como joga pilhas fora. Uma linha vertical tracejada cai logo depois do GROUP BY, com nenhum agregado existe ainda escrito à esquerda dela e agregados existem à direita.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">A ordem em que o banco roda as cláusulas, que não é a ordem em que são escritas.</text><rect x=\"14\" y=\"56\" width=\"84\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"56.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">FROM</text><path d=\"M100 71 L108 71\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M108 71 L102 68 L102 74 Z\" fill=\"var(--wire)\"></path><rect x=\"110\" y=\"56\" width=\"84\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"152.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">WHERE</text><path d=\"M196 71 L204 71\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M204 71 L198 68 L198 74 Z\" fill=\"var(--wire)\"></path><rect x=\"206\" y=\"56\" width=\"96\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"254.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">GROUP BY</text><path d=\"M304 71 L312 71\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M312 71 L306 68 L306 74 Z\" fill=\"var(--wire)\"></path><rect x=\"314\" y=\"56\" width=\"84\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"356.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">HAVING</text><path d=\"M400 71 L408 71\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M408 71 L402 68 L402 74 Z\" fill=\"var(--wire)\"></path><rect x=\"410\" y=\"56\" width=\"84\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"452.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">SELECT</text><path d=\"M496 71 L504 71\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M504 71 L498 68 L498 74 Z\" fill=\"var(--wire)\"></path><rect x=\"506\" y=\"56\" width=\"96\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"554.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">ORDER BY</text><path d=\"M604 71 L612 71\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M612 71 L606 68 L606 74 Z\" fill=\"var(--wire)\"></path><rect x=\"614\" y=\"56\" width=\"84\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"656.0\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">LIMIT</text><path d=\"M308.0 44 L308.0 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" fill=\"none\"></path><text x=\"300.0\" y=\"38\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">nenhum agregado existe ainda</text><text x=\"316.0\" y=\"38\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">agregados existem</text><path d=\"M152.0 88 L152.0 104\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><text x=\"152.0\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">joga linhas fora</text><path d=\"M356.0 88 L356.0 104\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><text x=\"356.0\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">joga pilhas fora</text><text x=\"14\" y=\"148\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Um agregado no WHERE não é uma regra para decorar: a essa altura nada foi contado.</text></svg>", "caption": "A linha tracejada é a seção inteira. WHERE fica à esquerda dela e HAVING à direita, e toda regra sobre qual das duas aceita um agregado decorre de onde elas estão."}
```

Leia essa lista e o erro que você está prestes a encontrar deixa de ser misterioso:

```sql
SELECT customer_id FROM orders WHERE count(*) > 3 GROUP BY customer_id;
```

```
ERROR:  aggregate functions are not allowed in WHERE
```

Quando o `WHERE` roda, não há grupos e não há contagem — há uma linha, sozinha, e `count(*)` de uma
linha não é uma pergunta. Mude de lugar:

```sql
SELECT   customer_id, count(*)
FROM     orders
GROUP BY customer_id
HAVING   count(*) > 3;
```

## A consulta que precisa dos dois, que é a maioria delas

*"Clientes com mais de três pedidos em 2026."* Duas condições, e elas vão em cláusulas diferentes,
porque uma é sobre uma linha e a outra é sobre uma pilha:

```sql
SELECT   customer_id, count(*) AS orders_2026
FROM     orders
WHERE    ordered_on >= DATE '2026-01-01'
  AND    ordered_on <  DATE '2027-01-01'
GROUP BY customer_id
HAVING   count(*) > 3;
```

O ano é uma propriedade de um pedido, então é `WHERE`. A contagem é uma propriedade da pilha do
cliente, então é `HAVING`. Troque os dois e um deles é erro e o outro é outra pergunta inteiramente
— `HAVING max(ordered_on) >= DATE '2026-01-01'` daria os clientes com mais de três pedidos **na
vida**, que também compraram pelo menos uma vez em 2026. É uma pergunta de verdade, e não é a de
cima.

Que é a distinção honesta para levar embora: as duas cláusulas não são dois jeitos de escrever um
filtro. Mudar onde uma condição fica muda o sentido, não o estilo.

## Um `HAVING` sem agregação dentro

É legal e quase sempre é um erro:

```sql
SELECT   customer_id, count(*)
FROM     orders
GROUP BY customer_id
HAVING   customer_id <> 7;          -- works, and belongs in WHERE
```

Dá a resposta certa. Também agrupa cada um dos pedidos do cliente 7, calcula a contagem deles, e
depois joga o grupo fora. Filtrar no `WHERE` teria pulado essas linhas antes de o agrupamento
começar, o que é menos trabalho — às vezes muito menos, porque um `WHERE` sobre uma coluna indexada
pode evitar ler as linhas, e o `HAVING` nunca pode.

**A regra prática: se a condição pode ser escrita no `WHERE`, escreva no `WHERE`.** `HAVING` é para
condições que precisam de uma agregação, e para mais nada.

## `HAVING` sem `GROUP BY`

Também é legal, e de vez em quando é exatamente certo:

```sql
SELECT sum(total) FROM orders WHERE customer_id = 7 HAVING sum(total) > 1000;
```

Sem `GROUP BY`, a tabela inteira é um grupo, então isso devolve **uma linha ou nenhuma** — o total,
se ele passar do limite, e nada se não passar. É o único caso em que uma consulta com agregação
pode devolver zero linhas, e é um truque útil para "me avise só se importar".

## Apelidos, que não são portáveis aqui

```sql
SELECT   customer_id, count(*) AS orders
FROM     orders
GROUP BY customer_id
HAVING   orders > 3;             -- MySQL and SQLite: yes.  PostgreSQL: error.
```

MySQL e SQLite deixam você nomear a coluna de saída. O PostgreSQL não, mesmo permitindo exatamente
isso no `GROUP BY` — o que é inconsistente, e é culpa do padrão, não deles. As respostas portáveis
são repetir a expressão, ou calcular a agregação numa subconsulta e filtrar por fora, o que lê
melhor conforme a consulta cresce e é assunto da aula 7:

```sql
SELECT *
FROM  (SELECT customer_id, count(*) AS orders FROM orders GROUP BY customer_id) t
WHERE t.orders > 3;
```

Repare no que aconteceu: uma vez que a agregação virou coluna de uma consulta interna, o filtro de
fora é um `WHERE` comum de novo. `HAVING` não é um tipo especial de filtro — é um `WHERE` para um
resultado que você ainda não terminou de calcular.
