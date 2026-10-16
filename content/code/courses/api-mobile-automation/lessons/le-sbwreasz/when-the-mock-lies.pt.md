---
title: Quando o mock mente, e como pegar
version: 1
---

**Um substituto é uma afirmação sobre outro programa, escrita por alguém que não era esse programa.**
Ela é verdadeira no dia em que é escrita, se a pessoa leu com cuidado a documentação do provedor, e
fica exatamente como estava enquanto o provedor segue em frente. A falha que vem daí é a pior que uma
suíte de testes pode ter: está tudo verde, e a produção está quebrada.

## Um mock que responde 200

Imagine que o mapping do WireMock tivesse sido escrito de memória, por alguém que achava que um
provedor de pagamento responde `200 OK` a uma cobrança. O WireMock aceita um mapping pela API de
administração além de por arquivo, que é como um teste prepara um substituto para um caso só, então o
errado pode ser acrescentado com ele rodando. A prioridade 1 o põe na frente dos dois arquivos:

```
ana@laptop:~/boxoffice$ curl -s localhost:8091/__admin/mappings -d '{"priority":1,"request":{"method":"POST","url":"/charges"},"response":{"status":200,"jsonBody":{"id":"ch-wm-3","status":"approved"}}}' | jq -c '{id, response}'
{"id":"35ad87b9-38e9-4d60-ad17-3c2157422d5e","response":{"status":200,"jsonBody":{"id":"ch-wm-3","status":"approved"}}}
```

Depois, um pedido comum pelo boxoffice, que continua apontado para o WireMock:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":2}'
{"type":"about:blank","title":"Bad Gateway","status":502,"detail":"the payment provider failed"}
```

`502`, *the payment provider failed*. O próprio log do boxoffice diz por quê:

```
ana@laptop:~/boxoffice$ PAYMENTS_URL=http://localhost:8091 node boxoffice.mjs
boxoffice listening on http://localhost:8080
POST /v1/orders 201
POST /v1/orders 402
POST /v1/orders 201
GET /v1/shows?date=tomorrow 200
  payments: payments answered 200
POST /v1/orders 502
```

`payments answered 200`: o boxoffice só aceita `201`, então tratou a cobrança como falha e recusou o
pedido. **Aqui o boxoffice está certo e o mock está errado**, e o teste ficou vermelho, que é o caso
de sorte. Inverta e a sorte acaba. Se o boxoffice tivesse sido escrito contra esse mock, por alguém
que conferisse `200`, todo teste passaria, e em produção todo pedido falharia contra um provedor que
responde `201`. A suíte teria testado o boxoffice contra um provedor que não existe.

Então, quando um teste contra um substituto falha, há sempre dois suspeitos, e **a pergunta "quem está
certo?" não pode ser respondida por nenhum dos dois programas**. Quem responde é o que o provedor
promete.

## O contrato do provedor

Um provedor publica o que aceita e o que responde, cada vez mais num documento OpenAPI como o do
próprio boxoffice. O provedor deste curso é imaginário, então o contrato dele é escrito aqui, reduzido
à única operação que o boxoffice usa. Salve como `payments.yaml`:

```yaml
openapi: 3.1.0
info:
  title: payments
  version: 1.0.0
  description: The charges endpoint of the payment provider, as the provider publishes it.
paths:
  /charges:
    post:
      summary: Charge an amount, once per idempotency key
      parameters:
        - name: idempotency-key
          in: header
          required: true
          schema: { type: string }
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [amount_cents, reference]
              properties:
                amount_cents: { type: integer, minimum: 1 }
                reference: { type: string }
      responses:
        '201':
          description: The charge, approved or declined.
          content:
            application/json:
              schema:
                type: object
                required: [id, status]
                properties:
                  id: { type: string }
                  status: { enum: [approved, declined] }
```

Ele diz três coisas que um substituto precisa respeitar: o cabeçalho `idempotency-key` é obrigatório,
uma cobrança é respondida com `201`, e `status` é `approved` ou `declined` e nada mais.

## O Prism como árbitro

A seção 05 usou o Prism para responder a partir de um contrato. Ele tem um segundo modo, `proxy`, em
que **não responde nada por conta própria**: repassa cada requisição a um servidor de verdade e confere
a requisição e a resposta contra o contrato no caminho. Com `--errors`, uma violação em qualquer
direção vira uma resposta de erro em vez de uma linha no log do Prism. Pare o mock do Prism com Ctrl-C
se ele ainda estiver rodando, e inicie o árbitro no lugar dele, na frente do WireMock:

```sh
npx --yes @stoplight/prism-cli@5.14.2 proxy payments.yaml http://localhost:8091 --errors
```

Uma cobrança pelo proxy, com o mapping mentiroso ainda no WireMock:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/charges -H 'content-type: application/json' -H 'idempotency-key: try-1' -d '{"amount_cents":16000,"reference":"ord-9001"}' | grep -iE '^HTTP|^sl-violations'
HTTP/1.1 500 Internal Server Error
sl-violations: [{"location":["response"],"severity":"Error","message":"Unable to match the returned status code with those defined in the document: 201"}]
```

