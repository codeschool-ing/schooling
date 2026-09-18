---
title: Tabelas derivadas, e os três formatos que você já escreveu
version: 1
---

Uma subconsulta no `FROM` é uma **tabela derivada**: uma tabela que existe pela duração de uma
instrução e não tem nome em disco. Tudo o que funciona numa tabela de verdade funciona nela — dá
para juntar, agrupar, juntar duas delas entre si.

Três formatos de aulas anteriores são todos isto, o que vale reunir num lugar só porque você vai
escrevê-los pelo resto da vida profissional.

## Um · filtrar por algo que você calculou

A aula 6 não conseguiu escrever `HAVING orders > 3` de forma portável, porque o PostgreSQL não
aceita um nome de saída ali. Calcule dentro, filtre fora, e o problema desaparece:

```sql
SELECT *
FROM  (SELECT customer_id, count(*) AS orders FROM orders GROUP BY customer_id) t
WHERE t.orders > 3;
```

Uma vez que a agregação é coluna de uma tabela, o filtro é um `WHERE` comum. Também é o único jeito
de filtrar por uma função de **janela**, pela razão de ordem de execução que a aula 6 deu:

```sql
SELECT * FROM (
    SELECT o.*, row_number() OVER (PARTITION BY customer_id ORDER BY ordered_on DESC) AS n
    FROM   orders o
) t
WHERE t.n <= 3;
```

## Dois · agregar cada lado antes de juntar

As aulas 5 e 6 chegaram aqui, por caminhos diferentes, e é a cura geral para a multiplicação da
junção:

```sql
SELECT o.id, coalesce(l.items, 0) AS items, coalesce(p.paid, 0) AS paid
FROM   orders o
LEFT JOIN (SELECT order_id, sum(quantity) AS items FROM order_lines GROUP BY order_id) l
       ON l.order_id = o.id
LEFT JOIN (SELECT order_id, sum(amount)   AS paid  FROM payments    GROUP BY order_id) p
       ON p.order_id = o.id;
```

Cada tabela derivada é uma linha por pedido. Duas coisas que são cada uma uma-por-pedido não podem
multiplicar uma à outra, e é esse o argumento inteiro.

## Três · dar nome a uma expressão bagunçada

```sql
SELECT bucket, count(*)
FROM  (SELECT CASE WHEN total < 50 THEN 'small'
                   WHEN total < 200 THEN 'medium'
                   ELSE 'large' END AS bucket
       FROM orders) t
GROUP BY bucket;
```

`GROUP BY` não pode conter subconsulta e repetir um `CASE` em duas cláusulas é como eles se afastam
um do outro. Calcule uma vez, agrupe por fora.

## Uma tabela derivada não enxerga a consulta em volta

É esta a diferença para a seção anterior, e ela é absoluta:

```sql
SELECT c.name, t.last
FROM   customers c
JOIN  (SELECT max(ordered_on) AS last FROM orders WHERE customer_id = c.id) t ON true;
```

```
ERROR:  invalid reference to FROM-clause entry for table "c"
```

A tabela derivada é avaliada antes da junção, então `c` ainda não existe. Uma subconsulta
correlacionada na lista do `SELECT` pode se referir para fora; uma no `FROM` não pode.

A menos que você diga `LATERAL`, que a aula 5 mencionou e deixou para esta aula:

```sql
SELECT c.name, t.*
FROM   customers c
CROSS JOIN LATERAL (
    SELECT o.id, o.ordered_on FROM orders o
    WHERE  o.customer_id = c.id
    ORDER BY o.ordered_on DESC
    LIMIT  3
) t;
```

`LATERAL` diz: rode isto uma vez por linha do que veio antes, com os valores daquela linha
disponíveis. É o único jeito de escrever "os três primeiros por grupo" com um `LIMIT` em vez de uma
função de janela, e é a ferramenta certa quando a consulta de dentro é cara e o limite poupa
trabalho de verdade. PostgreSQL e MySQL 8 têm; o SQLite não. Use `CROSS JOIN LATERAL` quando toda
linha de fora precisa ter par e `LEFT JOIN LATERAL … ON true` quando não precisa.

## Onde o filtro vai parar

Uma coisa útil de saber, e que você pode conferir em vez de acreditar:

```sql
SELECT * FROM (SELECT * FROM orders) t WHERE t.customer_id = 7;
```

O planejador empurra essa condição para **dentro**, então a tabela derivada nunca monta mil linhas
para jogar 999 fora. É comportamento padrão e é por isso que uma tabela derivada normalmente não
custa nada.

Nem sempre acontece. Um filtro não pode ser empurrado através de uma função de janela, nem de um
`DISTINCT`, nem de um `LIMIT`, porque fazê-lo mudaria a resposta — um `row_number()` calculado sobre
menos linhas é outro `row_number()`. Então isto:

```sql
SELECT * FROM (
    SELECT o.*, row_number() OVER (ORDER BY ordered_on) AS n FROM orders o
) t
WHERE t.customer_id = 7;
```

numera todo pedido da tabela e depois fica com os de um cliente. Se você queria a numeração por
cliente, o `WHERE` pertence lá dentro, ou o `PARTITION BY` pertence à janela — e são duas perguntas
diferentes com duas respostas diferentes.

**Quando uma tabela derivada é mais lenta do que você esperava, é a primeira coisa a conferir**, e a
aula 10 mostra como ver em vez de adivinhar.

## Nomeie tudo

```sql
FROM (SELECT customer_id, count(*) FROM orders GROUP BY customer_id) t
```

`t.count`? `t.?column?`? Depende do banco, e uma coluna sem nome numa tabela derivada é uma consulta
que quebra quando alguém atualiza a versão. Escreva `count(*) AS orders`, e dê apelido à tabela
derivada mesmo onde o SQLite deixaria você pular.

E quando você se pegar aninhando isto três níveis, pare e leia a próxima seção. É a mesma consulta
com os passos nomeados.
