---
title: WireMock, substitutos descritos em arquivos
version: 1
---

**O WireMock é um servidor substituto cujas respostas são escritas como dados, e não como código.**
Cada resposta é um *mapping*, um arquivo JSON que diz que requisições ele aceita e o que mandar de
volta. O WireMock lê um diretório deles, responde o que casa, registra tudo o que recebe e diz em
detalhe quando uma requisição não casou com nada. Ele é escrito em Java, é livre e de código aberto,
sob a licença Apache. Roda como biblioteca dentro de um teste Java, como os testes REST Assured da
lição 7 poderiam usar, ou como servidor sozinho, que é como esta seção o roda.

## Dois mappings

O stub da seção 03 mudava a resposta quando você mandava. O WireMock também consegue escolher a
resposta a partir da própria requisição, e dois mappings bastam para mostrar isso: cobranças
aprovadas, a não ser que o valor passe de R$ 400,00. Crie o diretório com
`mkdir -p ~/boxoffice/wiremock/mappings`. O primeiro mapping aprova; salve como
`wiremock/mappings/charge-approved.json`:

```json
{
  "priority": 5,
  "request": {
    "method": "POST",
    "url": "/charges",
    "headers": { "Content-Type": { "contains": "application/json" } },
    "bodyPatterns": [{ "matchesJsonPath": "$.amount_cents" }]
  },
  "response": {
    "status": 201,
    "headers": { "Content-Type": "application/json" },
    "jsonBody": { "id": "ch-wm-1", "status": "approved" }
  }
}
```

O segundo recusa as grandes; salve como `wiremock/mappings/charge-declined.json`:

```json
{
  "priority": 1,
  "request": {
    "method": "POST",
    "url": "/charges",
    "bodyPatterns": [{ "matchesJsonPath": "$[?(@.amount_cents > 40000)]" }]
  },
  "response": {
    "status": 201,
    "headers": { "Content-Type": "application/json" },
    "jsonBody": { "id": "ch-wm-2", "status": "declined" }
  }
}
```

Um mapping tem um `request`, que é um padrão, e um `response`, que é o que mandar. Leia os padrões
linha por linha:

| campo | nestes arquivos | casa com |
|---|---|---|
| `method`, `url` | `POST`, `/charges` | exatamente esse método e esse caminho; `urlPath` ignoraria a query string |
| `headers` | `Content-Type` contém `application/json` | um cabeçalho pelo nome, sem ligar para maiúsculas, comparado por `equalTo`, `contains`, `matches` e outros |
| `bodyPatterns` | `matchesJsonPath` | um corpo em que esse JSONPath encontra algo: um campo que existe, ou um filtro que vale |
| `priority` | 1 e 5 | quando dois mappings casam, **o número menor vence** |

O pedido de seis lugares do sh-101, 48000 centavos, casa com os dois arquivos. A prioridade 1 escolhe
a recusa, e sem ela o WireMock escolheria pela regra dele, o mapping acrescentado mais recentemente,
que não é uma regra da qual você quer que um teste dependa.

## Iniciando

O WireMock roda no Java 21 que a lição 7 instalou. Baixe o jar standalone, o servidor inteiro num
arquivo só, do Maven Central. O `-f` do curl faz um download recusado falhar alto, em vez de salvar
uma página de erro com o nome do jar:

```
ana@laptop:~/boxoffice$ curl -fsSL -o wiremock/wiremock-standalone-3.13.2.jar https://repo1.maven.org/maven2/org/wiremock/wiremock-standalone/3.13.2/wiremock-standalone-3.13.2.jar
ana@laptop:~/boxoffice$ ls -lh wiremock/*.jar
-rw-r--r-- 1 ana ana 19M Oct 10 16:52 wiremock/wiremock-standalone-3.13.2.jar
```

Inicie num terminal só dele. `--root-dir` indica o diretório que contém `mappings`, e
`--disable-banner` deixa de fora o logotipo grande que ele imprime se não for avisado:

```
ana@laptop:~/boxoffice$ java -jar wiremock/wiremock-standalone-3.13.2.jar --port 8091 --root-dir wiremock --disable-banner

The WireMock server is started .....
version:                      3.13.2
port:                         8091
enable-browser-proxying:      false
disable-banner:               true
no-request-journal:           false
verbose:                      false

extensions:                   response-template,webhook
```

De outro terminal, uma cobrança de R$ 160,00 e uma de R$ 480,00:

