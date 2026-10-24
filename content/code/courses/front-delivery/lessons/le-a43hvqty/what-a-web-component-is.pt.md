---
title: O que é um Web Component
version: 1
---

**Um Web Component é um elemento que você define, usado numa página como qualquer elemento nativo, e feito
de três padrões do navegador que não precisam de biblioteca nenhuma.** Cada padrão é útil sozinho; juntos,
dão a um design system algo que os componentes em forma de função não dão: um componente que todo
framework consegue usar, porque é só um elemento.

| padrão | o que dá | o uso no planner |
|---|---|---|
| **custom elements** | uma tag sua, `<planner-session>`, com uma classe que roda quando uma aparece | uma linha de sessão que qualquer página escreve em HTML |
| **shadow DOM** | uma árvore privada de elementos dentro da sua tag, com estilos que não entram nem saem | um botão que o CSS da página não consegue repintar |
| **templates e slots** | marcação inerte para clonar, e buracos onde entra o conteúdo da própria página | a estrutura da linha, com o nome do curso passado de fora |

A imagem comum é a de que Web Components são um framework rival, para escolher no lugar de React ou Vue.
Eles ficam num nível abaixo: **um framework renderiza elementos, e um Web Component é um elemento**.
React, Angular, Vue e Svelte renderizam `<planner-session>` do jeito que renderizam `<button>`, e é por isso
que a última seção desta aula consegue mostrar a mesma tag em cada um deles.

## Por que um design system recorre a eles

A biblioteca da aula 7 exporta funções que devolvem DOM. Um app em TypeScript puro as chama sem
problema. Um app em Vue precisaria de um componente envolvendo cada uma, um app em React também, e cada
um desses invólucros é código a manter em dia com a biblioteca. Uma empresa com apps em três frameworks
ou escreve três invólucros por componente, ou escreve o componente uma vez, como elemento.

O custo é real, e a aula o mostra pelo caminho: atributos são strings, a fronteira do shadow complica
formulários e rótulos, e renderizar shadow DOM no servidor pede cuidado extra. Muitos design systems usam
Web Components nos componentes das pontas, botões, selos e linhas, e componentes do framework nos layouts
em volta deles.

## O que a aula constrói

`<planner-session>`, na biblioteca, ao lado dos componentes em forma de função, com uma página de
demonstração que o Vite serve e testes do Playwright que a dirigem. **Nenhuma biblioteca é usada para
escrevê-lo**, então cada linha é uma API do navegador. O **Lit**, uma biblioteca pequena da equipe de
plataforma web do Google, é o que muitas equipes usam para escrever a mesma coisa com menos código, e ele
produz exatamente o tipo de elemento que esta aula escreve à mão.
