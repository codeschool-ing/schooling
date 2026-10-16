---
title: Lendo as formas
version: 1
---

Ninguém lê um CFD medindo-o toda manhã. As pessoas leem a **forma** dele, e um punhado de formas se repete no gráfico de todo time. Cada uma aponta para um problema específico, e cada uma fica visível dias ou semanas antes de os tempos de ciclo dos itens terminados mudarem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 220\" role=\"img\" data-fig=\"l03-patterns\" aria-label=\"Três pequenos diagramas de fluxo cumulativo desenhados como esboço. No primeiro, a faixa entre duas linhas alarga porque a de cima sobe mais rápido que a de baixo: um gargalo. No segundo, a linha de baixo fica plana enquanto as outras continuam subindo: nada está terminando. No terceiro, a linha de baixo sobe em degraus: o trabalho cruza essa fronteira em lotes.\"><rect x=\"20.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma faixa que alarga</text><text x=\"120.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">uma fila está crescendo</text><path d=\"M34.0 136.0 L120.0 96.0 L206.0 56.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M34.0 146.0 L120.0 126.0 L206.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"246.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"346.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma linha que fica plana</text><text x=\"346.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nada está terminando</text><path d=\"M260.0 136.0 L346.0 96.0 L432.0 58.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M260.0 146.0 L346.0 110.0 L363.2 104.0 L432.0 104.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"472.0\" y=\"30.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"572.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">degraus em vez de rampa</text><text x=\"572.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o trabalho anda em lotes</text><path d=\"M486.0 136.0 L572.0 96.0 L658.0 58.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M486.0 148.0 L524.7 148.0 L524.7 124.0 L580.6 124.0 L580.6 98.0 L636.5 98.0 L636.5 74.0 L658.0 74.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path></svg>", "caption": "Três formas que vale reconhecer de relance. Cada uma aparece dias antes de os tempos de ciclo dos itens terminados mudarem."}
```

## Uma faixa que alarga

Quando uma faixa engrossa enquanto as outras ficam iguais, **o trabalho está entrando naquele estado mais rápido do que sai**. Aquele estado é o gargalo, ou a fila diante dele.

O gráfico do time de Billing tem exatamente isso ao longo de julho. Leia na tabela: em 3 de julho, 31 itens tinham chegado à revisão e 22 tinham sido integrados, então **9** estavam esperando revisão ou sendo revisados; em 24 de julho eram 57 − 43 = **14**. A fila da Bia crescia semana a semana, e nada no gráfico de dispersão dos itens terminados dizia isso ainda, porque os itens presos nela não tinham terminado.

## Uma linha que fica plana

Num CFD a linha mais baixa é a última coluna, então uma linha de baixo plana quer dizer que **nada está terminando**, e uma linha de cima plana quer dizer que nada está chegando. Uma linha plana no meio quer dizer que nada está cruzando aquela fronteira. A linha *started* do time de Billing fica plana de 31 de julho a 7 de agosto, em 78: por uma semana depois das novas regras, ninguém começou nada. Isso não é um problema; é o limite fazendo o seu trabalho, enquanto cada dev terminava os três itens que já tinha antes de pegar um quarto. Leia uma linha plana como uma pergunta, não como um veredito.

## Degraus em vez de uma rampa

Uma linha que sobe em degraus quer dizer que **o trabalho cruza aquela fronteira em lotes**. Em junho e julho a linha *deployed* fica atrás da linha *merged* e a alcança uma vez por semana, porque o pipeline rodava às quintas. A partir de agosto as duas linhas ficam uma em cima da outra. Num gráfico desenhado dia a dia os degraus são inconfundíveis; na tabela das sextas-feiras eles aparecem como a diferença entre *merged* e *deployed*, que era de 3 itens em 24 de julho e de nenhum depois da primeira semana de agosto.

## Uma faixa de cima que não para de crescer

A faixa entre *arrived* e *started* é o backlog. No gráfico do time de Billing ela foi de 20 itens em 5 de junho para 21 em 31 de julho, e estava em 17 em 25 de setembro: quase estável, com os pedidos chegando mais ou menos na velocidade em que o time os começava. **Uma faixa de backlog que só cresce é uma promessa que o time não está cumprindo**, e é a forma por trás da descoberta da aula 2 de que a espera de quem fez o pedido era quase toda backlog.

## O que as formas não dizem

Um CFD descreve o quadro como um todo. Ele não consegue dizer **qual** item está preso, só que os itens estão se acumulando em algum lugar; e um item que fica parado enquanto os outros passam por ele quase não muda faixa nenhuma. Um item bloqueado entre cem é uma linha da espessura de um item. O gráfico para isso é o assunto da próxima seção.
