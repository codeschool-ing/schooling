---
title: Cinco números e uma regra
version: 1
---

Um **boxplot**, ou diagrama de caixa, foi criado pelo estatístico John Tukey nos anos 1970 para
resumir uma distribuição num espaço pequeno o bastante para pôr vários lado a lado. Ele desenha cinco
números e aplica uma regra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 230\" role=\"img\" data-fig=\"l09-anatomy\" aria-label=\"Um boxplot horizontal dos 400 tempos de entrega, com cada parte nomeada. A caixa vai do primeiro quartil, 27,0 minutos, ao terceiro, 39,8, com a mediana em 33,1 dentro dela. Os bigodes vão de 12,2 à esquerda até 57,3 à direita, a última entrega a menos de uma caixa e meia da caixa. 16 entregas mais lentas são desenhadas como círculos separados, até 101,3.\"><path d=\"M96.2 105.0 L176.6 105.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M246.2 105.0 L341.1 105.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M96.2 95.0 L96.2 115.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M341.1 95.0 L341.1 115.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M176.6 85.0 h69.6 v40.0 h-69.6 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill-opacity=\"0.6\"></path><path d=\"M209.4 85.0 L209.4 125.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><circle cx=\"361.1\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"369.3\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"371.5\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"374.2\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"376.9\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"377.4\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"382.3\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"383.4\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"398.1\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"399.7\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"406.2\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"414.9\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"435.0\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"519.7\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"539.2\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"579.9\" cy=\"105.0\" r=\"2.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><path d=\"M30.0 170.0 L600.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M30.0 170.0 L30.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"30.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M111.4 170.0 L111.4 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"111.4\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M192.9 170.0 L192.9 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"192.9\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M274.3 170.0 L274.3 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"274.3\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">45</text><path d=\"M355.7 170.0 L355.7 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"355.7\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M437.1 170.0 L437.1 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"437.1\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">75</text><path d=\"M518.6 170.0 L518.6 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"518.6\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">90</text><path d=\"M600.0 170.0 L600.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"600.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">105</text><text x=\"315.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tempo de entrega (minutos)</text><text x=\"176.6\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Q1</text><text x=\"246.2\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Q3</text><text x=\"209.4\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">mediana</text><text x=\"211.4\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a metade do meio</text><text x=\"136.4\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bigode</text><text x=\"293.6\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bigode</text><text x=\"464.3\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">além da cerca</text></svg>", "caption": "Cinco números e uma regra. A caixa guarda a metade do meio das entregas, a linha dentro dela é a mediana, e o que passa de uma caixa e meia para fora é desenhado sozinho."}
```

Os cinco números, para as 400 entregas da Horta:

| | valor | significado |
|---|---|---|
| **primeiro quartil, Q1** | 27,0 min | um quarto das entregas levou menos |
| **mediana** | 33,1 min | metade levou menos, metade levou mais |
| **terceiro quartil, Q3** | 39,8 min | três quartos levaram menos |
| **menor** | 12,2 min | a entrega mais rápida |
| **maior** | 101,3 min | a mais lenta |

A **caixa** vai de Q1 a Q3, então guarda **a metade do meio dos dados**, e o comprimento dela, 12,8
minutos, é o **intervalo interquartil** da aula 5. A linha dentro da caixa é a mediana.

## A regra dos bigodes

Os bigodes não vão simplesmente até o menor e o maior valor. Eles param no último valor a menos de
**uma caixa e meia** da caixa, um limite chamado de **cerca**:

```localised
cerca de cima = Q3 + 1,5 × (Q3 − Q1) = 39,82 + 1,5 × 12,82 = 59,05 minutos
```

A entrega mais lenta dentro da cerca levou 57,3 minutos, então é ali que termina o bigode de cima.
**As 16 entregas além dela são desenhadas como pontos separados**, cada uma visível como ela mesma. À
esquerda a cerca fica abaixo de zero, então o bigode vai até a entrega mais rápida, 12,2.

## O que a forma de uma caixa diz

- **Onde a mediana fica na caixa.** Aqui ela está um pouco à esquerda do centro, e o bigode direito é
  mais longo que o esquerdo: o dado é **assimétrico à direita**, como o histograma mostrou na aula 5.
- **O comprimento da caixa.** Uma caixa curta quer dizer que a metade do meio está bem agrupada; uma
  longa quer dizer que os valores típicos variam muito.
- **Quantos pontos ficam além das cercas.** Pontos lá fora não são erros por definição; são as
  entregas que valem ser olhadas uma a uma. Dezesseis de 400 é uma cauda longa, não um punhado de
  erros.

O 1,5 é uma convenção de Tukey, não uma lei. Alguns programas deixam mudá-lo, e alguns desenham os
bigodes até os extremos. **Confira o que o seu faz** antes de dizer a alguém que um ponto é um valor
atípico.
