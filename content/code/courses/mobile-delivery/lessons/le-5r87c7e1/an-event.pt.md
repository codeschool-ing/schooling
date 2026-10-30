---
title: Um evento, e o esquema que o decide
version: 1
---

**Um evento de analytics é o registro de que algo aconteceu no app: um nome, um horário, algumas
propriedades e um identificador da instalação onde aconteceu.** `session_done` às 19:40 com
`minutes: 30`, da instalação `i042`. Tudo o que uma equipe de produto pergunta depois, quantos, com
que frequência, em que ordem, é uma consulta sobre linhas assim.

## Quatro decisões por evento

- **O nome diz o que aconteceu, no passado, do lado da pessoa**: `session_done`, e não
  `button_tap_3` nem `WeekViewModel.complete`. Um nome que descreve o código muda quando o código muda,
  e os números do mês passado deixam de significar a mesma coisa.
- **As propriedades são números e escolhas, nunca o que a pessoa escreveu.** `minutes: 30` e
  `course_count: 2` são medidas; o nome de um curso, uma anotação, uma busca são conteúdo da pessoa.
- **O identificador é o da instalação, aleatório**, a mesma ideia do coletor de crashes da lição 12:
  ele conta e ordena sem nomear.
- **O horário é o do aparelho, no momento em que aconteceu.** Eventos são enfileirados e mandados
  depois, como relatórios de crash, porque um celular fica offline boa parte do dia.

## O esquema é a decisão, escrita

Uma equipe que deixa qualquer código mandar qualquer evento com quaisquer propriedades acaba com
milhares de nomes de evento, metade com erro de digitação, e propriedades que ninguém lembra de ter
acrescentado, uma delas um endereço de e-mail. A cura é um **esquema**: a lista de eventos que o app
pode mandar e as propriedades que cada um pode levar, guardada no repositório e revisada como código.
**Um evento ou uma propriedade fora do esquema é recusado**, no momento em que é mandado, em
desenvolvimento, onde alguém vê o erro.

O esquema do planner tem quatro eventos:

| evento | propriedades | a pergunta que ele responde |
|---|---|---|
| `app_open` | nenhuma | quantas instalações são usadas |
| `course_added` | `course_count` | a pessoa começa |
| `session_added` | `minutes` | ela planeja |
| `session_done` | `minutes` | ela estuda |

A seção "Um funil" monta o código que o impõe, e o inventário da lição 5 leva uma linha para os
quatro: eventos de produto, não ligados à pessoa, opcionais.
