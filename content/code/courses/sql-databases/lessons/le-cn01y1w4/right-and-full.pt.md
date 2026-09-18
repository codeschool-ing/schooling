---
title: RIGHT e FULL, brevemente e com uma recomendação
version: 1
---

## RIGHT JOIN

Mantém toda linha da tabela da **direita** em vez da esquerda:

```sql
SELECT c.name, o.id
FROM   customers c
RIGHT JOIN orders o ON o.customer_id = c.id;
```

Todo pedido aparece, incluindo o 1005 sem cliente, e o `c.name` dele é nulo.

**É exatamente um `LEFT JOIN` com as tabelas trocadas**, e a troca é a recomendação:

```sql
FROM orders o LEFT JOIN customers c ON c.id = o.customer_id
```

Mesmas linhas, mesma resposta, e lê na direção de que a consulta trata — *todo pedido, com o cliente
dele onde houver.*

> **Escreva `LEFT JOIN`. Troque as tabelas em vez de buscar o `RIGHT`.**

Não porque o `RIGHT` seja quebrado, mas porque quem percorre uma consulta monta a figura de cima para
baixo, e um `RIGHT JOIN` três tabelas adiante significa que a coisa de que a consulta trata está mais
embaixo na lista em vez de no começo. Misture os dois numa consulta e quase ninguém consegue dizer
qual é o conjunto de resultados sem resolver no papel.

Você ainda vai encontrar — normalmente numa consulta que cresceu uma tabela por vez — e reconhecer é
tudo de que você precisa.

## FULL OUTER JOIN

Mantém tudo dos dois lados:

```sql
SELECT c.name, o.id
FROM   customers c
FULL JOIN orders o ON o.customer_id = c.id;
```

```
 name       | id
------------+------
 Ana Lopes  | 1001
 Ana Lopes  | 1003
 Ana Lopes  | 1004
 Bruno Sá   | 1002
 Célia Reis | NULL    <- um cliente sem pedido
 NULL       | 1005    <- um pedido sem cliente
```

Os dois tipos de órfão, num resultado. É genuinamente raro em código de aplicação e genuinamente útil
para um trabalho: **reconciliação**.

```sql
SELECT coalesce(a.reference, b.reference) AS reference,
       a.amount AS ours,
       b.amount AS theirs
FROM   our_ledger   a
FULL JOIN their_statement b ON b.reference = a.reference
WHERE  a.reference IS NULL          -- só eles têm
   OR  b.reference IS NULL          -- só nós temos
   OR  a.amount <> b.amount;        -- os dois têm e discordam
```

Essa é a consulta para *"em que estes dois sistemas discordam"*, e ela acha os três tipos de
discordância de uma vez. Todo sistema financeiro, toda importação, toda migração acaba precisando.

Note o `coalesce` na primeira coluna: qualquer lado pode ser nulo, então nenhum sozinho te dá a
referência.

## Qual usar, como uma tabela

| você quer | escreva |
|---|---|
| só linhas que pareiam | `JOIN` |
| toda linha da tabela de que a pergunta trata | `LEFT JOIN`, com aquela tabela primeiro |
| toda linha da outra | troque as tabelas e use `LEFT JOIN` |
| os dois conjuntos de órfãos | `FULL JOIN` |
| todo par, deliberadamente | `CROSS JOIN` — a seção `the-other-joins` |

Na prática, ao longo de uma carreira: a grande maioria `JOIN`, uma minoria substancial `LEFT JOIN`,
`FULL JOIN` um punhado de vezes, e `RIGHT JOIN` principalmente lendo código dos outros.

## O MySQL não tem FULL JOIN

Vale saber antes da aula 12, porque é a lacuna em que as pessoas esbarram:

```sql
SELECT … FROM a LEFT JOIN b ON …
UNION
SELECT … FROM a RIGHT JOIN b ON …;
```

Uma junção à esquerda e uma à direita, unidas — `UNION` e não `UNION ALL`, porque as linhas pareadas
aparecem nas duas metades e as duplicatas têm que sair. Funciona, é mais lento, e é a solução padrão.
O SQLite ganhou `FULL JOIN` em 2022; o MariaDB ainda não.
