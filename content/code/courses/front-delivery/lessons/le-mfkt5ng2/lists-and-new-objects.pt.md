---
title: Listas, e objetos que o cache não viu
version: 1
---

**Uma mutation que muda um objeto que o cache conhece atualiza toda consulta sozinha; uma mutation que
cria um não, porque o cache não tem como saber em quais listas ele entra.** Os passos 3 e 4 são os dois
casos.

## Mudando um objeto conhecido

```
3. Session:6: {"__typename":"Session","id":6,"date":"2026-10-15","minutes":45,"done":true}
```

A mutation pediu de volta só `id` e `done`. O Apollo leu a resposta, viu `__typename` `Session` e `id` 6,
e gravou `done: true` na `Session:6` que já existia. Toda consulta que inclui a sessão 6 agora a lê como
feita, sem rodar de novo. **É por isso que a convenção da aula 9, de devolver o objeto mudado, importa**:
com um cliente, os campos devolvidos são a atualização.

## Criando um novo

```
4. Course:git sessions: [{"__ref":"Session:3"}]
5. Course:git sessions: [{"__ref":"Session:3"},{"__ref":"Session:7"}]
```

O `addSession` devolveu a sessão 7, e o cache guardou a `Session:7`. Mas a lista de sessões do git
continua só com a sessão 3. A resposta não disse nada sobre em qual lista de curso a sessão nova entra, nem
em que posição, e o cache não adivinha. O passo 5 perguntou ao servidor de novo, e a lista voltou com as
duas.

Há três jeitos de pôr uma lista em dia depois de uma criação, do menor trabalho para o maior:

- **Perguntar de novo.** `refetchQueries: ["Planner"]` na mutation roda a consulta nomeada mais uma vez
  quando a mutation termina. Custa um pedido e está sempre certo.
- **Devolver o pai.** Se o `addSession` devolvesse o curso com as sessões, o cache atualizaria a lista a
  partir dessa resposta, como atualizou o `done` no passo 3. Isso exige que o schema ofereça.
- **Editar o cache.** A função `update` da mutation recebe o cache e pode acrescentar a nova referência às
  `sessions` da `Course:git` com `cache.modify`. Nenhum pedido, e um código que precisa conhecer cada lista
  em que o objeto entra.

Apagar é o mesmo problema ao contrário: a entrada do objeto pode ser removida, mas uma lista que apontava
para ele precisa ser avisada. O planner nunca cria sessões no servidor neste curso; o exercício final
pergunta qual dos três você escolheria se criasse.
