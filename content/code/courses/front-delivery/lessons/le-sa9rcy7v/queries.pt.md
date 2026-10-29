---
title: Consultas
version: 1
---

**Uma consulta é uma árvore de campos, que começa num campo de `Query`, e a resposta é a mesma árvore com
os valores preenchidos.** Todo campo de um objeto precisa ser escolhido; um campo que é objeto precisa
das próprias chaves, até chegar aos escalares. Não volta nada que não tenha sido pedido.

## Campos, e campos dentro de campos

```
ana@dev:~/planner$ node api/ask.mjs '{ course(id: "javascript") { title minutesPlanned sessions { date minutes done } } }'
{
  "data": {
    "course": {
      "title": "JavaScript",
      "minutesPlanned": 145,
      "sessions": [
        {
          "date": "2026-10-06",
          "minutes": 40,
          "done": true
        },
        {
          "date": "2026-10-12",
          "minutes": 60,
          "done": true
        },
        {
          "date": "2026-10-15",
          "minutes": 45,
          "done": false
        }
      ]
    }
  }
}
```

Três coisas num pedido só: o curso, um número que o servidor calculou, e as sessões dentro dele.
`course(id: "javascript")` passa um **argumento** ao campo, que a função `course` do servidor recebe como
`{ id }`. Os campos voltam na ordem em que foram pedidos.

## Percorrendo o grafo

O schema liga `Session` de volta a `Course`, então uma consulta pode andar em círculo, e o servidor a
segue até onde for pedido:

```
ana@dev:~/planner$ node api/ask.mjs '{ course(id: "git") { sessions { date course { title } } } }'
{
  "data": {
    "course": {
      "sessions": [
        {
          "date": "2026-10-08",
          "course": {
            "title": "Git"
          }
        }
      ]
    }
  }
}
```

Esse é o *grafo* do nome: tipos ligados por campos, que uma consulta percorre em qualquer direção que o
schema permita. É também por isso que um servidor público limita a profundidade das consultas: nada na
linguagem impede uma consulta de aninhar `course { sessions { course { sessions … } } }` cem níveis abaixo.

## Aliases

Um campo pode ser pedido duas vezes, com argumentos diferentes, se cada um ganhar um nome próprio, um
**alias**, que é o que a resposta usa como chave:

```
ana@dev:~/planner$ node api/ask.mjs '{ js: course(id: "javascript") { minutesPlanned } git: course(id: "git") { minutesPlanned } }'
{
  "data": {
    "js": {
      "minutesPlanned": 145
    },
    "git": {
      "minutesPlanned": 30
    }
  }
}
```

## Um curso que não existe

```
ana@dev:~/planner$ node api/ask.mjs '{ course(id: "rust") { title } }'
{
  "data": {
    "course": null
  }
}
```

`course` não tem `!` no schema, então um id desconhecido responde `null`, sem erro. A página que pediu
precisa tratar `null` como uma resposta de verdade, do jeito que o planner já mostra a sua página de *not
found* quando nenhum curso corresponde ao endereço.
