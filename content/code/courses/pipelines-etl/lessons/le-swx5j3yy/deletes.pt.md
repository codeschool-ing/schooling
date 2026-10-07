---
title: A mudança que uma carga incremental não vê
version: 1
---

Em 14 de março um cliente pede que a Ponto Final o esqueça, e o escritório faz o que a lei exige —
desliga os pedidos dele e apaga a linha:

```
ana@vm:~/etl$ sudo bash ~/lab/lab.sh until 2026-03-14
ana@vm:~/etl$ grep -A2 "SET customer_id = NULL" /var/lib/etl-data/days/2026-03-14.sql
UPDATE orders SET customer_id = NULL, updated_at = '2026-03-14 10:14:53-03:00' WHERE customer_id = 1880;
DELETE FROM customers WHERE customer_id = 1880;
COMMIT;
ana@vm:~/etl$ python incremental.py customers
shop.customers: 294 rows since 03-01 22:21:41, watermark now 03-14 22:46:33
ana@vm:~/etl$ python full_customers.py
raw.customers: 5345 rows, all of them
ana@vm:~/etl$ psql -c "SELECT count(*) AS in_the_shop FROM customers WHERE customer_id = 1880"
 in_the_shop 
-------------
           0
(1 row)

ana@vm:~/etl$ psql -d wh -c "SELECT (SELECT count(*) FROM raw.customers_changes WHERE customer_id = 1880) AS incremental, (SELECT count(*) FROM raw.customers WHERE customer_id = 1880) AS full_copy"
 incremental | full_copy 
-------------+-----------
           1 |         0
(1 row)
```

A extração incremental rodou naquela noite e leu 294 clientes alterados. O apagado não estava entre
eles, e não poderia estar: **uma linha apagada não tem `updated_at`, porque não tem linha.** A cópia
incremental no warehouse ainda guarda o cliente 1880, nome, e-mail e cidade, e vai guardar até
alguém perceber. A cópia completa, refeita do zero na mesma noite, simplesmente não o tem.

Um warehouse que guarda o e-mail de um cliente apagado depois que a loja o apagou está guardando
um dado pessoal que ninguém mais pode guardar, e foi pelo pipeline que ele chegou lá.

## Quatro jeitos de ver uma exclusão

- **Uma carga completa da tabela**, para tabelas pequenas o bastante para isso. `customers` tem cinco
  mil linhas; recarregá-la toda noite não custa nada e torna impossível perder uma exclusão.
- **Comparar as chaves.** Extraia só os ids da origem, toda noite, e apague do warehouse o que não
  estiver mais lá. Mais barato que uma carga completa, porque ids são pequenos, e ainda assim lê a
  chave de cada linha.
- **Exclusões lógicas na origem.** A origem nunca apaga; ela preenche `deleted_at` e deixa a linha.
  Aí uma exclusão vira uma atualização, o `updated_at` anda, e uma extração incremental a vê. Isso
  precisa da concordância dos donos da origem, e é errado para um pedido de apagamento, em que a
  linha tem de sumir.
- **Ler o log do banco.** Toda exclusão é escrita lá, na ordem de confirmação, e a lição 5 o lê.

Os pedidos que o cliente apagado fez são outra questão, e o escritório cuidou dela: o `customer_id`
deles virou `NULL` e o `updated_at` andou, então a extração incremental de pedidos *viu* essa
mudança. **Uma atualização de uma linha é visível para uma marca d'água; o sumiço de uma linha não
é.**
