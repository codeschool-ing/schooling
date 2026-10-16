---
title: Scripts que rodam antes da requisição
version: 1
---

**Um script de pré-requisição roda antes de a requisição ser montada, então pode produzir um valor de
que ela precisa.** Um teste lê uma resposta; um script de pré-requisição prepara uma pergunta. A
coleção tem dois deles, e cada um resolve um problema que o encadeamento da seção 04 deixou aberto.

A ordem importa aqui. Para cada requisição o Postman roda o script de pré-requisição da coleção,
depois o da pasta, depois o da própria requisição, e só então resolve as variáveis e manda. Então um
valor definido num script de pré-requisição já está no lugar quando `{{name}}` é substituído.

## Uma chave nova para cada pedido

**Create order** e **Order seats** rodam, cada uma, uma linha antes de mandar:

```js
pm.variables.set('idempotencyKey', pm.variables.replaceIn('{{$guid}}'));
```

`{{$guid}}` é uma das *variáveis dinâmicas* do Postman: toda vez que é resolvida, produz um
identificador aleatório novo. `replaceIn` a resolve agora, e `pm.variables.set` guarda o resultado no
escopo local, que dura esta requisição. O cabeçalho da requisição, `Idempotency-Key:
{{idempotencyKey}}`, então o manda.

A chave é a promessa do cliente de que uma requisição repetida é a mesma requisição. O boxoffice
guarda uma chave junto com a resposta que deu. Uma segunda requisição com aquela chave recebe a
primeira resposta de novo, e nenhum lugar a mais é vendido. **É exatamente por isso que um teste não
deve reaproveitar uma.** Uma coleção com chave fixa no cabeçalho criaria um pedido na primeira
execução. Em toda execução seguinte contra o mesmo boxoffice, receberia de volta o pedido da
primeira: todos os testes passando, nenhum pedido novo criado. A lição 13 testa a idempotência em
si, incluindo um defeito no jeito como o boxoffice cumpre a promessa.

## Um token, só quando preciso

O script de pré-requisição da própria coleção, o primeiro `event` do arquivo, roda antes de toda
requisição. Na maior parte das vezes não faz nada:

```js
const expires = Number(pm.collectionVariables.get('tokenExpires') || 0);
if (!pm.collectionVariables.get('token') || Date.now() >= expires) {
```

Ele só pede um token quando não há nenhum, ou quando o horário guardado por **Get token** já passou.
`pm.sendRequest` manda essa requisição de dentro do script: o mesmo `POST /oauth/token`, com o id e
o segredo do cliente vindos do ambiente. O callback dele guarda a resposta exatamente como Get token
faz. Se a resposta não for `200`, ele lança um erro, e o erro diz o status.

Duas execuções mostram por que ele está ali:

- Rodar uma pasta sozinha. A pasta `seat rules`, na seção 06, roda sem a pasta `auth` antes dela,
  então nada teria buscado um token. A execução da seção 02 começou com uma linha
  `POST /oauth/token` embaixo de **List shows** que nenhuma requisição pediu: era este script.
- Uma sessão do Postman que dura. Variáveis da coleção mantêm o valor no aplicativo entre um envio e
  outro. Um token guardado às nove horas já expirou às nove e quinze, e sem a conferência de expiração
  toda requisição de pedido responderia `401` até alguém rodar Get token de novo.

Os trinta segundos tirados da expiração são uma folga. Um token que expira enquanto a requisição está
a caminho é recusado, e uma folga custa uma requisição de token a mais de vez em quando.

**Um script de pré-requisição é código no seu teste que ninguém testa.** Mantenha-o curto e num
lugar só, na coleção e não numa cópia por requisição. Faça-o falhar alto, como este faz com `throw`.
Um script que engolisse um token recusado mandaria todo pedido sem token e deixaria você lendo uma
coluna de `401` atrás da causa.
