---
title: Um write não roda de novo, e é essa a diferença inteira
version: 1
---

Um `SELECT` com defeito não custa nada. Você lê o resultado, vê que está errado, conserta a condição
e roda de novo — e o banco está exatamente como estava antes de você começar. As aulas 4 a 7 foram
escritas nesse tom, e é por isso que dava para aprendê-las experimentando.

Este é o mesmo defeito num `UPDATE`:

```
shop=# SELECT sku, price FROM products;
  sku   |  price  
--------+---------
 KB-101 |  349.90
 MS-204 |  189.00
 MN-330 | 1499.00
 CB-012 |   39.90
(4 rows)

shop=# UPDATE products SET price = price * 1.10;
UPDATE 4

shop=# SELECT sku, price FROM products;
  sku   |  price  
--------+---------
 KB-101 |  384.89
 MS-204 |  207.90
 MN-330 | 1648.90
 CB-012 |   43.89
(4 rows)
```

Sem erro. Sem aviso. Nada naquela saída diz que falta um `WHERE`, porque não há nada de errado com a
instrução — `UPDATE 4` é o relato verdadeiro e completo de que quatro linhas mudaram, que foi o que
se pediu. Os preços antigos não se recuperam de nada que esteja nesta página.

**Um write não roda de novo.** Consertar a instrução e rodar a certa não desfaz a primeira: o
catálogo agora está dez por cento mais caro e um produto está, além disso, corretamente reajustado.
Dois enganos onde um `SELECT` não teria deixado nenhum.

## Escreva o `WHERE` primeiro, como um `SELECT`

O hábito custa uma instrução e é o seguro mais barato deste curso:

```
shop=# SELECT id, status FROM orders WHERE customer_id = 1 AND status = 'placed';
 id | status 
----+--------
  1 | placed
  3 | placed
  4 | placed
(3 rows)

shop=# UPDATE orders SET status = 'cancelled' WHERE customer_id = 1 AND status = 'placed';
UPDATE 3
```

Três linhas, e você viu quais três antes de qualquer coisa se mexer. O `SELECT` é a prova de que a
condição quer dizer o que você acha que ela quer dizer — e pega a classe inteira de erros a que a
aula 4 dedicou uma seção, onde `city <> 'Recife'` descarta em silêncio todo mundo cuja cidade é
`NULL`.

Depois troque só o verbo. O momento em que você redigita a condição é o momento em que ela deixa de
ser a condição que você conferiu.

## Leia a contagem

`UPDATE 3` contra três linhas que você acabou de contar é uma confirmação. `UPDATE 4812` é uma frase
avisando que algo está errado **enquanto ainda dá para fazer alguma coisa**, e olhar não custa nada.

**Saiba o número antes de apertar enter, e leia o número que volta.** A maioria dos acidentes de
escrita é alguém que não sabia nem um nem outro.

## `RETURNING` quando a contagem não basta

**A contagem diz quantas. O `RETURNING` diz quais:**

```
shop=# UPDATE products SET price = price * 1.10 WHERE sku = 'KB-101' RETURNING sku, price;
  sku   | price  
--------+--------
 KB-101 | 384.89
(1 row)

UPDATE 1
```

Uma instrução, uma passada, e as linhas como elas ficaram em vez de como você espera que tenham
ficado. Funciona nas três instruções, e é o jeito honesto de registrar o que uma rotina fez.

Não está em todo lugar. O MySQL não tem `RETURNING` nenhum, o MariaDB tem para `INSERT` e `DELETE`,
e a aula 12 é onde essas diferenças moram. Onde ele falta, a contagem é o que você tem.

## E nada disso desfaz coisa alguma

Tudo nesta seção é cuidado tomado **antes** do fato: conferir a condição, ler o número, pedir as
linhas de volta. Tudo ajuda e nada é saída, porque quando dá para ver aquele `UPDATE 4812` as quatro
mil oitocentas e doze linhas já mudaram.

A aula 4 prometeu que esta aula era o lugar certo para estas três instruções, e a razão é essa: o
que torna um write recuperável não é um hábito, é uma transação, e é disso que trata o resto da
aula.
