---
title: A chave de clustering ordena as linhas dentro da partição
version: 1
---

A chave de partição diz **onde** uma partição mora. As colunas de clustering dizem **em que ordem
suas linhas ficam guardadas** quando se chega lá, e essa ordem está no disco, não é calculada quando
você pergunta. Uma primeira leitura comum de `PRIMARY KEY (customer, ordered_at, order_id)` é "uma
chave composta, como a do SQL". São três trabalhos diferentes numa linha:

| parte | em `orders_by_customer` | o que decide |
| --- | --- | --- |
| chave de partição | `customer` | quais nós guardam as linhas; uma consulta precisa nomeá-la com `=` ou `IN` |
| primeira coluna de clustering | `ordered_at` | a ordem das linhas dentro da partição, e os intervalos que se pode pedir |
| coluna de clustering seguinte | `order_id` | a ordem entre linhas com o mesmo `ordered_at`, e o que torna cada linha única |

`order_id` está na chave pelo último motivo. **Um `INSERT` cuja chave primária completa já existe
sobrescreve aquela linha sem erro**, então uma chave só de `(customer, ordered_at)` deixaria dois
pedidos de um cliente no mesmo milissegundo virarem um. Acrescentar o id do próprio pedido não custa
nada e fecha essa porta.

## Perguntando a uma partição

`WITH CLUSTERING ORDER BY (ordered_at DESC, order_id ASC)` guarda primeiro o pedido mais novo de
cada cliente. Peça a partição da Ana, depois um intervalo dela, depois o mais novo, depois do mais
antigo para o mais novo:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com';

 order_id | ordered_at                      | total
----------+---------------------------------+---------
   A-1006 | 2026-04-08 12:30:00.000000+0000 | 1499.00
   A-1004 | 2026-03-20 00:02:00.000000+0000 |  189.00
   A-1001 | 2026-03-02 13:15:00.000000+0000 |  349.90

(3 rows)
cqlsh> SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com' AND ordered_at >= '2026-03-01' AND ordered_at < '2026-04-01';

 order_id | ordered_at                      | total
----------+---------------------------------+--------
   A-1004 | 2026-03-20 00:02:00.000000+0000 | 189.00
   A-1001 | 2026-03-02 13:15:00.000000+0000 | 349.90

(2 rows)
cqlsh> SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com' LIMIT 1;

 order_id | ordered_at                      | total
----------+---------------------------------+---------
   A-1006 | 2026-04-08 12:30:00.000000+0000 | 1499.00

(1 rows)
cqlsh> SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com' ORDER BY ordered_at ASC;

 order_id | ordered_at                      | total
----------+---------------------------------+---------
   A-1001 | 2026-03-02 13:15:00.000000+0000 |  349.90
   A-1004 | 2026-03-20 00:02:00.000000+0000 |  189.00
   A-1006 | 2026-04-08 12:30:00.000000+0000 | 1499.00

(3 rows)
cqlsh> SELECT order_id, ordered_at, total FROM shop.orders_by_customer WHERE customer = 'ana@example.com' ORDER BY total DESC;
InvalidRequest: Error from server: code=2200 [Invalid query] message="Order by is currently only supported on the clustered columns of the PRIMARY KEY, got total"
cqlsh> exit
```

Quatro coisas nessa transcrição merecem nome:

- **A primeira consulta não tem `ORDER BY` e volta do mais novo para o mais antigo.** É a ordem
  guardada, lida do começo. Uma tabela criada sem `DESC` devolveria o mais antigo primeiro.
- **O intervalo em `ordered_at` é uma fatia da partição**, não um filtro sobre ela. Como as linhas
  estão ordenadas por data, março é um trecho contínuo: o Cassandra acha onde ele começa e lê até
  onde termina.
- **`LIMIT 1` é "o último pedido da Ana"**, a pergunta mais comum que uma loja faz sobre um cliente,
  e lê exatamente uma linha. O `DESC` na definição da tabela é o que faz dela o último, e não o
  primeiro que ela fez.
- **`ORDER BY ordered_at ASC` funciona e `ORDER BY total` é recusado.** Ler uma partição de trás para
  frente é barato, então dá para inverter a ordem de clustering. Ordenar por qualquer outra coisa
  exigiria ler todas as linhas e ordenar em memória, e o Cassandra recusa em vez de fazer isso
  calado: `Order by is currently only supported on the clustered columns of the PRIMARY KEY`.

## O que um intervalo pode e não pode fazer

As colunas de clustering formam um caminho ordenado, e um intervalo só é barato ao longo dele.
`ordered_at >= '2026-03-01'` é um intervalo na primeira coluna de clustering, então é uma fatia. Uma
condição em `total` ou `status`, que nem estão na chave, não é um trecho de coisa nenhuma: a próxima
seção mostra o Cassandra recusando. A ordem das colunas de clustering é portanto uma decisão sobre
**quais intervalos a aplicação vai precisar**, tomada quando a tabela é criada e fixa por toda a vida
dela. Mudá-la significa uma tabela nova e uma cópia dos dados.

Esse é o formato da próxima seção. Toda pergunta que a aplicação faz precisa poder ser respondida
como "uma partição, depois uma fatia das suas linhas ordenadas", e quando não pode, a resposta é
outra tabela, e não uma consulta mais esperta.
