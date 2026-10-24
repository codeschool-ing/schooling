---
title: O problema que o contexto resolve
version: 1
---

**Props viajam um nível de cada vez.** Um valor de que um componente três níveis abaixo precisa tem
de ser passado por cada componente no caminho, inclusive pelos que nunca o usam e só o repassam. Isso
se chama **prop drilling**, e não está errado; é honesto sobre por onde os dados passam. Vira problema
quando os componentes do meio ganham props com as quais não se importam, e cada necessidade nova lá
embaixo na árvore significa editar cada arquivo acima dela.

O planner está prestes a encontrá-lo. O `Planner.svelte` cresceu de novo desde a aula 10: a frase sobre
quanto já foi feito e a lista de minutos por dia são dois pedaços com nome próprio, e os dois deveriam
ser componentes. Os dois precisam do planner: a frase lê `total` e `doneMinutes`, a lista lê `week` e
`byDay`. Como props, são quatro valores descendo do `Planner.svelte`, e no dia em que a lista quiser
mostrar qual dia tem mais minutos, um quinto.

## O que seria passado, e o que já está lá

Olhe o que os dois componentes precisam, e nunca é um valor só: é **o planner**. Cada um lê alguns
campos dele, e os campos que leem vão mudar conforme eles mudarem. Passar a instância inteira como
prop, `<Days {planner} />`, é melhor que passar quatro campos, e é assim que muitos códigos fazem.

O **contexto** é o outro jeito: um componente torna um valor disponível para todo componente dentro
dele, em qualquer profundidade, sem passar por cada um. É a ferramenta certa quando três coisas são
verdade ao mesmo tempo:

- muitos componentes dentro de uma parte da página precisam da mesma coisa;
- essa coisa pertence àquela parte da página, não à aplicação inteira;
- passá-la pelos componentes do meio seria só ruído.

O planner é exatamente isso: tudo dentro do `Planner.svelte` trabalha com um `Planner`, o que aquele
componente criou, e nada fora dele precisa desse planner. A próxima seção o põe no contexto.

## O que o contexto não é

Não é uma variável global. Cada componente que define um contexto o fornece aos **seus próprios**
descendentes, então dois planners lado a lado numa página dariam cada um a sua própria instância aos
filhos. Também não é reativo por si só: ele entrega o valor que foi definido, uma vez, e é a
reatividade do próprio valor que faz os filhos se atualizarem. E ele só é definido enquanto um
componente está sendo criado, o que a seção depois da próxima mostra falhando quando essa regra é
quebrada.
