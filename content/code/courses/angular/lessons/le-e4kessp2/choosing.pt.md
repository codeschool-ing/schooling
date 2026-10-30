---
title: Escolher, e o que vai com você
version: 1
---

**Um framework é escolhido para uma equipe e uma aplicação, não para um cartão, e as diferenças do
cartão são as pequenas.** O que pesa numa escolha de verdade:

| o Angular combina quando | outro combina quando |
| --- | --- |
| a aplicação é grande, de vida longa, e muita gente vai trabalhar nela | uma equipe pequena quer escolher cada peça sozinha |
| uma estrutura em todo lugar importa mais que liberdade: serviços, DI, os geradores do CLI | a página é sobretudo conteúdo, lida uma vez, em que cada kilobyte conta |
| a equipe quer um caminho de atualização só, o `ng update`, para a pilha inteira | a equipe já conhece React, Vue ou Svelte, e as bibliotecas deles |
| formulários, rotas e HTTP devem ser iguais em todo projeto da empresa | a ferramenta full-stack do próprio framework, Next, Nuxt ou SvelteKit, é o produto |

O hábito do Angular de decidir as coisas é o motivo de ele ser comum em empresas com muitas equipes e
aplicações que vivem por anos: quem passa de um projeto Angular a outro acha as mesmas pastas, os
mesmos serviços, o mesmo roteador e os mesmos formulários. O hábito do React de não decidir é o
motivo de ele estar em todo o resto: cada projeto monta o que precisa, e não há dois que montem igual.
Nenhum dos dois é um erro. Saber qual escolha uma equipe fez, e por quê, é a parte útil.

## O que vai com você

A maior parte do que este curso ensinou não é do Angular:

- **Componentes com entradas e saídas, e dados que correm num sentido.** Todo framework aqui funciona
  assim, e o `input()` e o `output()` da aula 8 são `props` e um evento nos outros.
- **Estado que é lido, e valores derivados dele, nunca guardados duas vezes.** Signals, refs, runes,
  ou um `const` numa função do React; o padrão de store da aula 22 é o mesmo padrão nos quatro.
- **TypeScript, e um template que o compilador confere.** Os quatro conferem templates hoje, o Angular
  com mais rigor.
- **Para que o servidor serve, e para que não serve.** A API, os erros que ela manda, uma falha
  desfeita e dita em voz alta: as aulas 12 e 13 valem em qualquer um deles.
- **Renderizar no servidor, e o navegador assumindo.** A hidratação é a mesma ideia no Next, no Nuxt e
  no SvelteKit.
- **Acessibilidade, testada no que a página diz.** Um rótulo, um foco movido e devolvido, uma região
  ao vivo: isso é do HTML, e o diálogo da aula 21 funciona igual em qualquer lugar.
- **Testes no nível mais barato que consegue ver a regra.** O Vitest é o runner dos quatro.

O que fica é do Angular: a injeção de dependência como sistema, os decorators, o `@for` e os outros
blocos, o RxJS onde uma aplicação o usa, e o CLI. Quem fizer um dos outros cursos depois deste começa
da segunda lista, não do começo.
