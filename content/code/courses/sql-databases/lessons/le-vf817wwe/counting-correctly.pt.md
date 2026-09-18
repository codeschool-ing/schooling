---
title: Contar direito, que é onde junções e agregações se encontram
version: 1
---

A aula 5 disse que uma junção pareia linhas e que o pareamento multiplica. Agora você tem funções
que somam essas linhas, e os dois fatos se encontram. Esta é a seção de maior valor prático da aula,
porque todo bug dela produz um número plausível em vez de um erro.

## A que todo mundo escreve

*"Quantos pedidos cada cliente fez?"* Clientes sem nenhum precisam aparecer com zero, então é um
`LEFT JOIN`:

```sql
SELECT   c.name, count(*) AS orders
FROM     customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;
```

A Célia nunca comprou. A linha dela diz **1**.

Nada deu errado na junção: um `LEFT JOIN` mantém a linha da esquerda sem par e preenche as colunas
da direita com nulos, então a Célia está no resultado exatamente uma vez, numa linha em que toda
coluna `o.` é nula. `count(*)` conta linhas. Há uma linha. Ele diz um.

```sql
SELECT   c.name, count(o.id) AS orders
FROM     customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;
```

A Célia diz **0**, porque `count(o.id)` pula os nulos — a regra da primeira seção desta aula,
fazendo algo útil pela primeira vez.

> **Depois de um `LEFT JOIN`, conte uma coluna da tabela da direita, nunca `count(*)`.**

E a coluna que você contar tem que ser uma que não possa ser nula numa linha de verdade pareada: a
chave primária é sempre segura, uma coluna anulável não é. `count(o.shipped_at)` contaria pedidos
enviados, que pode muito bem ser outro número, e nenhum erro vai lhe dizer isso.

Somas têm o mesmo formato e um sintoma diferente. `sum(o.total)` para a Célia é nulo, não zero,
porque somar nenhum valor não tem resposta — então envolva:

```sql
SELECT   c.name, count(o.id) AS orders, coalesce(sum(o.total), 0) AS spent
FROM     customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;
```

## A multiplicação, agora que está sendo somada

O pior caso da aula 5 eram duas junções um-para-muitos a partir da mesma tabela. Eis o que as
agregações fazem com isso:

```sql
SELECT   o.id, sum(l.quantity) AS items, sum(p.amount) AS paid
FROM     orders o
JOIN     order_lines l ON l.order_id = o.id
JOIN     payments    p ON p.order_id = o.id
GROUP BY o.id;
```

Três linhas e dois pagamentos fazem seis linhas. Toda quantidade é somada duas vezes e todo
pagamento três. As duas colunas estão erradas, as duas estão na ordem de grandeza certa, e a
consulta lê perfeitamente.

`count(DISTINCT …)` salva as contagens:

```sql
count(DISTINCT l.id)   -- 3, correto
count(DISTINCT p.id)   -- 2, correto
```

**Não salva as somas.** Não existe `sum(DISTINCT l.quantity)` que queira dizer alguma coisa:
*valores* distintos não é *linhas* distintas, então duas linhas de quantidade 2 virariam uma só e o
total cairia para 2. De vez em quando alguém escreve isso e o número fica silenciosamente menor.

A correção é a que a aula 5 deu, e vale repetir porque é a resposta geral: **agregue cada lado
separadamente e depois junte os resumos.**

```sql
SELECT o.id, coalesce(l.items, 0) AS items, coalesce(p.paid, 0) AS paid
FROM   orders o
LEFT JOIN (SELECT order_id, sum(quantity) AS items FROM order_lines GROUP BY order_id) l
       ON l.order_id = o.id
LEFT JOIN (SELECT order_id, sum(amount)   AS paid  FROM payments    GROUP BY order_id) p
       ON p.order_id = o.id;
```

Cada subconsulta é uma linha por pedido, então nenhuma pode multiplicar a outra. A aula 7 dá a esse
formato um nome e uma sintaxe mais arrumada; a aritmética é o que importa e ela não muda.

## `count(DISTINCT)` não é de graça

Ele precisa lembrar de todo valor que viu, enquanto `count(*)` só precisa lembrar de um número. Numa
tabela grande isso é a diferença entre uma varredura e uma varredura mais uma ordenação ou uma
tabela hash, e é um motivo comum para uma consulta que era rápida. Quando ele aparece só para
desfazer um leque que você mesmo criou, o formato de agregações separadas acima é ao mesmo tempo
mais rápido e mais honesto.

## A verificação que pega tudo isso

Antes de acreditar numa agregação sobre uma junção, pergunte o que é uma linha da consulta **sem
agrupar**. Diga como uma frase: *"uma linha por pedido por item por pagamento."* Se essa frase tiver
a palavra "por" mais de uma vez, todo `sum` da consulta está contando alguma coisa mais de uma vez.

E depois confira, o que custa uma consulta:

```sql
SELECT count(*) FROM orders;                                   -- 1 000
SELECT count(*) FROM orders o JOIN order_lines l ON …;          -- 3 200
```

Se a segunda for maior e você não esperava que fosse, encontrou a multiplicação antes de ela chegar
a um relatório, em vez de depois.
