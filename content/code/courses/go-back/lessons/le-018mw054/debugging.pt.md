---
title: Olhando dentro de uma chamada
version: 1
---

Quando algo dá errado numa API REST, a primeira ferramenta é o `curl`, e nada precisa estar instalado nem
ser conhecido de antemão. **O mesmo movimento contra uma porta gRPC não diz quase nada**:

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events/1
{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0,"available":120}
ana@vm:~/boxoffice$ curl -s localhost:9090/boxoffice.v1.Seats/GetEvent; echo "exit $?"
exit 1
ana@vm:~/boxoffice$ curl -si --http2-prior-knowledge -X POST -H "content-type: application/grpc" --data-binary @/dev/null localhost:9090/boxoffice.v1.Seats/GetEvent
HTTP/2 200 
content-type: application/grpc
grpc-status: 13
grpc-message: cardinality violation: received no request message from non-client-streaming RPC

```

A primeira requisição é a API da aula 3, legível num relance. A segunda foi para a porta gRPC em HTTP/1.1,
que o gRPC não fala, e o `curl` não recebeu resposta que pudesse usar, status de saída 1. A terceira falou
HTTP/2 e disse que era gRPC, e recebeu resposta: **status 200, com o resultado de verdade no cabeçalho
`grpc-status`**, 13, `Internal`, porque a chamada não levava mensagem nenhuma. É assim que todo erro gRPC
viaja: o status HTTP é 200 e o status gRPC vem em `grpc-status`, normalmente um trailer depois do corpo,
e aqui entre os cabeçalhos porque não havia corpo nenhum. Um proxy ou um log que só olha status HTTP vê toda
falha gRPC como sucesso.

## grpcurl

A ferramenta feita para isso é o **`grpcurl`**: o `curl` do gRPC, que recebe uma requisição escrita em JSON,
codifica com o contrato, faz a chamada e imprime a resposta de volta em JSON. Ele se instala como toda
ferramenta Go deste curso; trouxe uns trinta módulos junto, cortados aqui nas duas primeiras linhas:

```
ana@vm:~$ go install github.com/fullstorydev/grpcurl/cmd/grpcurl@v1.9.4
...
```

Ele precisa do contrato, dado aqui com `-proto`:

```
ana@vm:~/boxoffice$ grpcurl -plaintext -proto proto/seats.proto -d '{"id": 1}' localhost:9090 boxoffice.v1.Seats/GetEvent
{
  "id": 1,
  "name": "Jazz at the Docks",
  "seats": 120
}
ana@vm:~/boxoffice$ grpcurl -plaintext -proto proto/seats.proto -d '{"id": 9}' localhost:9090 boxoffice.v1.Seats/GetEvent
ERROR:
  Code: NotFound
  Message: event 9: no such event
ana@vm:~/boxoffice$ grpcurl -plaintext localhost:9090 list
Failed to list services: server does not support the reflection API
```

**A resposta não tem `"sold"`**. O evento 1 não vendeu nada, e o jeito padrão de transformar Protocol
Buffers em JSON deixa de fora os campos no valor zero, porque a forma binária nunca os mandou. Quem lê esse
JSON precisa saber que um número ausente quer dizer zero, que é exatamente a ambiguidade que a aula 3 seção
04 encontrou. O `NotFound` chegou com a mensagem que o `toStatus` escreveu, e o `describe` imprimiu o
serviço como o `.proto` o declara, comentários incluídos.

## Reflexão

O `grpcurl list` sem `-proto` falhou: **o servidor não suporta a API de reflexão**. Reflexão é um serviço
opcional que um servidor gRPC registra, numa linha com `reflection.Register(srv)`, pelo qual ele descreve o
próprio contrato a quem perguntar; as ferramentas então dispensam o arquivo `.proto`. É prático em
desenvolvimento e em redes internas, e **é um mapa da sua API entregue a quem chegar à porta**, por isso
muitas equipes só o ligam fora da produção. O boxoffice o deixa desligado e mantém o contrato no
repositório, onde todo cliente o pega de qualquer jeito.
