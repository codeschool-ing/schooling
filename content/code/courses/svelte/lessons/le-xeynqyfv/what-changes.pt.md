---
title: O que isso muda no jeito de pensar
version: 1
---

**Sem DOM virtual, um componente é preparado uma vez e depois deixado em paz, e o código que você
escreve é o código que roda.** Quase tudo o que parece diferente no Svelte, para quem vem do React ou
de tutoriais escritos para ele, vem desse único fato. Esta seção junta as consequências num lugar só,
para que cada aula depois possa apontar para cá.

## O que você deixa de fazer

| no React você… | no Svelte… | porque |
|---|---|---|
| embrulharia uma função em `useCallback` para um filho não re-renderizar | escreve a função | o script roda uma vez, então a função é o mesmo objeto pela vida do componente |
| embrulharia um cálculo em `useMemo` | escreve `$derived(…)`, aula 3 | um valor derivado recalcula quando algo que ele leu muda, e não em outra hora |
| manteria os hooks no topo, nunca dentro de um `if` | usa runes onde fazem sentido | uma rune é uma instrução do compilador, não uma chamada que o React conta em ordem |
| copiaria um array para mudá-lo: `[...list, item]` | `list.push(item)` | arrays e objetos `$state` são profundos, aula 3; mudá-los no lugar é rastreado |
| buscaria uma biblioteca de estado para qualquer coisa compartilhada | um módulo `.svelte.js` ou contexto, aulas 10 e 11 | signals funcionam fora de componentes também |

Nada da coluna da esquerda está errado no React. Cada item é o preço de a função do componente rodar
a cada mudança, e o Svelte não cobra esse preço.

## O que você ainda precisa fazer

**Chaves em listas continuam importando.** Quando uma lista é reordenada, o Svelte precisa decidir
qual elemento existente vira qual, e sem chave ele os casa por posição. A aula 8 mostra a linha
errada ficando com um input meio digitado por causa disso.

**Efeitos continuam pedindo cuidado.** Um efeito que define um valor que ele mesmo lê pode rodar a si
mesmo em loop, e o Svelte o para com um erro em vez de deixá-lo girar. A regra da aula 3 para efeitos
é a prática: quase tudo o que parece um efeito é, na verdade, um valor derivado ou um handler de
evento.

**A reatividade mora na variável, então tirar o valor de lá a quebra.** `let { minutes } = counter`
copia o número uma vez, exatamente como o `hours` que ficou em zero em "O script roda uma vez". A aula
3 mostra as formas que mantêm a ligação: ler `counter.minutes` onde for preciso, ou `$derived`.

## O que você ganha, e do que abre mão

Você ganha componentes pequenos e um runtime pequeno, porque o compilador descobriu antes o que cada
mudança afeta. Ganha código que parece JavaScript comum, `minutes += 30`, mesmo o compilador o tendo
reescrito.

Você abre mão de conseguir ler um componente como JavaScript comum. Um arquivo `.svelte` só significa
o que significa depois que o compilador o leu, então um editor, um linter ou um executor de testes
precisa conhecer o Svelte para ajudar, e todos os que este curso usa conhecem. E você abre mão do
maior ecossistema: o React tem mais componentes, mais exemplos e mais vagas, o que a aula 20 pesa com
honestidade contra tudo o que está acima.
