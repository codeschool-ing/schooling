---
title: Métodos, e o primeiro defeito
version: 1
---

**O método é o verbo de uma requisição: o que o cliente quer que seja feito com a coisa naquele
endereço.** O mesmo caminho pode significar coisas diferentes com métodos diferentes.
`GET /v1/orders/ord-1001` lê um pedido e `DELETE /v1/orders/ord-1001` o cancela, então quem testa
nunca confere um endereço sem conferir que métodos ele responde.

| método | o que pede | muda alguma coisa? | seguro repetir? | o boxoffice usa para |
|---|---|---|---|---|
| `GET` | me mande isto | não | sim | os espetáculos, um espetáculo, um pedido |
| `HEAD` | me mande só os cabeçalhos que um GET mandaria | não | sim | (veja abaixo) |
| `POST` | aqui vai algo novo; você escolhe onde fica | sim | **não** | um token, um pedido novo |
| `PUT` | guarde isto, inteiro, neste endereço | sim | sim | — |
| `PATCH` | mude parte do que está neste endereço | sim | depende | — |
| `DELETE` | remova o que está neste endereço | sim | sim | cancelar um pedido |

Duas palavras dessa tabela carregam boa parte do curso. Um método **seguro** não muda nada no
servidor, então um cliente, um cache ou um teste pode mandá-lo quantas vezes quiser. Um método
**idempotente** pode mudar algo, mas mandá-lo duas vezes deixa o servidor como mandá-lo uma vez:
cancelar um pedido já cancelado não muda mais nada. O `POST` não é nenhum dos dois, e é por isso que
tocar duas vezes em *Comprar* numa conexão lenta pode comprar dois ingressos, e por isso a lição 13
dedica uma lição inteira a ele.

## Perguntando com o verbo errado

Quem testa pergunta com o verbo errado de propósito, porque uma API que faz alguma coisa com um
método que não suporta tem um defeito. O `-X` do curl escolhe o método, e o `-i` acrescenta a linha
de status e os cabeçalhos à saída:

```
ana@laptop:~/boxoffice$ curl -i -X DELETE localhost:8080/v1/shows/sh-103
HTTP/1.1 405 Method Not Allowed
content-type: application/problem+json
allow: GET
Date: Sat, 10 Oct 2026 07:13:50 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"type":"about:blank","title":"Method Not Allowed","status":405,"detail":"DELETE is not allowed here"}
```

Essa é a recusa certa. `405 Method Not Allowed` diz que o endereço existe e o método não é aceito
ali, e o cabeçalho `allow` lista o que é, como o padrão exige num 405. Um `404` aqui estaria errado,
porque o espetáculo existe, e um `200` seria alarmante.

## O primeiro defeito

`HEAD` pede os cabeçalhos que um `GET` devolveria, sem o corpo. Um cliente o usa para saber se algo
mudou, ou qual o tamanho, sem baixar. O curl manda um com `-I`:

```
ana@laptop:~/boxoffice$ curl -I localhost:8080/v1/shows/sh-103
HTTP/1.1 405 Method Not Allowed
content-type: application/problem+json
allow: GET
Date: Sat, 10 Oct 2026 07:13:50 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

O boxoffice recusa, e a recusa se contradiz: o cabeçalho `allow` diz que `GET` pode, e o padrão é
explícito em que **todo servidor de uso geral deve suportar `GET` e `HEAD`** (RFC 9110, §9.1).
Isso é um defeito, e um defeito típico: nada em tela alguma vai mostrá-lo, ninguém escreveu um caso
para ele, e ele foi achado fazendo à API uma pergunta que mais ninguém faz.

Se você fez `manual-testing`, este é o momento de registrá-lo do jeito que aquele curso ensinou: o
que você mandou, o que voltou, o que o padrão diz que deveria ter voltado, e a evidência, que é a
transcrição acima. A correção são poucas linhas no boxoffice, e o curso a deixa sem corrigir para que
você veja os testes das lições seguintes pegarem o defeito.
