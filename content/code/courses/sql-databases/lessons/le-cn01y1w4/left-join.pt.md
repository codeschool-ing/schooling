---
title: LEFT JOIN, e as linhas que estavam sumindo
version: 1
---

A Célia nunca pediu. Uma junção interna a deixa de fora, e nada avisa.

Na maior parte do tempo isso está errado, porque as perguntas que as pessoas de fato fazem são sobre
todo mundo:

- *Quanto cada cliente gastou?* — a Célia gastou zero, e zero é uma resposta.
- *Quais produtos nunca venderam?* — pergunta inteiramente sobre linhas sem parceiro.
- *Mostre todo pedido com o envio dele* — pedidos ainda não enviados são o que alguém procura.

```sql
SELECT c.name, o.id, o.total
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id;
```

```
 name       | id   | total
------------+------+-------
 Ana Lopes  | 1001 | 34.90
 Ana Lopes  | 1003 | 51.00
 Ana Lopes  | 1004 | 34.90
 Bruno Sá   | 1002 | 69.80
 Célia Reis | NULL | NULL
```

Cinco linhas. **Toda linha da tabela da esquerda aparece pelo menos uma vez**; onde não há parceiro,
as colunas da direita são preenchidas com `NULL`.

## O que `LEFT` significa, exatamente

> **Mantenha toda linha da tabela da esquerda. Pareie onde der. Onde não der, invente um par com
> nulos à direita.**

`LEFT OUTER JOIN` é a grafia completa; o `OUTER` é opcional e quase ninguém escreve.

**Os lados agora significam coisas diferentes**, que é a diferença para a junção interna:

```sql
FROM customers c LEFT JOIN orders o ON …    -- todo cliente, pedidos onde houver
FROM orders o LEFT JOIN customers c ON …    -- todo pedido, clientes onde houver
```

São consultas diferentes. A primeira mantém a Célia; a segunda mantém o pedido 1005, a compra sem
conta. Qual você quer depende da pergunta, e inverter produz um resultado que parece bom e responde
outra coisa.

O hábito: **ponha na esquerda a tabela de que a pergunta trata.**

## Os nulos que ela cria não estão nos dados

Isso pega todo mundo uma vez. `o.total` é `NOT NULL` na tabela — a aula 3 declarou — e aqui está ele,
nulo.

O nulo não foi lido de lugar nenhum. **A junção o inventou**, porque não havia linha de onde tirar um
valor. O que significa que toda regra da aula 1 se aplica a ele:

```sql
SELECT c.name, sum(o.total) FROM customers c LEFT JOIN orders o ON … GROUP BY c.name;
```

A soma da Célia é `NULL`, não `0` — porque `sum` de nada é desconhecido e não zero. Quase sempre o
que você quer mostrar é zero:

```sql
SELECT c.name, coalesce(sum(o.total), 0) AS spent
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.name;
```

E a contagem precisa de cuidado pelo mesmo motivo:

```sql
count(*)        -- 1 para a Célia: existe uma linha, a inventada
count(o.id)     -- 0 para a Célia: a coluna é nula e count ignora nulos
```

**`count(*)` depois de um `LEFT JOIN` quase sempre é o bug.** Ele conta linhas, e a Célia tem uma
linha. `count(o.id)` conta pedidos, que é o que alguém queria. Esta é a coisa mais útil a lembrar
sobre contar depois de uma junção externa.

## Lendo uma

Quando você vir um `LEFT JOIN`, três perguntas:

1. **Qual é a tabela da esquerda?** É o conjunto de linhas de que a resposta trata.
2. **Quais colunas agora podem ser nulas e não eram?** Todas as do lado direito.
3. **Alguma coisa adiante trata esses nulos corretamente?** O `count(*)`, o `sum`, o `WHERE` — cada
   um tem uma regra da aula 1 e cada uma se aplica.

Essa terceira pergunta é a próxima seção inteira, porque existe um lugar onde uma condição pode ir
que transforma um `LEFT JOIN` de volta numa junção interna sem avisar.
