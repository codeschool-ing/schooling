---
title: Mais de duas tabelas, e uma tabela juntada consigo mesma
version: 1
---

Junções encadeiam. Cada uma pareia o que você tem até agora com mais uma tabela.

```sql
SELECT c.name, o.id, p.name AS product, l.quantity
FROM   customers   c
JOIN   orders      o ON o.customer_id = c.id
JOIN   order_lines l ON l.order_id    = o.id
JOIN   products    p ON p.id          = l.product_id
WHERE  o.ordered_on >= '2026-03-01';
```

Quatro tabelas, três junções, e **uma linha por linha de pedido** — que é a pergunta a continuar
fazendo conforme a cadeia cresce. Um cliente com dois pedidos de três linhas cada produz seis linhas,
e o nome dele está nas seis.

## Escrevendo uma que funciona de primeira

**Comece pela tabela de que a pergunta trata, e acrescente uma junção por vez**, conferindo a
contagem depois de cada uma. A técnica da aula 4, aplicada aqui:

```sql
SELECT count(*) FROM orders o;                              -- 5
SELECT count(*) FROM orders o JOIN customers c ON …;        -- 4, e é o pedido 1005 saindo
SELECT count(*) FROM orders o JOIN customers c ON … JOIN order_lines l ON …;   -- 11
```

O número indo de 4 para 11 te diz que a granularidade mudou: você já não está contando pedidos. Se
isso não era intencional, você achou na junção que causou em vez de num relatório três semanas
depois.

**E uma contagem que cai quando você acrescenta uma junção é a interessante.** Significa que linhas
não tinham parceiro, o que é ou um problema de dado ou um `LEFT JOIN` que você ainda não escreveu.

## A ordem não muda a resposta

```sql
FROM a JOIN b ON … JOIN c ON …
FROM c JOIN b ON … JOIN a ON …
```

Mesmas linhas, para junções internas. O planejador decide a ordem real do trabalho pelas estimativas
dele, e a aula 10 é onde você vê o que ele escolheu.

**Com junções externas a ordem importa**, porque um `LEFT JOIN` não é simétrico. Este é o caso a
tomar cuidado:

```sql
FROM customers c
LEFT JOIN orders o      ON o.customer_id = c.id
JOIN      order_lines l ON l.order_id    = o.id;
```

A junção interna no fim **desfaz a junção à esquerda**, pela mesma razão que um `WHERE` desfaz: a
linha inventada da Célia tem `o.id` nulo, nada em `order_lines` pareia com ela, e ela é descartada.

Uma vez que a cadeia vira externa, as junções depois dela normalmente também precisam ser:

```sql
LEFT JOIN orders      o ON o.customer_id = c.id
LEFT JOIN order_lines l ON l.order_id    = o.id
```

## Juntando uma tabela consigo mesma

Uma tabela pode aparecer duas vezes, e os apelidos deixam de ser conveniência e viram necessidade.

**Uma hierarquia.** Empregados com os gerentes deles, em que os dois são empregados:

```sql
SELECT e.name AS employee, m.name AS manager
FROM   employees e
LEFT JOIN employees m ON m.id = e.manager_id;
```

`LEFT`, porque quem está no topo não tem gerente, e uma junção interna descartaria o presidente em
silêncio.

**Comparando linhas entre si.** Pares de produtos com o mesmo preço:

```sql
SELECT a.name, b.name, a.price
FROM   products a
JOIN   products b ON b.price = a.price AND b.id > a.id;
```

O `b.id > a.id` faz dois trabalhos, e os dois importam: sem ele, todo produto pareia consigo mesmo, e
todo par genuíno aparece duas vezes nas duas ordens. Uma desigualdade estrita na chave dá cada par
exatamente uma vez.

**A linha anterior.** Que é uma pergunta real — o intervalo entre os pedidos de um cliente — e é
penosa com auto-junção e trivial com as funções de janela da aula 6:

```sql
-- a versão com auto-junção, que precisa de subconsulta correlacionada para achar "a anterior"
SELECT o.id, o.ordered_on,
       (SELECT max(p.ordered_on) FROM orders p
        WHERE p.customer_id = o.customer_id AND p.ordered_on < o.ordered_on) AS previous
FROM   orders o;

-- aula 6
SELECT id, ordered_on,
       lag(ordered_on) OVER (PARTITION BY customer_id ORDER BY ordered_on) AS previous
FROM   orders;
```

As duas estão corretas. A segunda diz o que significa, e é a razão de funções de janela existirem.

## Lendo uma consulta de cinco tabelas

A de outra pessoa, rápido:

1. **Ache a primeira tabela no `FROM`.** É do que a consulta trata — ou deveria.
2. **Leia cada `ON` como frase.** `l.order_id = o.id` é *"a linha pertence ao pedido"*. Todo `ON` que
   você não consegue ler assim merece segunda olhada; é ou uma junção por faixa ou um engano.
3. **Note todo `LEFT`**, e confira que nada depois dele é interno.
4. **Diga o que é uma linha.** *"Uma linha por linha de pedido."* Se você não consegue, a consulta
   também não sabe.
5. **Aí leia o `WHERE`**, procurando uma coluna da direita, que é o bug da seção anterior.

São cinco perguntas e nenhuma é sobre sintaxe, que é o ponto: junções são difíceis pelo que
significam, não por como são escritas.