**A mentira, pega pelo próprio documento do provedor.** O Prism trocou a resposta do WireMock por um
`500` e disse por quê: o contrato define `201` para esta operação, e o substituto respondeu outra
coisa. Reinicie os mappings do WireMock, o que descarta o que foi acrescentado pela API e relê os
arquivos, e mande a mesma cobrança com uma chave nova:

```
ana@laptop:~/boxoffice$ curl -s -X POST localhost:8091/__admin/mappings/reset
ana@laptop:~/boxoffice$ curl -si localhost:4010/charges -H 'content-type: application/json' -H 'idempotency-key: try-2' -d '{"amount_cents":16000,"reference":"ord-9001"}' | grep -iE '^HTTP|^sl-violations|^\{'
HTTP/1.1 201 Created
{"id":"ch-wm-1","status":"approved"}
```

`201`, um corpo `approved` e nenhum `sl-violations`: os dois arquivos dizem a verdade, até onde este
contrato enxerga.

## Ele confere quem chama também

Um proxy confere o que entra além do que sai. A mesma cobrança sem o cabeçalho `idempotency-key`:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/charges -H 'content-type: application/json' -d '{"amount_cents":16000,"reference":"ord-9001"}' | grep -iE '^HTTP|^sl-violations'
HTTP/1.1 422 Unprocessable Entity
```

O contrato exige o cabeçalho, então esta requisição seria um defeito de quem a mandou. O boxoffice
sempre manda um, mas **um cliente que o esquecesse seria pego aqui**, e não por um provedor que talvez
recusasse, talvez não.

## Mantendo um substituto honesto

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 262\" role=\"img\" aria-label=\"O boxoffice manda uma cobrança a um proxy do Prism iniciado com --errors, que a repassa a um substituto, o WireMock ou o stub. Acima do proxy fica o contrato, payments.yaml, e o proxy confere a requisição e a resposta contra ele. À direita, o provedor de verdade é conferido contra o mesmo contrato por testes de contrato, lição 10. Um substituto continua honesto enquanto as duas conferências passam.\"><defs><marker id=\"f11referee-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"230\" y=\"20\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o contrato</text><text x=\"315\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">payments.yaml</text><rect x=\"560\" y=\"20\" width=\"130\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o provedor</text><text x=\"625\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o de verdade</text><rect x=\"20\" y=\"170\" width=\"130\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">boxoffice</text><rect x=\"230\" y=\"170\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">proxy do Prism</text><text x=\"315\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">--errors</text><rect x=\"560\" y=\"170\" width=\"130\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um substituto</text><text x=\"625\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">WireMock, o stub</text><line x1=\"152\" y1=\"195\" x2=\"228\" y2=\"195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f11referee-ah)\"></line><text x=\"190\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma cobrança</text><line x1=\"402\" y1=\"195\" x2=\"558\" y2=\"195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f11referee-ah)\"></line><text x=\"480\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repassada</text><line x1=\"315\" y1=\"72\" x2=\"315\" y2=\"168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f11referee-ah)\"></line><text x=\"325\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">confere a requisição</text><text x=\"325\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">e a resposta</text><line x1=\"558\" y1=\"45\" x2=\"402\" y2=\"45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f11referee-ah)\"></line><text x=\"480\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">testes de contrato</text><text x=\"480\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lição 10</text><text x=\"355\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um substituto continua honesto enquanto as duas conferências passam</text></svg>", "caption": "Duas conferências se encontram no contrato do provedor: o substituto pelo proxy, e o provedor por testes de contrato."}
```

Duas conferências se encontram no contrato, e um substituto só é honesto enquanto as duas passam. A
primeira é o substituto contra o contrato: rode os testes do boxoffice com o `PAYMENTS_URL` apontando
para um proxy do Prism na frente do substituto, e toda cobrança que qualquer teste fizer é conferida
no caminho, então um mapping que se desviou reprova a execução que o usa. A segunda é o provedor
contra o contrato, porque o contrato também é só uma afirmação até alguém conferir o provedor de
verdade contra ele. Esse é o teste de contrato da lição 10, e é tarefa do provedor tanto quanto sua;
pergunte se eles fazem.

Dois hábitos fazem o resto. **Construa substitutos a partir da documentação e do contrato do
provedor**, nunca de memória nem do que o seu próprio código espera, porque um substituto escrito a
partir do seu código concorda com o seu código por construção. E quando o provedor anunciar uma
mudança, mude o contrato primeiro e deixe o árbitro dizer quais substitutos estão mentindo agora.

Um contrato também tem buracos. Este não lista nenhum `500`, embora provedores de verdade respondam um
de vez em quando, e o stub da seção 03 o responde de propósito no modo `down`. Este proxy aponta
qualquer status que o contrato não lista, como apontou o `200`. Se a culpa é do substituto ou do
contrato é uma pergunta para o provedor, e fazê-la faz parte do trabalho.
