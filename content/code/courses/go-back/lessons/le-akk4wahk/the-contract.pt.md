---
title: O contrato, num arquivo .proto
version: 1
---

O serviço é escrito antes de existir qualquer Go, em `~/boxoffice/proto/seats.proto`:

```
// boxoffice/proto/seats.proto
syntax = "proto3";

package boxoffice.v1;

option go_package = "example.com/boxoffice/internal/seatspb";

// Seats is boxoffice's service for the other programs of the venue.
service Seats {
  // GetEvent answers one event.
  rpc GetEvent(GetEventRequest) returns (Event);
  // Watch sends an event's availability now, and again whenever it changes.
  rpc Watch(WatchRequest) returns (stream Availability);
  // Scan reads the tickets presented at the door and answers once, at the end.
  rpc Scan(stream ScanRequest) returns (ScanSummary);
}

message GetEventRequest {
  int32 id = 1;
}

message Event {
  int32 id = 1;
  string name = 2;
  int32 seats = 3;
  int32 sold = 4;
}

message WatchRequest {
  int32 event_id = 1;
}

message Availability {
  int32 event_id = 1;
  int32 available = 2;
}

message ScanRequest {
  int32 ticket_id = 1;
}

message ScanSummary {
  int32 admitted = 1;
  int32 refused = 2;
}
```

Leia em três camadas:

- **O cabeçalho.** `syntax = "proto3"` é a versão atual da linguagem. `package boxoffice.v1` dá nome ao
  contrato, e o `v1` está lá de propósito: um contrato que um dia precisar quebrar é publicado como
  `v2` ao lado dele, em vez de mudar debaixo dos clientes. `go_package` diz a que pacote Go o código
  gerado pertence, aqui `internal/seatspb` no módulo do boxoffice.
- **O serviço.** Três linhas `rpc`, uma por função, cada uma com o tipo da requisição e o tipo da
  resposta. **A palavra `stream` decide o tipo de chamada**: do lado da resposta no `Watch`, do lado da
  requisição no `Scan`. Os comentários acima delas vão parar no Go gerado.
- **As mensagens.** Cada campo tem um tipo, um nome e **um número. O número é o que viaja**, não o
  nome; ele é a identidade do campo para sempre, e a seção 09 trata do que isso significa quando o
  contrato muda.

O `.proto` não tem realce de sintaxe nos blocos de código deste curso, e precisa de pouco: ele se lê
como um Go bem pequeno.

## O que os números compram

O `protoc` sabe codificar uma mensagem a partir de uma forma de texto legível e decodificá-la de novo,
o que mostra exatamente o que atravessa a rede. Eis o evento de jazz em bytes, quantos são, e o que um
leitor vê **sem** o `.proto`:

```
ana@vm:~/boxoffice$ echo 'id: 1 name: "Jazz at the Docks" seats: 120 sold: 2' | protoc --encode=boxoffice.v1.Event proto/seats.proto | od -An -tx1
 08 01 12 11 4a 61 7a 7a 20 61 74 20 74 68 65 20
 44 6f 63 6b 73 18 78 20 02
ana@vm:~/boxoffice$ echo 'id: 1 name: "Jazz at the Docks" seats: 120 sold: 2' | protoc --encode=boxoffice.v1.Event proto/seats.proto | wc -c
25
ana@vm:~/boxoffice$ echo 'id: 1 name: "Jazz at the Docks" seats: 120 sold: 2' | protoc --encode=boxoffice.v1.Event proto/seats.proto | protoc --decode_raw
1: 1
2: "Jazz at the Docks"
3: 120
4: 2
ana@vm:~/boxoffice$ printf '%s' '{"id":1,"name":"Jazz at the Docks","seats":120,"sold":2}' | wc -c
56
```

**25 bytes contra os 56 do mesmo evento em JSON.** Leia os primeiros bytes: `08 01` é o campo 1 com o
número 1; `12 11` é o campo 2, uma string de 17 (`0x11`) bytes, seguida das letras de *Jazz at the
Docks*; `18 78` é o campo 3, 120; `20 02` é o campo 4, 2. Os nomes `id`, `name`, `seats` e `sold` não
aparecem em lugar nenhum: **o `--decode_raw` recupera os números e os valores, e só o contrato diz o que
eles significam.** Essa é a troca, e a aula 11 a mede numa resposta maior.
