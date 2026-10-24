---
title: Documentação que não tem como ficar para trás
version: 1
---

**A documentação mais útil de um componente é a gerada a partir do componente e das stories dele, porque é
a única que muda quando eles mudam.** Uma página de wiki descrevendo a linha de sessão está certa no dia
em que é escrita e errada na primeira vez que alguém acrescenta um argumento e esquece a wiki.

`tags: ["autodocs"]` no `preview.ts` dá a todo componente uma página **Docs**, construída a partir de três
coisas que já existem:

- **as stories**, cada uma desenhada ao vivo na página, uma embaixo da outra, então a página mostra todo
  estado que as stories cobrem;
- **os argumentos**, como uma tabela com tipos e padrões, e os mesmos controles do canvas;
- **os comentários**: o comentário JSDoc acima de `sessionRow` no `components.ts` vira a descrição do
  componente, e um comentário JSDoc acima do export de uma story vira a descrição dela.

Nada disso é escrito duas vezes. Um argumento novo aparece na tabela da próxima vez que o Storybook lê o
arquivo; uma story nova aparece na página.

## Texto que não é gerado

Parte da documentação não é sobre um componente: quando usar uma linha e quando um cartão, como a escala
de espaçamento deve ser usada, como os tokens se chamam. O Storybook aceita isso como arquivos **MDX**,
Markdown que pode embutir stories e blocos do próprio Storybook, e os lista na barra lateral ao lado dos
componentes. A página inicial de um design system, a referência dos tokens e o guia de contribuição em
geral são páginas MDX.

A regra da aula anterior vale aqui também: **texto que repete um valor fica velho.** Uma página MDX que diz
"o destaque é verde" está errada no dia em que a marca muda; uma que embute a cor a partir dos tokens não
está. Escreva os motivos em texto e deixe os valores virem do código.

## Quem lê

O público é maior que o de desenvolvedores. Uma designer confere que o componente bate com o design em todo
estado; um gerente de produto vê o que existe antes de pedir algo novo; quem testa acha os estados para
experimentar. É por isso que a próxima seção o publica: **uma oficina só no seu computador é uma oficina
para uma pessoa**.
