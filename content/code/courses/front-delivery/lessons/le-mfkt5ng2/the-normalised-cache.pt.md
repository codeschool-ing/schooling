---
title: O cache normalizado
version: 1
---

**O cache do Apollo não guarda respostas; guarda objetos, uma entrada cada, com chave de tipo e id.** O
passo 1 pediu três cursos com as sessões, e o cache saiu com nove entradas e uma raiz:

```
1. keys: ["Session:1","Session:5","Course:html-css","Session:2","Session:4","Session:6","Course:javascript","Session:3","Course:git","ROOT_QUERY"]
   Session:6: {"__typename":"Session","id":6,"date":"2026-10-15","minutes":45,"done":false}
```

Desmontar uma resposta aninhada em entradas planas assim é a **normalização**, e é o que faz do cache mais
do que uma lista de respostas antigas.

- **A chave é `__typename` mais `id`.** O Apollo acrescenta `__typename` a todo objeto de toda consulta
  que manda, então cada objeto volta dizendo de que tipo é. `Session:6` é a sessão 6 em qualquer consulta
  em que ela chegue.
- **Objetos apontam uns para os outros.** A entrada de um curso guarda as sessões como referências,
  `{"__ref": "Session:3"}`, e não como cópias. Existe uma sessão 6 só, e toda consulta que a inclui lê
  essa.
- **`ROOT_QUERY`** registra o que cada campo de `Query` respondeu: que `courses` são essas três
  referências. Uma consulta posterior de `courses` com os mesmos campos pode ser respondida a partir dela.

## Por que uma entrada importa

Dois lugares de uma página mostrando a sessão 6, a página do curso e um resumo da semana, digamos, são
duas consultas que chegam à `Session:6`. Mude essa entrada e as duas veem a mudança, sem código nenhum
dizendo que elas têm relação. Esse é o passo 3, duas seções adiante, e é a coisa mais útil que um cliente
GraphQL faz.

## Quando não há `id`

A normalização precisa de algo para servir de chave. Um objeto cujo tipo não tem campo `id`, ou uma
consulta que não o pediu, é guardado dentro do pai, e as atualizações nele deixam de chegar às outras
consultas. **Peça o `id` de todo objeto que você quer que o cache acompanhe**, e é por isso que o fragment
do planner na aula 9 tem `id` tanto na sessão quanto no curso dela. Um tipo cuja identidade é outro campo
é informado disso nas opções do cache, com `typePolicies: { Course: { keyFields: ["slug"] } }`.
