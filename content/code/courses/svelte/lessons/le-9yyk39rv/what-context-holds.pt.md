---
title: O que um contexto guarda
version: 1
---

**Um contexto guarda o valor que foi definido, uma vez, e repassa exatamente esse valor.** Não é um
segundo sistema de reatividade. Os filhos se atualizam quando o que eles leem pelo contexto muda,
então o que você põe num contexto decide se eles algum dia vão se atualizar.

O contexto do planner guarda a instância de `Planner`, um objeto cujos campos são signals. Um filho
guarda a instância e lê `planner.total` sempre que precisa, e cada leitura é rastreada, então um filho
sempre vê o total atual. Essa é a forma a usar: **ponha num contexto um objeto com campos reativos, e
leia os campos onde eles são usados.**

Duas coisas quebram isso, e vale vê-las no papel antes de encontrá-las numa página:

| o pai define… | um filho lê… | o que acontece |
|---|---|---|
| `setTotal(planner.total)`, um número | `getTotal()` | o número como era quando foi definido, para sempre: um número não tem campos para rastrear |
| `setPlanner(planner)`, e depois `planner = new Planner(…)` | `getPlanner()` | a instância antiga: os filhos ficaram com o objeto que receberam, não com a variável |
| `setPlanner(planner)`, e as mudanças passam pelos campos e métodos dele | `getPlanner().total` | o total atual, sempre |

A primeira linha é o `hours` da aula 2 de novo, um valor copiado uma vez, num lugar novo. O compilador
do Svelte avisa sobre a versão simples disso, `setContext('total', total)` com uma variável `$state`,
com o mesmo `state_referenced_locally` que você viu na aula 2. Quando um único valor que muda é de fato
tudo de que um filho precisa, passe uma função que o leia, `setTotal(() => planner.total)`, e chame-a
no filho; uma chamada de função é lida quando roda, então fica atual.

A segunda linha é o motivo de o planner ser definido como instância e nunca substituído. A aula 13
carrega os dados do servidor, e a partir daí os campos do planner são atualizados no lugar em vez de
um `Planner` novo ser criado, para que todo componente que guarda a instância continue funcionando.
