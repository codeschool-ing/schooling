---
title: Achando órfãos em SQL
version: 1
---

Achar as linhas sem par se chama **anti-join**, e o SQL tem dois jeitos comuns de escrever um.
Os dois dão a mesma resposta aqui:

```
ana@lab:~/clean$ psql -c 'SELECT count(DISTINCT o.order_id) AS orders, count(DISTINCT o.customer_id) AS customers FROM raw.orders o WHERE NOT EXISTS (SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id)'
 orders | customers 
--------+-----------
    246 |        32
(1 row)

ana@lab:~/clean$ psql -c 'SELECT count(DISTINCT o.order_id) AS orders FROM raw.orders o LEFT JOIN raw.customers c ON c.customer_id = o.customer_id WHERE c.customer_id IS NULL'
 orders 
--------
    246
(1 row)
```

O primeiro, `NOT EXISTS`, se lê como a pergunta: pedidos para os quais não existe cliente. O
segundo, um `LEFT JOIN` seguido de `WHERE c.customer_id IS NULL`, mantém todo pedido, prende um
cliente onde houver, e depois fica só com as linhas em que nada foi preso. **Teste `NULL` na
coluna da chave do lado direito, nunca numa coluna que pode estar vazia por conta própria**: um
cliente sem e-mail pareceria um cliente faltante se o teste fosse em `c.email`.

As duas consultas contam `DISTINCT o.order_id`, porque `raw.orders` ainda guarda os 25 pedidos
repetidos e `raw.customers` as suas 37 linhas repetidas. Nenhuma repetição calha de ser órfã,
então um `count(*)` simples também daria 246, mas **uma contagem de linhas sobre tabelas sujas só
acerta por sorte**, e o `DISTINCT` na chave tira a sorte da conta.

Há um terceiro jeito que parece igual e não é: `WHERE customer_id NOT IN (SELECT customer_id FROM
raw.customers)`. **Se a subconsulta devolver um único `NULL`, o `NOT IN` não devolve linha
nenhuma**, porque comparar qualquer coisa com `NULL` dá desconhecido, não falso. O arquivo de
clientes não tem códigos vazios hoje. No dia em que tiver, uma consulta escrita com `NOT IN`
informa zero órfãos e parece boa notícia. Prefira `NOT EXISTS`, que não tem essa armadilha.
