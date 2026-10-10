---
title: Erros fazem parte do contrato
version: 1
---

**Uma resposta de erro é uma resposta como outra qualquer, e um cliente é escrito contra a forma
dela.** A crença a abandonar é a de que erros são a parte não planejada de uma API, onde vale tudo
desde que o código de status esteja certo. Um app que diz ao usuário *"só resta 1 lugar"* está lendo
o corpo de um `409`; se um endpoint põe a mensagem em `detail` e outro em `message`, o app mostra uma
caixa vazia para um deles.

O boxoffice responde todo erro numa forma só, a que a RFC 9457 define com o nome de **problem
details**. Três erros de três partes diferentes da API:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-999
{"type":"about:blank","title":"Not Found","status":404,"detail":"there is no show sh-999"}
ana@laptop:~/boxoffice$ curl -s -X PUT localhost:8080/v1/shows
{"type":"about:blank","title":"Method Not Allowed","status":405,"detail":"PUT is not allowed here"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders
{"type":"about:blank","title":"Unauthorized","status":401,"detail":"no bearer token"}
```

Um espetáculo que não existe, um método errado, um token que falta: três causas, e os mesmos quatro
campos toda vez.

| campo | guarda | quem lê |
|---|---|---|
| `type` | uma URI que nomeia o tipo de problema; `about:blank` quer dizer "nada além do código de status" | programas, para distinguir problemas |
| `title` | um resumo curto daquele tipo, igual toda vez que ele acontece | pessoas |
| `status` | o código de status de novo, dentro do corpo | qualquer coisa que guardou só o corpo, um log por exemplo |
| `detail` | o que deu errado **nesta** requisição | pessoas |

A RFC permite um quinto, `instance`, que nomeia a ocorrência, e qualquer outro campo que uma API
queira acrescentar; o boxoffice não usa nenhum dos dois. A separação entre `type` e `detail` é a que
interessa a quem testa: **um programa decide pelo `status` e pelo `type`, e nunca pelo texto do
`detail`.** O `type` do boxoffice é sempre `about:blank`, então aqui o código de status é tudo o que
um cliente tem para decidir. Uma API com dois tipos de `422` que valesse a pena distinguir daria a
cada um o seu `type`, e um teste conferiria o `type` em vez de analisar uma frase em inglês que
alguém um dia vai reescrever.

## O rótulo do corpo

Um problema é rotulado `application/problem+json`, não `application/json`. O `-w` do curl consegue
imprimir o rótulo sem o corpo:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{content_type}\n' localhost:8080/v1/shows/sh-999
404 application/problem+json
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{content_type}\n' localhost:8080/v1/orders
401 application/problem+json
```

O rótulo faz parte do contrato, e ele pega testes desprevenidos. **Um teste que confere se o tipo de
conteúdo começa com `application/json` falha em todo erro do boxoffice**, e um cliente que só
analisa corpos rotulados exatamente `application/json` os ignora. O corpo continua sendo JSON; o
`+json` no fim do rótulo diz isso, e uma verificação deveria aceitá-lo.

## A exceção, e por que ela é permitida

Uma parte do boxoffice não usa problem details. O endpoint de token responde seus erros na forma que
o OAuth 2.0 prescreve justamente para esse endpoint (RFC 6749, §5.2):

```
ana@laptop:~/boxoffice$ curl -s -w '%{http_code} %{content_type}\n' localhost:8080/oauth/token -d grant_type=password
{"error":"unsupported_grant_type"}
400 application/json
```

`{"error":"unsupported_grant_type"}` com `application/json`. Isso não é defeito: toda biblioteca
cliente de OAuth espera essa forma de um endpoint de token, e um documento de problema ali as
quebraria. Defeito seria o contrato não dizer isso, e é por isso que o `openapi.yaml` dá ao
endpoint de token uma resposta de erro própria, `OAuthError`, separada de `Problem`. **Duas formas
tudo bem; uma segunda forma não documentada não**, porque quem escreve um cliente só a descobre
quando o código dele falha nela.

## O que testar num erro

Para todo erro que um teste provoca, quatro verificações, nesta ordem:

1. o código de status é o que o contrato lista para aquela causa;
2. o tipo de conteúdo é o que o contrato nomeia, aqui `application/problem+json`;
3. o corpo tem os campos que o contrato exige, com `status` igual ao código de status;
4. o corpo não diz nada que não deveria: nenhum stack trace, nenhum caminho de arquivo, nenhum SQL.

A quarta não tem nada a ver com a forma e tudo a ver com o que um erro vaza. O `detail` é escrito
para pessoas, e um servidor descuidado põe a exceção nele. A seção 06 faz o boxoffice lançar uma, e
vale conferir o que voltou.
