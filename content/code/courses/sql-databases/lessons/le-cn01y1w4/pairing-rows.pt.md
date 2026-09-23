---
title: Uma junção pareia linhas. Ela não funde tabelas
version: 2
---

Uma frase decide se junções algum dia parecem simples, então ela vem antes de qualquer sintaxe.

> **Uma junção pareia linhas. Todo par que satisfaz a condição vira uma linha do resultado.**

Não "ela combina duas tabelas em uma". Não "ela anexa o cliente ao pedido". Ela percorre os pares,
mantém os que a condição permite, e cada sobrevivente é uma linha com **todas as colunas dos dois
lados**.

Tudo nesta aula decorre disso, incluindo a parte que dá errado.

## As tabelas desta aula

```
customers                        orders
id  name                         id    customer_id  total
1   Ana Lopes                    1001  1             34.90
2   Bruno Sá                     1002  2             69.80
3   Célia Reis                   1003  1             51.00
                                 1004  1             34.90
                                 1005  NULL          12.00
```

A Ana tem três pedidos, o Bruno tem um, a Célia não tem nenhum, e o pedido 1005 não é de ninguém —
uma compra sem conta, da relação opcional da aula 1.

## Pareando

```sql
SELECT c.name, o.id, o.total
FROM   customers c
JOIN   orders o ON o.customer_id = c.id;
```

```
 name       | id   | total
------------+------+-------
 Ana Lopes  | 1001 | 34.90
 Ana Lopes  | 1003 | 51.00
 Ana Lopes  | 1004 | 34.90
 Bruno Sá   | 1002 | 69.80
```

Quatro linhas. Leia como pares, não como tabela:

- `(Ana, 1001)` — a condição vale, então é uma linha.
- `(Ana, 1002)` — pedido do Bruno, então `o.customer_id = c.id` é falso. Não é linha.
- `(Célia, qualquer)` — nada pareia com ela, então ela está **ausente do resultado por inteiro**.
- `(qualquer, 1005)` — o `customer_id` é nulo, então toda comparação é desconhecida, e desconhecido
  não é verdadeiro. Ausente.

**`Ana Lopes` aparece três vezes**, e isso não é defeito. Ela está em três pares, então há três
linhas, e cada uma carrega uma cópia completa das colunas da linha dela. Essa é a multiplicação, e
tem seção própria.

## Os dois fatos que saem disso

**Uma junção pode produzir mais linhas que qualquer das tabelas tem.** Três clientes e cinco pedidos
deram quatro linhas aqui, e com outra condição poderiam dar quinze. O resultado não é "os clientes,
decorados" — é um conjunto de pares, e quantos há depende dos dados.

**Uma junção pode produzir menos.** A Célia e o pedido 1005 sumiram. Ninguém foi avisado. Se a
pergunta era *"quantos clientes temos"*, esta consulta responde 2 e a verdade é 3 — que é a falha
para a qual o `left-join` existe, e a razão de aquela seção importar mais do que parece.

## Onde a condição vai

```sql
FROM customers c JOIN orders o ON o.customer_id = c.id
```

O `ON` diz quais pares sobrevivem. Quase sempre é uma igualdade entre uma chave estrangeira e a
chave que ela referencia — é para isso que a aula 1 construiu as colunas, e é por que um esquema bem
formado torna junções óbvias.

Não precisa ser:

```sql
ON o.customer_id = c.id AND o.total > 50      -- pairs, further restricted
ON o.created_at BETWEEN c.joined_on AND c.left_on   -- a range, not an equality
ON true                                        -- every pair, which is a CROSS JOIN
```

A diferença entre pôr uma condição no `ON` e pôr no `WHERE` é nenhuma numa junção comum — e é o bug
mais comum deste curso num `LEFT JOIN`. É a seção `on-against-where`, e é a que vale ler duas vezes.

## O modelo mental a carregar

Quando você lê uma junção, faça três perguntas nesta ordem:

1. **O que é uma linha do resultado?** Não "um cliente" — *um cliente pareado com um dos pedidos
   dele*. Dizer como par é o que torna o resto óbvio.
2. **Quantas vezes cada linha do lado esquerdo aparece?** Uma por casamento. Zero se nenhum, que é o
   silêncio da junção interna.
3. **Quais linhas não têm parceiro, e a pergunta queria elas?**

Quase todo bug de junção é um desses três respondido errado, e nenhum deles é sobre sintaxe.
