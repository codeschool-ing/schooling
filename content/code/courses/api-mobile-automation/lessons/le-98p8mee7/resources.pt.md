---
title: Recursos, endereços e uma requisição que se basta
version: 1
---

**REST é um jeito de organizar uma API: toda coisa que a API conhece é um recurso, todo recurso tem
um endereço, e os métodos do HTTP são os únicos verbos.** É um estilo, descrito por Roy Fielding em
2000, e não um padrão que alguém certifique. A maioria das APIs que se dizem REST segue parte dele,
e essa parte é a que quem testa encontra todo dia: substantivos no caminho, verbos no método.

Uma primeira imagem comum é a de uma API como uma lista de funções com nomes esquisitos,
`getShows`, `createOrder`, `cancelOrder`. O boxoffice não tem nome assim em lugar nenhum. Ele tem
coisas, e você age sobre elas com o método:

| endereço | o que é | métodos |
|---|---|---|
| `/v1/shows` | a **coleção** de espetáculos | `GET` |
| `/v1/shows/sh-103` | um espetáculo, um **item** dessa coleção | `GET` |
| `/v1/orders` | a coleção de pedidos | `POST` acrescenta um |
| `/v1/orders/ord-1001` | um pedido | `GET` o lê, `DELETE` o cancela |

O `v1` na frente é a versão da API. Uma mudança que quebraria clientes existentes vai para debaixo
de `/v2/`, e o endereço antigo continua respondendo aos clientes que ninguém consegue atualizar,
como um app num celular que nunca foi atualizado.

## Uma coleção, e um filtro sobre ela

Um `GET` numa coleção lista os itens dela. O jq consegue tirar um campo de cada um, que é o jeito
mais rápido de ver o que uma coleção guarda:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows | jq '.shows[].id'
"sh-101"
"sh-102"
"sh-103"
```

A query string estreita uma coleção sem mudar o que o endereço nomeia. `?date=` fica com os
espetáculos de um dia:

```
ana@laptop:~/boxoffice$ curl -s 'localhost:8080/v1/shows?date=2026-11-07' | jq -c '.shows[] | {id, starts_at}'
{"id":"sh-102","starts_at":"2026-11-07T20:00:00-03:00"}
```

O caminho diz *qual* recurso; a query diz *que parte dele*. Quem testa trata cada parâmetro de
query como uma entrada própria, com valores válidos, inválidos e uma borda, e a seção 06 volta a
este.

## Criando, e ouvindo onde ficou

Fazer um pedido exige um token, o mesmo que a lição 1 buscou. A lição 3 o explica; por ora, peça
um de novo:

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

Um `POST` na coleção cria um item, e o servidor escolhe o endereço dele. Aqui só importam a linha de
status e o cabeçalho `location`, então o `grep` fica com esses dois:

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":2}' | grep -iE '^HTTP|^location'
HTTP/1.1 201 Created
location: /v1/orders/ord-1001
```

O pedido novo agora é um recurso por direito próprio, no endereço que o servidor deu.

## Toda requisição carrega tudo

**Um servidor REST não guarda memória da conversa entre uma requisição e outra.** Essa propriedade
se chama ausência de estado (*statelessness*), e a imagem errada dela é a de um site em que você
entra uma vez e depois toda página sabe quem você é. O boxoffice sabe quem você é só durante uma
requisição, e só porque aquela requisição disse:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders/ord-1001 -H "authorization: Bearer $TOKEN"
{"id":"ord-1001","show_id":"sh-101","seats":2,"total_cents":16000,"status":"confirmed","payment":"ch-local-ord-1001"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders/ord-1001
{"type":"about:blank","title":"Unauthorized","status":401,"detail":"no bearer token"}
```

O mesmo endereço, uma requisição depois da outra, do mesmo terminal. A primeira levava o token e
recebeu o pedido; a segunda não levava, e o boxoffice não fazia ideia de que tinha acabado de
responder ao mesmo cliente. Nada da primeira requisição sobreviveu até a segunda.

**É isso que torna possível testar uma API requisição por requisição.** Cada requisição contém a
pergunta inteira, então pode ser mandada por qualquer programa, em qualquer ordem, quantas vezes for,
e a resposta depende só do que ela diz e dos dados que o servidor guarda, nunca de qual requisição
veio antes. Um teste de `GET /v1/orders/ord-1001` precisa de um token e de um pedido existente; não
precisa de uma sequência de telas repetida para chegar ao estado certo.

Os dados são a metade que ainda pode morder. O pedido acima existe porque uma requisição anterior o
criou, então um teste que o lê depende de essa requisição anterior ter rodado. A lição 12 trata do
que dá errado quando testes compartilham dados assim, e de como evitar.
