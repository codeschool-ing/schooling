---
title: Achando o que não está lá
version: 1
---

Algumas das perguntas mais valiosas são sobre ausência:

- clientes que nunca pediram
- produtos que nunca venderam
- pedidos sem pagamento
- usuários que se cadastraram e nunca voltaram

Nenhuma delas é respondível olhando linhas que existem. São perguntas sobre **linhas que não
existem**, e há três jeitos de fazer.

## A anti-junção

```sql
SELECT c.name
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE  o.id IS NULL;
```

Leia em dois passos. O `LEFT JOIN` mantém todo cliente e preenche as colunas da direita com nulos
onde não houve parceiro. Aí o `WHERE o.id IS NULL` mantém exatamente esses — **as linhas em que a
junção não achou nada**.

Esta é a exceção deliberada da seção anterior: uma condição sobre a tabela da direita no `WHERE`, e
aqui ela é o ponto inteiro.

**A coluna que você testa tem que ser uma que não possa ser nula na tabela.** Teste `o.id` — uma
chave primária — e nulo significa "sem parceiro". Teste `o.cancelled_at`, que aceita nulo, e você
também pega pedidos que existem e nunca foram cancelados, que é uma pergunta completamente diferente
e devolve uma resposta errada plausível.

## `NOT EXISTS`

```sql
SELECT c.name
FROM   customers c
WHERE  NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```

A aula 7 cobre subconsultas direito; este formato vale ter agora porque normalmente é o mais claro
dos três.

Ele diz o que significa — *não existe pedido para este cliente* — sem junção sobre a qual raciocinar,
sem nulos inventados, e sem depender de escolher uma coluna não nula. `SELECT 1` é convenção: o
`EXISTS` se importa se uma linha volta, não com o que tem nela.

**Ele também para no primeiro casamento.** Para um cliente com mil pedidos, a anti-junção constrói
linhas que vai descartar; o `NOT EXISTS` acha uma e segue.

## `NOT IN`, que você não deve usar aqui

```sql
SELECT name FROM customers
WHERE  id NOT IN (SELECT customer_id FROM orders);
```

Lê melhor dos três, e **devolve nenhuma linha**, porque `orders.customer_id` aceita nulo e o pedido
1005 tem um. As aulas 1 e 4 avisaram; aqui é onde de fato morde.

`x NOT IN (1, 2, NULL)` se desdobra em `x <> 1 AND x <> 2 AND x <> NULL`, o último termo é
desconhecido, e o `AND` inteiro nunca pode ser verdadeiro. Sem erro. Resultado vazio.

Dá para resgatar — `WHERE customer_id IS NOT NULL` dentro da subconsulta — e aí é uma consulta
correta com uma armadilha em que a próxima pessoa a editar vai cair.

> **Para "não está neste conjunto", escreva `NOT EXISTS`.** Está correto havendo nulos ou não, e não
> exige que quem lê confira.

## Os três, lado a lado

| | correto com nulos | para cedo | lê como a pergunta |
|---|---|---|---|
| `LEFT JOIN … IS NULL` | sim, se você testar coluna não nula | não | mais ou menos |
| `NOT EXISTS` | sim, sempre | sim | sim |
| `NOT IN` | **não** | não | sim |

O desempenho entre os dois primeiros é próximo o bastante para não ser o fator decisivo, e a aula 10
é como você descobriria para uma consulta específica. Correção e clareza apontam as duas para o
`NOT EXISTS`, e isso basta.

## O espelho: "pelo menos um"

Os mesmos três formatos respondem a pergunta positiva, e o mesmo vence:

```sql
-- clientes que JÁ pediram
SELECT name FROM customers c WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- a mesma coisa, mal feita
SELECT DISTINCT c.name FROM customers c JOIN orders o ON o.customer_id = c.id;
```

A segunda é o aviso do `DISTINCT` da aula 4 e a seção da multiplicação, chegando juntos: a junção
constrói uma linha por pedido e depois joga a maioria fora. O `EXISTS` nunca as constrói.

**Sempre que a pergunta for "existe pelo menos um", a resposta é `EXISTS`, não uma junção.** Uma
junção é para quando você quer as colunas da outra tabela; o `EXISTS` é para quando você só quer
saber.
