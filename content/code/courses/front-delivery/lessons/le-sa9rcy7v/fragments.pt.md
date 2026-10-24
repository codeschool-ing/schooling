---
title: Fragments
version: 1
---

**Um fragment é um conjunto de campos com nome, sobre um tipo, que uma consulta pode espalhar onde quer
que esse tipo apareça.** É o jeito do GraphQL de não se repetir, e num front-end é mais do que isso: deixa
cada pedaço da interface dizer de quais campos precisa.

O planner precisa das mesmas cinco coisas sobre toda sessão, onde quer que a receba: o id, a data, os
minutos, se está feita e a qual curso pertence. Isso é um fragment:

```
fragment SessionFields on Session {
  id
  date
  minutes
  done
  course {
    id
  }
}
```

`on Session` diz a qual tipo ele se aplica, e o servidor se recusa a espalhá-lo em qualquer outro lugar.
Espalhado com `...`, ele vale pelos seus campos:

```
ana@dev:~/planner$ node api/ask.mjs 'query Planner { courses { id title sessions { ...SessionFields } } } fragment SessionFields on Session { id date minutes done course { id } }' | head -20
{
  "data": {
    "courses": [
      {
        "id": "html-css",
        "title": "HTML and CSS",
        "sessions": [
          {
            "id": 1,
            "date": "2026-10-05",
            "minutes": 50,
            "done": true,
            "course": {
              "id": "html-css"
            }
          },
          {
            "id": 5,
            "date": "2026-10-14",
            "minutes": 25,
```

O fragment vai junto com a consulta, na mesma string: o servidor não guarda fragments próprios, e uma
consulta que espalha um que não recebeu é recusada.

## Um formato para a consulta e para a mutation

O planner lê sessões com a consulta acima e as grava com `markDone`, e as duas deveriam lhe dar uma sessão
no mesmo formato, para que o código que transforma a resposta numa `Session` seja escrito uma vez só. As
duas espalham o mesmo fragment:

```
ana@dev:~/planner$ node api/ask.mjs 'mutation MarkDone($id: Int!) { markDone(id: $id) { ...SessionFields } } fragment SessionFields on Session { id date minutes done course { id } }' '{"id": 6}'
{
  "data": {
    "markDone": {
      "id": 6,
      "date": "2026-10-15",
      "minutes": 45,
      "done": true,
      "course": {
        "id": "javascript"
      }
    }
  }
}
```

## Fragments ao lado dos componentes

A ideia vai além em apps maiores. Um componente que desenha uma linha de sessão sabe quais campos
desenha, então declara um fragment ao lado do seu código, e a consulta da página espalha os fragments dos
componentes que ela renderiza. Mude a linha para mostrar o título do curso e você muda o fragment dela, e
toda consulta que renderiza uma linha passa a pedir o título. **O Relay é construído em torno dessa
regra**, chamada colocation de fragments, e a aula 10 a mostra; o Apollo aceita o mesmo hábito sem
obrigar.
