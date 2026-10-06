---
title: Vendo o grid: DevTools
version: 1
---

Um grid é invisível. As trilhas, as linhas e os vãos não são desenhados, então um layout que dá errado costuma parecer "os itens estão no lugar errado" sem nenhuma pista do porquê. **O DevTools desenha o grid para você**, e este é o hábito que mais economiza tempo:

1. **No painel Elements, encontre o contêiner grid.** Todo elemento com `display: grid` tem um pequeno selo **grid** ao lado dele na árvore. Clique nele, e o grid é desenhado sobre a página: as trilhas contornadas, os vãos hachurados.
2. **Abra o painel Layout**, ao lado de Styles e Computed. Ele lista todo grid da página com uma caixa para mostrar a sobreposição, e opções para mostrar **números de linha**, **tamanhos de trilha** e **nomes de área** na sobreposição.
3. **Ligue os números de linha.** Eles são desenhados nas duas pontas de cada linha, positivos e negativos, que é exatamente o que você precisa para ler ou escrever `grid-column: 2 / -1`.
4. **Ligue os tamanhos de trilha**, e cada trilha ganha o rótulo do tamanho que você escreveu e do tamanho em que ela deu: `1fr` e `189.33px`, o mesmo par que esta aula calculou para `tracks.html`.
5. **Ligue os nomes de área**, e as áreas com nome aparecem rotuladas onde estão, que é o template desenhado de volta sobre a página.

O painel Computed mostra `grid-template-columns` resolvido em pixels, como o `probe style` fez para `autofit.html`: foi assim que esta aula viu a trilha colapsada de `0px` do `auto-fit`. O inspetor de grid do Firefox, que veio primeiro, faz o mesmo e desenha um pouco mais.

## Três coisas a conferir quando um grid se comporta mal

**Os itens não são itens grid.** `display: grid` só vale para os filhos diretos; uma `<div>` envolvente entre o grid e os cartões faz da `<div>` o único item grid.

**Um nome de área está escrito errado, ou uma área não é um retângulo.** Aí o valor inteiro de `grid-template-areas` é inválido e ignorado, e o DevTools o risca no painel Styles, que é de novo o sinal de aviso da aula 5.

**O conteúdo força uma trilha a ficar mais larga que o pretendido.** Uma trilha `1fr` tem mínimo `auto`, o que quer dizer que não encolhe abaixo do conteúdo: o mesmo piso da seção 08 da aula 8. `minmax(0, 1fr)` o tira.
