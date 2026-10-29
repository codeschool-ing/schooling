---
title: Variáveis e nomes de operação
version: 1
---

**Uma consulta escrita uma vez e preenchida com variáveis é como um app manda GraphQL; uma consulta
montada colando valores numa string é um bug esperando por uma aspa.** A consulta declara o que recebe,
com tipos, e os valores viajam ao lado dela na requisição.

```
query CourseSessions($id: ID!) {
  course(id: $id) {
    title
    sessions {
      date
      minutes
    }
  }
}
```

- **`query CourseSessions`** dá um nome à operação. O log do servidor o imprime, o painel de rede de um
  navegador o mostra, e os relatórios de erro da aula 11 o carregam, então *CourseSessions falhou* diz
  mais do que *uma consulta falhou*.
- **`($id: ID!)`** declara uma variável, o tipo dela e que ela é obrigatória. O servidor confere o valor
  contra esse tipo antes de qualquer coisa rodar.
- **`course(id: $id)`** a usa.

```
ana@dev:~/planner$ node api/ask.mjs 'query CourseSessions($id: ID!) { course(id: $id) { title sessions { date minutes } } }' '{"id": "html-css"}'
{
  "data": {
    "course": {
      "title": "HTML and CSS",
      "sessions": [
        {
          "date": "2026-10-05",
          "minutes": 50
        },
        {
          "date": "2026-10-14",
          "minutes": 25
        }
      ]
    }
  }
}
```

O log do servidor continua dizendo `(anonymous)` para ela. O nome dentro da consulta basta para o
`graphql` executá-la; o que o servidor registra é o campo `operationName` da própria requisição, que o
`ask.mjs` deixa de fora. O cliente do planner, mais adiante na aula, manda os dois.

## Uma variável que falta

```
ana@dev:~/planner$ node api/ask.mjs 'query CourseSessions($id: ID!) { course(id: $id) { title } }'
{
  "errors": [
    {
      "message": "Variable \"$id\" has invalid value: Expected a value of non-null type \"ID!\" to be provided.",
      "locations": [
        {
          "line": 1,
          "column": 22
        }
      ]
    }
  ]
}
```

Nada rodou: o servidor recusou a requisição porque uma variável obrigatória ficou sem valor, e disse qual.

## Por que não montar a string

``{ course(id: "${id}") { title } }`` parece mais curto, e dá errado na primeira vez que um valor tiver
uma aspa ou uma chave, o que um título de curso digitado por uma pessoa um dia vai ter. Um valor colado na
consulta também pode mudar o que a consulta pede, o mesmo erro de montar SQL a partir de strings. Com
variáveis, o texto da consulta nunca muda, então pode ser escrito uma vez, conferido uma vez pelo teste do
fim desta aula, e reconhecido pelo nome em todo log.
