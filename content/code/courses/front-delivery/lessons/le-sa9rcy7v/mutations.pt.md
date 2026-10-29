---
title: Mutations
version: 1
---

**Uma mutation é um pedido para mudar algo, escrito como uma consulta e respondido como uma: com os campos
que você escolher do que foi mudado.** O tipo `Mutation` do schema lista toda mudança que um cliente pode
pedir, e nada fora dessa lista pode ser mudado pelo GraphQL.

```
ana@dev:~/planner$ node api/ask.mjs 'mutation MarkDone($id: Int!) { markDone(id: $id) { id done course { title } } }' '{"id": 5}'
{
  "data": {
    "markDone": {
      "id": 5,
      "done": true,
      "course": {
        "title": "HTML and CSS"
      }
    }
  }
}
```

A sessão 5 estava planejada e agora está feita, e a resposta diz isso no mesmo pedido. **Devolver o objeto
mudado é a convenção**, e é o que deixa um cliente atualizar a tela sem perguntar de novo: os clientes da
aula 10 pegam a resposta de uma mutation e a põem no cache, e toda parte da página que mostra a sessão 5
se atualiza.

## Um tipo input

`addSession` recebe um argumento do tipo input `NewSession`, e a variável dele é declarada com esse tipo:

```
ana@dev:~/planner$ node api/ask.mjs 'mutation AddSession($input: NewSession!) { addSession(input: $input) { id date minutes done } }' '{"input": {"course": "git", "date": "2026-10-20", "minutes": 30}}'
{
  "data": {
    "addSession": {
      "id": 7,
      "date": "2026-10-20",
      "minutes": 30,
      "done": false
    }
  }
}
```

A sessão nova ganhou o id 7, o próximo livre, e começa como não feita. O `graphql` conferiu o valor contra
`NewSession` antes de a função rodar: um `minutes` igual a `"thirty"` seria recusado com uma mensagem
dizendo isso, e um `date` faltando também.

## A memória do servidor

O servidor guarda as sessões na memória. Peça o curso de novo e a sessão nova está lá; reinicie o
servidor e ela some, de volta às seis do `courses.json`:

```
ana@dev:~/planner$ node api/ask.mjs '{ course(id: "git") { minutesPlanned } }'
{
  "data": {
    "course": {
      "minutesPlanned": 60
    }
  }
}
```

Trinta minutos da sessão 3, e trinta da que acabou de entrar.

## Consultas leem, mutations escrevem

A diferença entre `query` e `mutation` é uma promessa, e não um mecanismo: um servidor poderia mudar dados
dentro de um campo de consulta, e nada no GraphQL o impediria. O que a especificação define é que os
campos de cima de uma consulta podem rodar em paralelo, enquanto os de uma mutation rodam um depois do
outro, na ordem em que foram escritos. Dois `markDone` numa mutation são aplicados do primeiro ao último.
