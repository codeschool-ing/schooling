---
title: Hashes, e quando uma string JSON é a melhor escolha
version: 1
---

Um produto tem nome, preço e estoque. O primeiro impulso é guardá-lo do jeito que a aplicação já o
tem, como um documento JSON numa string. **Um hash guarda o mesmo registro como campos com nome
dentro de uma chave**, e a diferença está nas operações que o Redis consegue fazer por você sem a
aplicação ler tudo.

## Um produto como hash

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> HSET product:KB-101 name "Mechanical keyboard" price_cents 34990 stock 12
(integer) 3
127.0.0.1:6379> HGETALL product:KB-101
1) "name"
2) "Mechanical keyboard"
3) "price_cents"
4) "34990"
5) "stock"
6) "12"
127.0.0.1:6379> HINCRBY product:KB-101 stock -1
(integer) 11
127.0.0.1:6379> HMGET product:KB-101 price_cents stock
1) "34990"
2) "11"
```

O `HSET` gravou três campos e respondeu quantos eram novos. O `HINCRBY` tirou um teclado do estoque
no servidor, de forma atômica, exatamente como o `INCR` num contador, e o `HMGET` leu dois campos
sem transferir o terceiro. Com a string JSON, a mesma venda é um `GET`, um parse, uma alteração e um
`SET`, e duas vendas ao mesmo tempo são a atualização perdida da seção anterior, com um registro de
produto no lugar de um contador de páginas.

## Quanto custa em memória

O mesmo produto, dos dois jeitos:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET product:KB-101:json '{"name":"Mechanical keyboard","price_cents":34990,"stock":12}'
OK
127.0.0.1:6379> MEMORY USAGE product:KB-101
(integer) 120
127.0.0.1:6379> MEMORY USAGE product:KB-101:json
(integer) 144
127.0.0.1:6379> OBJECT ENCODING product:KB-101
"listpack"
```

**O hash ocupa 120 bytes e a string JSON 144**, porque o hash não guarda as chaves, as aspas e os
dois-pontos. A economia vem da codificação: um hash pequeno é guardado como `listpack`, um bloco
compacto de memória com os campos um atrás do outro. O Redis o mantém assim enquanto o hash é
pequeno, e o converte numa tabela hash de verdade, mais rápida de consultar e bem maior, no momento
em que deixa de ser:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG GET hash-max-listpack-*
1) "hash-max-listpack-value"
2) "64"
3) "hash-max-listpack-entries"
4) "512"
127.0.0.1:6379> HSET product:KB-101 description "Full-size mechanical keyboard with brown switches, ABNT2 layout and a detachable USB-C cable"
(integer) 1
127.0.0.1:6379> OBJECT ENCODING product:KB-101
"hashtable"
127.0.0.1:6379> MEMORY USAGE product:KB-101
(integer) 424
```

Os dois limites são `hash-max-listpack-entries`, 512 campos, e `hash-max-listpack-value`, 64 bytes.
**Uma descrição com mais de 64 bytes transformou o produto num `hashtable`, e o tamanho foi de 120
bytes para 424**, muito mais que os 92 caracteres acrescentados. Numa chave, não é nada. Num milhão
de produtos, cada um empurrado além do limite por um campo longo, é a diferença entre uma máquina em
que o catálogo cabe e uma em que não cabe. Um texto longo que só é exibido muitas vezes fica melhor
numa chave própria, ao lado do hash.

## Qual escolher

A escolha segue o padrão de acesso, que é o argumento da aula 3 aplicado a uma chave:

| | o hash ganha | a string JSON ganha |
| --- | --- | --- |
| como é lido | um ou dois campos por vez: o preço numa listagem, o estoque num carrinho | sempre inteiro, por um código que vai fazer o parse de qualquer jeito |
| como é escrito | um campo muda sozinho: o estoque baixa, um preço é corrigido | o valor inteiro é trocado de uma vez |
| a forma | plana: um campo guarda uma string ou um número | aninhada: listas dentro de objetos, que um hash não comporta |
| contadores dentro | `HINCRBY` num campo, atômico | ler, fazer o parse, somar, gravar, e uma corrida |
| o que é | o registro do próprio sistema, alterado no lugar | uma cópia de outra coisa, como a resposta de uma API guardada por um minuto |

**Uma cópia em cache da resposta de outro sistema pertence a uma string**: ninguém atualiza um campo
de uma resposta em cache, e a string é exatamente o que a aplicação vai repassar. **Um registro que
a loja altera um campo por vez pertence a um hash.** O produto da loja, com o estoque baixando a cada
venda, é do segundo tipo.
