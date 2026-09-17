---
title: As outras junções, e uma a evitar
version: 1
---

## CROSS JOIN

Toda linha de uma tabela pareada com toda linha da outra, sem condição nenhuma:

```sql
SELECT c.name, s.size FROM colours c CROSS JOIN sizes s;
```

Quatro cores e três tamanhos dá doze linhas. É a única junção cuja contagem de linhas você prevê
exatamente, e é certa quando você genuinamente quer toda combinação:

- **toda variante de um produto** — cor por tamanho — para semear uma tabela;
- **todo dia de uma faixa contra toda loja**, para um relatório ter um zero nos dias em que nada foi
  vendido em vez de uma lacuna;
- **uma pequena tabela de apoio juntada a tudo**, como uma linha de configurações.

Essa segunda vale conhecer, porque "o relatório está sem os dias sem venda" é uma pergunta que as
pessoas resolvem editando a planilha depois:

```sql
SELECT d.day, s.name, coalesce(sum(o.total), 0) AS sales
FROM   generate_series('2026-03-01'::date, '2026-03-31', '1 day') AS d(day)
CROSS JOIN shops s
LEFT JOIN orders o ON o.shop_id = s.id AND o.ordered_on = d.day
GROUP BY d.day, s.name;
```

Uma linha para toda loja em todo dia, tenha acontecido algo ou não. É um `CROSS JOIN` fazendo o
trabalho que nada mais faz.

**E um acidental é catástrofe.** A sintaxe de vírgula da seção `inner-join` produz uma junção
cruzada quando o `WHERE` é esquecido — um milhão de linhas contra um milhão é um trilhão, e o banco
vai tentar. Um `CROSS JOIN` escrito de propósito é seguro porque alguém digitou as palavras.

## USING

Atalho para uma igualdade sobre uma coluna de mesmo nome nas duas tabelas:

```sql
FROM orders o JOIN customers c USING (customer_id)    -- se as duas chamarem assim
FROM orders o JOIN customers c ON c.customer_id = o.customer_id
```

É mais curto, e faz uma coisa que vale saber: **a coluna juntada aparece uma vez no resultado** em
vez de duas, e pode ser referida sem qualificação.

Só funciona onde os dois lados usam o mesmo nome, o que um esquema seguindo a convenção da aula 3
normalmente não faz — `customers.id` contra `orders.customer_id`. Onde couber, está bem.

## NATURAL JOIN, que você nunca deve escrever

```sql
FROM orders NATURAL JOIN customers
```

Ele junta por **toda coluna cujo nome as duas tabelas por acaso compartilham**, sem condição escrita
em lugar nenhum.

Isso soa conveniente e é uma armadilha com temporizador. Hoje a coluna compartilhada é `customer_id`
e a consulta está certa. Aí alguém acrescenta `created_at` nas duas tabelas — coisa perfeitamente
comum, numa migração sem relação — e a junção silenciosamente vira *"o mesmo cliente **e** criado no
mesmo instante"*.

O resultado quase sempre é vazio. Nada mudou na consulta. Nada deu erro. A migração que quebrou não
mencionou.

> **A condição de junção deve estar visível na consulta que depende dela.** O `NATURAL JOIN` a faz
> depender da nomenclatura do esquema, que não está sob o controle daquela consulta e muda sem
> referência a ela.

Reconheça no código dos outros, e substitua pelo `ON` que ele queria dizer.

## LATERAL

Uma junção cujo lado direito pode se referir ao esquerdo. É propriamente da aula 7, e está nesta
lista porque resolve uma pergunta que junções de outro modo não resolvem:

```sql
SELECT c.name, o.id, o.total
FROM   customers c
LEFT JOIN LATERAL (
    SELECT id, total FROM orders o
    WHERE  o.customer_id = c.id
    ORDER BY o.ordered_on DESC
    LIMIT  3
) o ON true;
```

**Os três pedidos mais recentes de cada cliente.** Uma junção comum não consegue — ela não tem como
dizer "por linha da tabela da esquerda" — e sem `LATERAL` isso precisa de uma função de janela e um
filtro.

`ON true` é idiomático: o pareamento já foi decidido dentro da subconsulta, então a condição de
junção não tem mais o que dizer.

## O conjunto inteiro

| | mantém | quando |
|---|---|---|
| `JOIN` | só os pares | na maior parte do tempo |
| `LEFT JOIN` | toda linha da esquerda | a pergunta inclui linhas sem nada |
| `RIGHT JOIN` | toda linha da direita | troque as tabelas e use `LEFT` |
| `FULL JOIN` | tudo | reconciliando duas fontes |
| `CROSS JOIN` | toda combinação | gerando uma grade de propósito |
| `LATERAL` | subconsulta por linha | top N por grupo, e tudo que precise da linha da esquerda |
| `NATURAL JOIN` | — | nunca |
