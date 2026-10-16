---
title: Prism, um substituto feito do contrato
version: 1
---

**O Prism lê um documento OpenAPI e responde como a API que ele descreve.** Ninguém escreve um
mapping. Todo caminho, parâmetro e status do `openapi.yaml` da lição 2 vira algo que o Prism
responde, com corpos montados a partir dos schemas e dos exemplos deles. Ele também confere toda
requisição contra o contrato e recusa a que o quebra, dizendo exatamente como. O Prism é feito pela
Stoplight, é livre e de código aberto, e roda em Node.

Vale dizer primeiro quem usa isto, porque não é quem testa o boxoffice. **Um mock do boxoffice serve
a quem chama o boxoffice.** O time que constrói o app Tickets da lição 14 pode trabalhar contra o
Prism antes de o boxoffice existir, ou enquanto ele está fora do ar, ou quando precisa de uma
resposta que o boxoffice não dá sob encomenda. O interesse de quem testa está no que um mock assim
pode e não pode prometer a eles.

## Qual Prism

O Prism vem do npm, e as versões mais novas dele não rodam mais no Node 22 que este curso usa. O npm
mostra o que cada versão pede:

```
ana@laptop:~/boxoffice$ npm view @stoplight/prism-cli@5.15.11 engines
{ node: '>=24.14.0' }
ana@laptop:~/boxoffice$ npm view @stoplight/prism-cli@5.14.2 engines
{ node: '>=18.20.1' }
```

Por isso o curso fixa a 5.14.2, a versão estável mais nova que aceita o Node 22. Se você instalou o
Node 24, um Prism mais novo serve e deve se comportar igual nesta seção. O `npx --yes` baixa uma
versão fixada na primeira vez e a roda, sem acrescentá-la ao projeto.

## Iniciando

Não pare nada: o boxoffice fica na 8080, e o Prism escuta na 4010. Num terminal só dele, a partir de
`~/boxoffice`:

```sh
npx --yes @stoplight/prism-cli@5.14.2 mock openapi.yaml
```

Ele imprime uma linha para cada operação que encontrou no contrato, oito delas, e depois
`Prism is listening on http://127.0.0.1:4010`. Dali em diante ele imprime algumas linhas para cada
requisição que trata, dizendo o que conferiu e que resposta escolheu. Vale ler essas linhas quando
uma resposta surpreende. Elas não aparecem aqui, porque o Prism marca cada uma com símbolos que as
transcrições do curso não conseguem desenhar.

## O que ele responde

A lista de espetáculos:

```
ana@laptop:~/boxoffice$ curl -s localhost:4010/v1/shows | jq
{
  "shows": [
    {
      "id": "sh-103",
      "title": "string",
      "starts_at": "2026-11-08T18:00:00-03:00",
      "price_cents": 0,
      "seats_left": 0
    }
  ]
}
```

**A forma está certa e o conteúdo é inventado.** Um espetáculo só, porque o schema diz que `shows` é
um array e o Prism faz o menor possível. O id e a data são os valores de `example` escritos no
contrato. O título é a palavra `string` e os números são `0`, porque nada melhor foi escrito. Um
pedido:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/v1/orders -H 'authorization: Bearer anything' -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2}'; echo
HTTP/1.1 201 Created
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: *
Access-Control-Allow-Credentials: true
Access-Control-Expose-Headers: *
location: /v1/orders/ord-1001
Content-type: application/json
Content-Length: 102
Date: Sat, 10 Oct 2026 19:52:40 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"id":"ord-1001","show_id":"string","seats":1,"total_cents":0,"status":"confirmed","payment":"string"}
```

`201`, o cabeçalho `location` do exemplo do contrato, e um pedido de **um** lugar de um espetáculo
chamado `string`, embora a requisição tenha pedido dois do sh-103. O Prism não lê a requisição para
montar a resposta. Ele monta a resposta a partir do schema.

## O que ele não tem como saber

Um mock feito de um contrato sabe só o que o contrato diz, e duas respostas deixam o limite claro:

```
ana@laptop:~/boxoffice$ curl -s localhost:4010/v1/shows/sh-999; echo
{"id":"sh-103","title":"string","starts_at":"2026-11-08T18:00:00-03:00","price_cents":0,"seats_left":0}
ana@laptop:~/boxoffice$ curl -s localhost:4010/oauth/token -d grant_type=client_credentials -d client_id=nobody -d client_secret=wrong; echo
{"access_token":"string","token_type":"Bearer","expires_in":0,"scope":"orders:read orders:write"}
```

**O sh-999 existe, e um cliente chamado `nobody` com um segredo errado ganha um token.** O contrato diz
como um espetáculo e um token se parecem; ele não lista os espetáculos nem os clientes, então o Prism
não tem com o que recusar. E nada num mock assim se lembra de coisa alguma: nenhum lugar é vendido, o
sh-103 nunca esgota, e o mesmo pedido pode ser feito para sempre. Um app testado só contra ele nunca
viu `409 only 1 seat left`.

## O que ele confere

**A outra metade do Prism é um validador, e ele é rigoroso.** Sete lugares, onde o contrato diz no
máximo seis:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/v1/orders -H 'authorization: Bearer anything' -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":7}' | grep -iE '^HTTP|^sl-violations'
HTTP/1.1 422 Unprocessable Entity
sl-violations: [{"location":["request","body","seats"],"severity":"Error","code":"maximum","message":"Request body property seats must be <= 6"}]
```

