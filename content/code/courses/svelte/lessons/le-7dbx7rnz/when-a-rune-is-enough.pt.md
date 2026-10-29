---
title: Quando uma rune basta, e quando um store não basta
version: 1
---

**Para o estado de que uma aplicação é dona, uma classe ou um objeto com runes é hoje a ferramenta
melhor, e é o que a própria documentação do Svelte recomenda.** É JavaScript comum com algumas runes
dentro, pode ser criado a cada uso em vez de compartilhado por import, funciona tanto em arquivos
`.svelte.js` quanto em componentes, e dispensa `$`, `subscribe` e `get`. O estado do planner é desse
tipo, e foi para uma classe.

Os stores ainda têm o seu lugar em três situações, e o timer era uma delas:

| use… | quando | porque |
|---|---|---|
| runes, numa classe ou num módulo `.svelte.js` | estado de que a aplicação é dona: as sessões do planner, os campos de um formulário, uma seleção | se lê como código comum, e o Svelte o rastreia sem inscrição |
| `readable` | um valor que chega de fora ao longo do tempo, e só deve ser escutado enquanto alguém olha | as funções de início e de fim são exatamente esse ciclo de vida |
| o contrato de store | uma biblioteca que já o oferece, como um observable do RxJS | qualquer coisa com `subscribe` funciona com `$`, sem adaptador |
| `derived` | um valor calculado a partir de outros stores | mantém o cálculo no mundo dos stores |

## Passar de um para o outro

Os dois mundos se encontram em `svelte/store`. **`fromStore(store)`** devolve um objeto cujo `current`
é o valor do store, tão reativo quanto um campo `$state`, para usar um store a partir de um módulo
`.svelte.js`, onde o `$` não existe. **`toStore(get, set)`** embrulha runes num store, para entregar o
seu estado a um código que espera um. Nenhum dos dois é preciso com frequência; os dois existem para
que a escolha nunca seja um muro.

## A armadilha da instância única

Há um jeito de um módulo `.svelte.js` ser pior que uma classe, e é o mesmo jeito de um módulo de
stores ser. Um módulo que **exporta uma instância**, `export const planner = new Planner(…)`, dá a cada
componente que o importa o mesmo objeto, o que parece cômodo e funciona no navegador, onde há um
visitante. No servidor há um módulo para **todos** os visitantes, e uma instância criada no nível do
módulo é compartilhada entre todas as requisições deles. O `startedAt` do timer é um valor assim:
inofensivo numa demonstração, perigoso para qualquer coisa que pertença a uma pessoa.

É por isso que o `Planner.svelte` cria o seu próprio `Planner`, e não importa um. A próxima aula
mostra o perigo acontecendo, e a ferramenta que compartilha uma instância com os componentes que
precisam dela sem torná-la global: o contexto.

Apague o timer antes de seguir, `rm -r src/routes/timer src/lib/timer.js`: era um experimento, e o
planner não tem uso para ele.