```
ana@laptop:~/boxoffice$ curl -si localhost:8091/charges -H 'content-type: application/json' -d '{"amount_cents":16000,"reference":"ord-1001"}'
HTTP/1.1 201 Created
Content-Type: application/json
Matched-Stub-Id: d43d7556-9f26-49ab-9b6b-13ab3823ba2c
Transfer-Encoding: chunked

{"id":"ch-wm-1","status":"approved"}
ana@laptop:~/boxoffice$ curl -s localhost:8091/charges -H 'content-type: application/json' -d '{"amount_cents":48000,"reference":"ord-1002"}'; echo
{"id":"ch-wm-2","status":"declined"}
```

`Matched-Stub-Id` indica o mapping que respondeu, um id que o WireMock deu a cada arquivo quando leu o
diretório, então o seu será outro. A segunda cobrança voltou recusada: o filtro valeu, e a prioridade
1 venceu.

## Uma requisição que não casa com nada

**É aqui que o WireMock se paga.** Um stub escrito à mão que recebe uma requisição para a qual não
foi escrito em geral responde algo inútil, ou responde como se estivesse tudo bem. O WireMock
responde `404` e diz que mapping chegou mais perto e por que foi recusado. Mande uma cobrança do jeito
que um cliente com um pequeno bug mandaria, com o valor num campo chamado `amount`:

```
ana@laptop:~/boxoffice$ curl -si localhost:8091/charges -H 'content-type: application/json' -d '{"amount":16000,"reference":"ord-1003"}'
HTTP/1.1 404 Not Found
Content-Type: text/plain;charset=UTF-8
Transfer-Encoding: chunked


                                               Request was not matched
                                               =======================

-----------------------------------------------------------------------------------------------------------------------
| Closest stub                                             | Request                                                  |
-----------------------------------------------------------------------------------------------------------------------
                                                           |
POST                                                       | POST
/charges                                                   | /charges
                                                           |
$[?(@.amount_cents > 40000)]                               | {"amount":16000,"reference":"ord-1003"}             <<<<< Body does not match
                                                           |
-----------------------------------------------------------------------------------------------------------------------
```

A coluna da esquerda é o mapping mais próximo, a da direita é a requisição, e a linha com `<<<<<` é a
diferença. O WireMock escolheu o mapping de recusa como o mais próximo porque ele tem menos condições
para falhar, e os dois mappings recusaram o corpo pelo mesmo motivo: nenhum dos JSONPath encontra um
`amount_cents`. Quando um teste falha porque o substituto "não respondeu", este relatório é a
primeira coisa a ler, e em geral ele transforma o problema numa correção de uma palavra.

## O boxoffice, apontado para o WireMock

Esvazie o journal do que o curl mandou, para que o que vem a seguir seja só do boxoffice. O journal é
o registro do WireMock de toda requisição que ele recebeu:

```
ana@laptop:~/boxoffice$ curl -s -X DELETE localhost:8091/__admin/requests; echo
{}
```

Pare o boxoffice com Ctrl-C e inicie de novo com o endereço novo:

```
ana@laptop:~/boxoffice$ PAYMENTS_URL=http://localhost:8091 node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

O seu token da seção 03 continua valendo, embora o boxoffice tenha reiniciado: um token é conferido
pela assinatura e pela validade, e nada sobre ele ficou guardado na memória que o reinício apagou.
Peça dois lugares, depois seis:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":2}'
{"id":"ord-1001","show_id":"sh-101","seats":2,"total_cents":16000,"status":"confirmed","payment":"ch-wm-1"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":6}'
{"type":"about:blank","title":"Payment Required","status":402,"detail":"the payment was declined"}
```

`201` com `ch-wm-1` do primeiro mapping, e `402` do segundo.

## Perguntando o que ele recebeu

**Um substituto que registra é um spy, e a API de administração do WireMock é como um teste lê o
registro.** Todo endereço de administração começa com `/__admin`. `requests/count` conta as
requisições que casam com um padrão escrito na mesma linguagem do `request` de um mapping, e
`requests` devolve o próprio journal, da mais nova para a mais antiga:

```
ana@laptop:~/boxoffice$ curl -s localhost:8091/__admin/requests/count -d '{"method":"POST","url":"/charges"}'; echo
{
  "count" : 2,
  "requestJournalDisabled" : false
}
ana@laptop:~/boxoffice$ curl -s localhost:8091/__admin/requests | jq -c '.requests[].request | {key: .headers["idempotency-key"], body}'
{"key":"ord-1002","body":"{\"amount_cents\":48000,\"reference\":\"ord-1002\"}"}
{"key":"ord-1001","body":"{\"amount_cents\":16000,\"reference\":\"ord-1001\"}"}
```

Duas cobranças, os valores que um teste esperaria, e a chave de idempotência que o boxoffice mandou
com cada uma. Um teste que afirma "o boxoffice cobrou 48000 por seis lugares" agora é uma requisição,
e essa afirmação não pode ser feita contra um provedor de verdade de jeito nenhum.
