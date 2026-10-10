---
title: Um armazenamento chave-valor, o Redis
version: 1
---

Um armazenamento chave-valor tem a forma que muita gente imagina para um de documentos: um nome, e
algo guardado sob ele. **O servidor guarda o valor e o devolve quando pedido pelo nome, e o nome é a
única porta de entrada.** O Redis dá um tipo ao valor, o que já é mais do que os armazenamentos mais
simples fazem, e a regra continua valendo: não há consulta, só chaves.

## O pedido como uma string

Guarde o pedido 1001 como faria uma aplicação que o põe em cache, como o JSON que ela já tem:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET order:1001 '{"customer":"ana@example.com","lines":[{"sku":"CB-012","qty":2,"unit_price":"39.90"},{"sku":"MS-204","qty":1,"unit_price":"189.00"}],"total":"268.80"}'
OK
127.0.0.1:6379> GET order:1001
"{\"customer\":\"ana@example.com\",\"lines\":[{\"sku\":\"CB-012\",\"qty\":2,\"unit_price\":\"39.90\"},{\"sku\":\"MS-204\",\"qty\":1,\"unit_price\":\"189.00\"}],\"total\":\"268.80\"}"
127.0.0.1:6379> TYPE order:1001
string
127.0.0.1:6379> HGET order:1001 total
(error) WRONGTYPE Operation against a key holding the wrong kind of value
127.0.0.1:6379> exit
```

O `SET` guardou o texto sob `order:1001` e o `GET` o devolveu, com as aspas internas escapadas pelo
`redis-cli` para que se veja onde a string termina. **Para o Redis isto é uma string de bytes**: o
`TYPE` diz `string`, e o servidor não faz ideia de que ali dentro há JSON, um cliente ou um total.
Pedir o campo `total` é recusado com `WRONGTYPE`, porque campo é coisa que um hash tem e uma string
não.

## O pedido como um hash

Um hash é uma chave cujo valor é um conjunto de campos com nome, e o servidor consegue ler e gravar
um campo sem mexer nos outros:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> DEL order:1001
(integer) 1
127.0.0.1:6379> HSET order:1001 customer ana@example.com ordered_at 2026-09-14T10:22:00-03:00 total 268.80
(integer) 3
127.0.0.1:6379> HGET order:1001 total
"268.80"
127.0.0.1:6379> HGETALL order:1001
1) "customer"
2) "ana@example.com"
3) "ordered_at"
4) "2026-09-14T10:22:00-03:00"
5) "total"
6) "268.80"
127.0.0.1:6379> HSET order:1001 lines '[{"sku":"CB-012","qty":2},{"sku":"MS-204","qty":1}]'
(integer) 1
127.0.0.1:6379> TYPE order:1001
hash
127.0.0.1:6379> exit
```

O `HSET` respondeu `3`, o número de campos que criou, e o `HGET` devolveu um deles sozinho. **Um hash
tem um nível só.** As linhas do pedido são uma lista de registros, e um campo guarda uma string,
então as linhas entram como texto JSON dentro do campo `lines`, opacas de novo. Todo valor que o
Redis devolveu também é string, `"268.80"` inclusive: o servidor guarda texto e não tem tipo
decimal, então a aritmética de dinheiro fica na aplicação ou em centavos inteiros, que o Redis soma
com exatidão usando `HINCRBY`.

## A pergunta que ele não responde

Peça ao Redis **todo pedido acima de 500 reais** e não há comando a digitar. Nenhum comando aceita
uma condição sobre um valor. A aplicação teria de conhecer toda chave de pedido, buscar cada valor,
interpretá-lo e comparar o total por conta própria, o que é uma varredura completa feita pela rede,
uma chave por vez.

Então um projeto chave-valor responde outras perguntas **gravando uma segunda estrutura que já
contém a resposta**: um sorted set de ids de pedidos com o total como score, por exemplo, do qual o
Redis devolve um intervalo por score num comando só. A aula 12 monta essa estrutura, e a aula 4 trata
do custo de manter duas cópias de um fato em dia.

O que a forma compra é velocidade e simplicidade. Um `GET` por chave é a coisa mais barata que um
banco de dados consegue fazer, e o Redis faz isso da memória. É por isso que o Redis tantas vezes fica
na frente de outro banco como cache, guardando respostas que outra coisa calculou, e a aula 14 trata
de operá-lo assim.

O Redis é o armazenamento chave-valor que este curso opera. O Memcached é o mais antigo e mais
simples, só de cache. O Valkey nasceu em 2024 como um fork do Redis, feito quando o Redis trocou de
licença, e responde aos mesmos comandos; a aula 21 conta por que isso importa para quem opera.
