---
title: Um quadro que mostra onde o trabalho está esperando
version: 1
---

**O Kanban é um jeito de gerenciar trabalho tornando-o visível, limitando quanto dele está em andamento e
melhorando como ele flui.** Não tem sprints, nem papéis, nem eventos próprios. Um time parte do que faz hoje,
desenha isso num quadro e muda um pouco de cada vez.

A palavra é japonesa e quer dizer placa ou cartão. Na Toyota dos anos 1950, Taiichi Ohno usava cartões para
controlar a produção: uma estação só fazia mais peças quando chegava um cartão pedindo, então nenhuma estação
podia empilhar trabalho que a seguinte não estava pronta para receber. No software, David J. Anderson adaptou a
ideia em meados dos anos 2000, primeiro com um time de manutenção na Microsoft, e descreveu o método no livro
*Kanban*, de 2010.

## Por que o Cine Aurora tem um quadro além das sprints

O trabalho dos preços corre em sprints. Outro tipo de trabalho não cabe nelas: os pedidos da Célia na
bilheteria e os defeitos achados em produção. Chegam em qualquer dia, a maioria é pequena, e alguns não podem
esperar duas semanas. O Rafael e a Lia cuidam desse fluxo num quadro Kanban, e o resto desta aula o acompanha.

## O quadro

Cada cartão é uma peça de trabalho. Cada coluna é uma etapa por que ele passa. O quadro do Cine Aurora começou
assim:

| a fazer | construindo | esperando teste | testando | pronto |
|---|---|---|---|---|
| recibo mostra o assento | botão de reembolso | lista de sessões ordenada | matinê nos feriados | |
| meia infantil na placa | | faixa da quarta | | |
| | | total do relatório em negrito | | |

Três coisas no quadro merecem atenção, e a segunda é a que mais importa a quem testa.

- **Testar é uma coluna.** Não fica escondido dentro de "em andamento", então um cartão construído e não
  testado parece diferente de um cartão terminado.
- **"Esperando teste" também é uma coluna.** Um cartão parado ali não está sendo trabalhado por ninguém.
  Desenhar a espera a torna visível, e o quadro acima já mostra uma fila de três.
- **O quadro mostra onde o trabalho espera, não quem está ocupado.** Todo mundo no Cine Aurora estava ocupado.
  Foi o quadro que mostrou que um cartão passava a maior parte da vida esperando alguém.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 230\" role=\"img\" data-fig=\"l13-board\" aria-label=\"Um quadro Kanban com cinco colunas: a fazer, construindo, esperando teste, testando e pronto. A fazer tem dois cartões, construindo um, esperando teste três, testando um, pronto nenhum. A coluna esperando teste está destacada, com uma nota: ninguém está trabalhando nestes.\"><rect x=\"10.0\" y=\"10.0\" width=\"126.0\" height=\"190.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"73.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">a fazer</text><rect x=\"18.0\" y=\"44.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"73.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">recibo mostra o assento</text><rect x=\"18.0\" y=\"86.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"73.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">meia infantil na placa</text><rect x=\"144.0\" y=\"10.0\" width=\"126.0\" height=\"190.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"207.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">construindo</text><rect x=\"152.0\" y=\"44.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"207.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">botão de reembolso</text><rect x=\"278.0\" y=\"10.0\" width=\"126.0\" height=\"190.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"341.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">esperando teste</text><rect x=\"286.0\" y=\"44.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"341.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">lista de sessões ordenada</text><rect x=\"286.0\" y=\"86.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"341.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">faixa da quarta</text><rect x=\"286.0\" y=\"128.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"341.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">total do relatório em negrito</text><rect x=\"412.0\" y=\"10.0\" width=\"126.0\" height=\"190.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">testando</text><rect x=\"420.0\" y=\"44.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">matinê nos feriados</text><rect x=\"546.0\" y=\"10.0\" width=\"126.0\" height=\"190.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"609.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">pronto</text><text x=\"341.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">ninguém está trabalhando nestes</text></svg>", "caption": "O primeiro quadro do Cine Aurora. Desenhar a espera como coluna própria foi o que mostrou a fila."}
```

## Um quadro ainda não é um método

Um time que desenha colunas e para por aí tem uma lista de tarefas na parede. O que o torna Kanban é o que as
próximas seções acrescentam: um limite de quantos cartões cada coluna pode ter, medidas de quanto tempo os
cartões levam, e políticas escritas no quadro dizendo do que um cartão precisa antes de andar. Anderson as lista
como as práticas centrais: **visualizar o trabalho, limitar o trabalho em andamento, gerenciar o fluxo, tornar
as políticas explícitas, criar ciclos de feedback e melhorar em colaboração**. Visualizar é a primeira e a mais
fácil, e sozinha muda muito pouco.
