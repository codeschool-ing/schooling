---
title: INNER JOIN, o que você mais escreve
version: 1
---

```sql
SELECT c.name, o.id, o.total
FROM   customers c
INNER JOIN orders o ON o.customer_id = c.id;
```

`INNER` é o padrão, então quase ninguém escreve:

```sql
FROM customers c JOIN orders o ON o.customer_id = c.id
```

**Só pares que satisfazem a condição sobrevivem.** Uma linha de qualquer lado sem parceiro não está
no resultado, e nada avisa.

## Os apelidos não são decoração

```sql
SELECT c.name, o.id
FROM   customers c
JOIN   orders o ON o.customer_id = c.id;
```

As duas tabelas têm `id`. Escrever `SELECT id` é erro — *column reference "id" is ambiguous* — e esse
erro é o caso bom. O caso ruim são duas tabelas em que só uma tem a coluna hoje, então o nome sem
qualificação funciona, e alguém acrescenta aquela coluna na outra tabela no ano que vem. A consulta
continua válida e agora lê a errada.

> **Qualifique toda coluna numa junção. Mesmo as inequívocas.**

E os apelidos deixam legível: `c` e `o` numa consulta de duas tabelas, nomes curtos com significado
numa de cinco. `customers AS c` é a grafia padrão e `customers c` é a mesma coisa.

## A sintaxe antiga, e por que vale reconhecer

Você vai encontrar isto em código existente:

```sql
SELECT c.name, o.id
FROM   customers c, orders o
WHERE  o.customer_id = c.id;
```

Uma vírgula entre tabelas significa todo par, e o `WHERE` então joga a maioria fora. Produz a mesma
resposta que a junção explícita acima e é pior em dois aspectos:

- **A condição de junção e os filtros ficam misturados.** Lendo uma consulta de cinco tabelas nesse
  estilo, você não distingue de relance quais condições conectam as tabelas e quais selecionam
  linhas.
- **Esquecer uma não é erro.** Omita `WHERE o.customer_id = c.id` e você recebe todo cliente pareado
  com todo pedido — três vezes cinco linhas aqui, e três milhões vezes cinco milhões num sistema
  real. A consulta roda, devolve absurdo, e leva o banco junto.

`JOIN … ON` explícito não pode ser esquecido do mesmo jeito: o `ON` é parte da sintaxe. Use.

## Uma junção interna é simétrica

```sql
FROM customers c JOIN orders o ON o.customer_id = c.id
FROM orders o JOIN customers c ON c.id = o.customer_id
```

Mesmas linhas, mesma resposta. Nada no `INNER JOIN` prefere um lado, então qual tabela vem primeiro é
decisão de legibilidade — comece pela coisa de que a consulta *trata*, e junte o que a decora.

**Isso deixa de ser verdade no `LEFT JOIN`**, onde os lados significam coisas diferentes. É a seção
depois da próxima, e é a razão de quem aprendeu junções como "combinar tabelas" travar.

## A condição pode ser qualquer coisa, e normalmente não é

Quase toda junção que você escrever será uma igualdade sobre uma chave estrangeira:

```sql
ON o.customer_id = c.id
```

Isso não é regra do SQL; é o que um esquema normalizado torna natural, e vale notar que as aulas 1 e
2 estavam construindo exatamente para isto. Uma tabela com uma lista numa célula, ou um nome repetido
em vez de uma referência, não pode ser juntada — que é o custo prático dos formatos que aquelas aulas
recusaram.

Quando a condição é outra coisa, vale um comentário:

```sql
-- um preço válido na época do pedido, não o atual
JOIN price_history p
  ON p.product_id = l.product_id
 AND o.ordered_on BETWEEN p.valid_from AND p.valid_to
```

Isso é uma junção por faixa, é um padrão real, e é também onde a multiplicação da próxima seção morde
mais forte — se duas linhas de `price_history` se sobrepõem, todo pedido na sobreposição é contado
duas vezes, e nada recusa.
