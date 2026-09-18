---
title: Subconsultas correlacionadas, que rodam uma vez por linha
version: 1
---

Duas subconsultas que se parecem e não são:

```sql
-- independente: pode ser rodada sozinha, e é rodada uma vez
WHERE price > (SELECT avg(price) FROM products)

-- correlacionada: menciona a consulta de fora, e não pode ser rodada sozinha
WHERE price > (SELECT avg(price) FROM products p2 WHERE p2.category_id = p.category_id)
```

A segunda nomeia `p`, que pertence à consulta em volta. Cole-a sozinha num cliente e é erro de
sintaxe. Essa única referência é o que a torna correlacionada, e ela muda quando a subconsulta roda:
conceitualmente, **uma vez para cada linha da consulta de fora**.

*"Mais caro que a média da própria categoria"* é uma pergunta real que não tem outra grafia curta,
então a forma merece o lugar dela. O custo vale ser dito com honestidade.

## O modelo mental e o que de fato acontece

Pense num laço: para cada produto, calcule a média daquela categoria, compare. Mil produtos, mil
consultinhas.

O banco em geral não faz isso. Um planejador que reconhece o formato o reescreve numa agregação
calculada uma vez por categoria e juntada — mesma resposta por uma fração do trabalho. Mas "em
geral" está trabalhando de verdade nessa frase. Se a reescrita acontece depende do banco, da versão
e do que mais está na consulta, que é por que uma subconsulta correlacionada é o defeito clássico de
"rápido em desenvolvimento, lento em produção": cem linhas escondem e um milhão não.

O formato de que desconfiar é aquele em que a subconsulta não pode ser puxada para fora — algo que
ela calcula depende da linha de fora de um jeito que junção nenhuma expressa. Aí o laço é real.

## Onde ela merece o lugar

**`EXISTS` e `NOT EXISTS`**, que são correlacionados por definição e que a seção anterior recomenda.
Planejadores lidam com eles particularmente bem: uma semijunção ou antijunção para no primeiro par
em vez de contar.

**Uma única coluna escalar**, quando uma é genuinamente tudo de que você precisa:

```sql
SELECT c.name,
       (SELECT max(o.ordered_on) FROM orders o WHERE o.customer_id = c.id) AS last_order
FROM   customers c;
```

Legível, e um cliente sem pedidos recebe `NULL` em vez de sumir — que é o mesmo desfecho de um
`LEFT JOIN` e dá menos trabalho de escrever.

## Onde ela deixa de merecer

Acrescente mais duas colunas e o formato se volta contra você:

```sql
SELECT c.name,
       (SELECT count(*)         FROM orders o WHERE o.customer_id = c.id) AS orders,
       (SELECT max(o.ordered_on) FROM orders o WHERE o.customer_id = c.id) AS last_order,
       (SELECT sum(o.total)     FROM orders o WHERE o.customer_id = c.id) AS spent
FROM   customers c;
```

Três subconsultas sobre a mesma tabela, perguntando sobre as mesmas linhas, três vezes. Um
`LEFT JOIN` com um `GROUP BY` faz tudo numa passada:

```sql
SELECT   c.name, count(o.id) AS orders, max(o.ordered_on) AS last_order,
         coalesce(sum(o.total), 0) AS spent
FROM     customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;
```

Repare no `count(o.id)` em vez de `count(*)`, pela razão da aula 6. A reescrita é um bom hábito por
um teste simples: **quando duas subconsultas correlacionadas nomeiam a mesma tabela, elas querem ser
uma junção.**

## O mesmo bug uma camada acima

Uma aplicação que percorre clientes e roda uma consulta por cliente está fazendo à mão o que uma
subconsulta correlacionada faz dentro do banco — e fazendo muito pior, porque cada iteração é uma
ida e volta pela rede. Isso é o problema N+1, é assunto da aula 11, e vale reconhecer que os dois são
o mesmo erro em altitudes diferentes. Pelo menos o banco tem um planejador que talvez o resgate.

## `UPDATE` correlacionado, e a armadilha dele

Preencher uma coluna desnormalizada é onde a maioria encontra esta forma de verdade:

```sql
UPDATE customers c
SET    order_count = (SELECT count(*) FROM orders o WHERE o.customer_id = c.id);
```

Está correto e atualiza todo cliente, inclusive os sem pedidos — onde `count(*)` sobre nenhuma linha
é `0`, que é o que você quer. Troque a agregação e deixa de ser o que você quer:

```sql
UPDATE customers c
SET    last_order_at = (SELECT max(o.ordered_on) FROM orders o WHERE o.customer_id = c.id);
```

Um cliente sem pedidos agora fica `NULL`, o que pode estar certo, e um cliente cujos pedidos foram
arquivados ontem à noite **também** fica nulo, sobrescrevendo um valor que era verdadeiro. Se você
queria tocar só as linhas que têm par, diga isso:

```sql
UPDATE customers c
SET    last_order_at = (SELECT max(o.ordered_on) FROM orders o WHERE o.customer_id = c.id)
WHERE  EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```

Duas subconsultas correlacionadas, uma no `SET` e uma no `WHERE`, que é comum neste formato.

E rode isso dentro de uma transação, para que um erro seja um `ROLLBACK` e não uma restauração. Isso
é a aula 8, e ela é a próxima por um motivo: daqui em diante, as instruções que você escreve mudam
coisas.
