---
title: A última escrita vence, pelo relógio
version: 1
---

O Cassandra não tem número de versão para você nem um primário para onde mandar as escritas. Quando
duas escritas na mesma célula discordam, ele decide com uma regra que não precisa de coordenação
nenhuma: **toda célula carrega um timestamp, e o timestamp maior vence.** A regra é simples, rápida e
determinística, e a fraqueza dela é que "timestamp maior" não é a mesma coisa que "mais tarde".

## Toda célula tem um timestamp

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
cqlsh> USE shop;
cqlsh:shop> CREATE TABLE products (sku text PRIMARY KEY, name text, price decimal);
cqlsh:shop> INSERT INTO products (sku, name, price) VALUES ('MS-204', 'Wireless mouse', 189.00);
cqlsh:shop> SELECT sku, price, WRITETIME(price) FROM products WHERE sku = 'MS-204';

 sku    | price  | writetime(price)
--------+--------+------------------
 MS-204 | 189.00 | 1791684040589140

(1 rows)
cqlsh:shop> UPDATE products USING TIMESTAMP 1789000000000000 SET price = 179.00 WHERE sku = 'MS-204';
cqlsh:shop> SELECT sku, price, WRITETIME(price) FROM products WHERE sku = 'MS-204';

 sku    | price  | writetime(price)
--------+--------+------------------
 MS-204 | 189.00 | 1791684040589140

(1 rows)
cqlsh:shop> exit
```

`WRITETIME(price)` mostra o timestamp guardado com a célula, em microssegundos desde 1970, que o nó
ou o cliente atribuiu quando o insert chegou. Depois chega uma atualização com um timestamp **mais
antigo**, dado aqui com `USING TIMESTAMP` para fazer as vezes de uma escrita atrasada em algum lugar,
ou carimbada por um relógio atrasado. Ela foi aceita sem uma palavra, e o `SELECT` mostra que perdeu:
o preço continua 189.00, com o timestamp original. **Em silêncio é a palavra importante.** O cliente
que mandou 179.00 ouviu que a atualização deu certo.

## Um relógio adiantado

A outra direção é pior. Uma escrita carimbada com um timestamp no futuro vence toda escrita que vier
depois dela, até o tempo real a alcançar:

```
ana@vm:~$ docker exec -it cassandra cqlsh -k shop
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh:shop> UPDATE products USING TIMESTAMP 1830000000000000 SET price = 159.00 WHERE sku = 'MS-204';
cqlsh:shop> UPDATE products SET price = 199.00 WHERE sku = 'MS-204';
cqlsh:shop> SELECT sku, price, WRITETIME(price) FROM products WHERE sku = 'MS-204';

 sku    | price  | writetime(price)
--------+--------+------------------
 MS-204 | 159.00 | 1830000000000000

(1 rows)
cqlsh:shop> exit
```

A primeira atualização carrega um timestamp do fim de 2027. A segunda é uma atualização comum, feita
agora, com o preço que a loja de fato quer. **A atualização comum perdeu**: o preço é 159.00, e toda
correção feita com um timestamp normal vai perder do mesmo jeito até o relógio passar o do futuro.
Nada nas respostas às duas atualizações foi diferente.

## De onde vêm os timestamps errados

`USING TIMESTAMP` é como esta aula faz isso acontecer de propósito. Em produção acontece sozinho, por
**desvio de relógio** (clock skew): os drivers e os nós atribuem timestamps pelos próprios relógios,
e relógios derivam. Um nó ou um servidor de aplicação com o relógio dois segundos atrasado perde
toda disputa de que participa por dois segundos; um cujo relógio saltou para a frente vence disputas
que deveria perder. Duas escritas de dois clientes com um milissegundo de diferença são ordenadas
pelo relógio que estava mais adiantado, não por qual veio primeiro.

Então last write wins é seguro para dados em que isso não importa, e perigoso onde importa:

- **seguro**: um horário de última visita, um campo de perfil que uma pessoa edita, um valor
  substituído por uma leitura mais nova do mesmo sensor;
- **perigoso**: um estoque que dois checkouts atualizam, um saldo, qualquer coisa calculada a partir
  do valor que estava lá antes, que é a atualização perdida de novo com o relógio escolhendo o
  perdedor.

As defesas são de operação e de projeto. Mantenha todo relógio sincronizado com NTP e alerte sobre
desvio, assunto ao qual a aula 20 volta. Evite ler-modificar-gravar numa célula compartilhada; grave
linhas novas em vez de sobrescrever uma, ou use um contador, ou pague por uma lightweight transaction
onde a escrita realmente precisa ser condicional, como mostra a aula 17.
