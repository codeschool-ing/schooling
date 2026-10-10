---
title: Protocol Buffers
version: 1
---

**Um arquivo `.proto` descreve mensagens: registros com campos tipados, cada campo com um nome e um
número.** O nome é para as pessoas e para o código que leem o arquivo. O número é para o fio, e é o
único dos dois que sai do programa. Esse fato explica quase todas as regras desta seção e da seção
sobre mudar o schema.

A imagem errada comum vem do JSON, em que toda mensagem leva as próprias chaves: `{"copies": 12}` diz
`copies` toda vez que é enviado. Uma mensagem de Protocol Buffers diz `3`, e quem lê sem o `.proto`
não consegue dizer o que é o campo 3. A próxima seção mostra os bytes.

Este é o contrato do depósito. Salve-o em `~/shelf` como `stock.proto`, do mesmo jeito que salvou o
`db.py` na aula 1:

```
// shelf/stock.proto
// The bookshop's warehouse, as a gRPC service.
syntax = "proto3";

package shelf.stock.v1;

service Stock {
  // How many copies of one book are on the shelf.
  rpc GetStock(BookRef) returns (StockLevel);
  // Take copies off the shelf for an order, if there are enough.
  rpc Reserve(ReserveRequest) returns (Reservation);
  // The level now, then again every time it changes.
  rpc WatchStock(BookRef) returns (stream StockLevel);
  // A delivery, one box at a time, and one summary at the end.
  rpc Restock(stream Delivery) returns (RestockSummary);
}

enum Availability {
  AVAILABILITY_UNSPECIFIED = 0;
  IN_STOCK = 1;
  LOW = 2;
  SOLD_OUT = 3;
}

message BookRef {
  string isbn = 1;
}

message StockLevel {
  string isbn = 1;
  string title = 2;
  int32 copies = 3;
  Availability availability = 4;
}

message ReserveRequest {
  string isbn = 1;
  int32 copies = 2;
}

message Reservation {
  string isbn = 1;
  int32 copies = 2;
  int32 left = 3;
}

message Delivery {
  string isbn = 1;
  int32 copies = 2;
}

message RestockSummary {
  int32 boxes = 1;
  int32 copies = 2;
  repeated string isbns = 3;
}
```

O bloco `service` no alto é o assunto da seção depois da próxima. Tudo abaixo dele são os dados.

## Mensagens e números de campo

`StockLevel` tem quatro campos. `string isbn = 1;` se lê assim: um campo chamado `isbn`, do tipo
`string`, enviado no fio como **campo número 1**. Os números só precisam ser únicos dentro de uma
mensagem, então `BookRef`, `StockLevel` e `ReserveRequest` têm todos um `isbn` que é o campo 1, e
nada os liga.

Os números de 1 a 15 cabem numa tag de um byte e os de 16 a 2047 precisam de dois, então os campos
que vão em toda mensagem ficam com os pequenos. **Um número, depois de usado, pertence àquele campo
para sempre.** A seção sobre mudar o schema mostra o que acontece quando alguém esquece.

## Tipos escalares

| tipo | guarda | observação |
|---|---|---|
| `string` | texto | sempre UTF-8 |
| `bytes` | quaisquer bytes | uma imagem, um hash, outro formato |
| `bool` | verdadeiro ou falso | |
| `int32`, `int64` | números inteiros | um negativo custa dez bytes no fio |
| `sint32`, `sint64` | números inteiros | para campos que muitas vezes são negativos |
| `double`, `float` | ponto flutuante | nunca para dinheiro; a regra dos centavos da aula 1 vale aqui também |

`copies` é um `int32` porque uma estante guarda bem menos que dois bilhões de livros, e nunca um
número negativo deles.

## `repeated`, e enums

**`repeated` transforma um campo numa lista.** O `RestockSummary` leva um campo `isbns` com cada
livro que uma entrega tocou, na ordem em que chegaram pela primeira vez. Em Python ele se comporta
como uma lista, em Go é um slice.

**Um enum é um conjunto de números com nome, e o primeiro valor tem de ser zero.** É uma regra da
linguagem, e o motivo é o próximo ponto: zero é o que quem lê vê quando o campo nunca foi preenchido.
Por isso o valor zero de `Availability` é `AVAILABILITY_UNSPECIFIED`, um nome que quer dizer "ninguém
disse", e não `IN_STOCK`, que faria um valor ausente parecer boa notícia.

## Um campo que não é enviado é zero

Nesta versão da linguagem, `proto3`, um campo com o valor zero não é enviado, e quem lê e não o
encontra devolve o valor zero: `0`, a string vazia, `false` ou o primeiro valor do enum. **Quem lê
não consegue distinguir "zero exemplares" de "ninguém me disse os exemplares".** Para `copies` tudo
bem, porque o servidor sempre o preenche. Onde a diferença importa, o campo é declarado
`optional int32 copies = 3;`, e o código gerado ganha um jeito de perguntar se ele foi preenchido.

O pacote, `shelf.stock.v1`, é a versão da aula 1 levada para dentro do contrato. Uma mudança que não
pode ser feita de forma compatível vai para `shelf.stock.v2`, ao lado, e a seção sobre mudar o schema
trata de evitar isso.