`422`, e o motivo num cabeçalho do próprio Prism, `sl-violations`: onde na requisição, que regra, e a
mensagem. Sem o cabeçalho `authorization`:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/v1/orders -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2}' | grep -iE '^HTTP|^sl-violations'
HTTP/1.1 401 Unauthorized
sl-violations: [{"location":["request"],"severity":"Error","code":401,"message":"Invalid security scheme used"}]
```

`401`, porque o contrato põe `/v1/orders` atrás do esquema `oauth`. O Prism confere que há um token e
que está no lugar certo; ele não consegue conferir se o token é bom, já que `Bearer anything` passou
acima.

## Onde o mock e o boxoffice discordam

Duas requisições recebem respostas diferentes do mock e do boxoffice de verdade, e **nas duas, quem
segue o contrato é o mock**. A lição 2 achou as duas divergências lendo o contrato caso a caso; aqui
elas aparecem sozinhas, na primeira vez que alguém chama o mock. Um campo que ninguém declarou:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/v1/orders -H 'authorization: Bearer anything' -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2,"seat_class":"vip"}' | grep -iE '^HTTP|^sl-violations'
HTTP/1.1 422 Unprocessable Entity
sl-violations: [{"location":["request","body"],"severity":"Error","code":"additionalProperties","message":"Request body must NOT have additional properties; found 'seat_class'"}]
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2,"seat_class":"vip"}'
201
```

O Prism recusa `seat_class`, porque o `NewOrder` do contrato diz `additionalProperties: false`; o
boxoffice cria o pedido. Um time de cliente que desenvolve contra o Prism encontra o mais rigoroso
dos dois, então essa divergência não surpreenderia ninguém em produção. Ela só esconde que o
servidor de verdade deixa erros passarem. Uma data que não é uma data:

```
ana@laptop:~/boxoffice$ curl -si 'localhost:4010/v1/shows?date=tomorrow' | grep -iE '^HTTP|^sl-violations'
HTTP/1.1 400 Bad Request
sl-violations: [{"location":["request","query","date"],"severity":"Error","code":"format","message":"Request query parameter date must match format \"date\""}]
ana@laptop:~/boxoffice$ curl -s 'localhost:8080/v1/shows?date=tomorrow'
{"shows":[]}
```

O contrato declara `date` como `format: date` e lista um `400` para a lista de espetáculos, e o
Prism responde isso. O boxoffice nunca confere o formato: responde `200` com uma lista vazia, então
um cliente que mandou `tomorrow` em vez de `2026-11-07` ouve que não há espetáculos naquele dia.
**Esta morde em produção**: um app construído contra o Prism mostra uma mensagem de erro para uma
data malformada que o boxoffice nunca vai mandar. Ou o código aprende a recusar, ou o contrato para
de prometer. O relatório de quem testa diz que lado divergiu e deixa a escolha para quem é dono do
contrato.

## Escolhendo a resposta

Um time de cliente também precisa das respostas de erro, e o Prism dá uma sob pedido com o cabeçalho
`Prefer`:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/v1/orders -H 'authorization: Bearer anything' -H 'content-type: application/json' -H 'Prefer: code=409' -d '{"show_id":"sh-103","seats":2}' | head -1
HTTP/1.1 409 Conflict
```

Qualquer status que o contrato liste para aquela operação pode ser pedido assim: `402`, `502`,
`504`. É desse jeito que as telas de erro de um app são construídas antes de o servidor conseguir
produzir qualquer um deles. Pare o Prism com Ctrl-C quando terminar: a seção 06 o inicia de novo, na
mesma porta, num outro papel.
