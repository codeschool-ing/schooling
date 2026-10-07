---
title: Espaços de cor perceptuais
version: 1
---

Um espaço de cor **perceptualmente uniforme** é feito para que distâncias iguais nele pareçam
diferenças iguais para o olho. Dois viraram padrão.

- **CIELAB**, publicado em 1976 pela Comissão Internacional de Iluminação, descreve uma cor pela
  luminosidade, **L**, e dois eixos opostos, do verde ao vermelho (**a**) e do azul ao amarelo (**b**).
  Ele é a referência da ciência da cor há décadas e não é perfeitamente uniforme, sobretudo nos azuis.
- **OKLab**, publicado por Björn Ottosson em 2020, mantém a mesma ideia com uniformidade melhor e
  aritmética simples. A forma polar dele, **OKLCH**, dá luminosidade, croma e matiz: as três dimensões
  da primeira seção, medidas de um jeito com que o olho concorda. O CSS aceita direto como `oklch()`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 290\" role=\"img\" data-fig=\"l11-ramps\" aria-label=\"Duas rampas de amarelo de sete passos do claro ao escuro, com a luminosidade percebida de cada passo desenhada embaixo como uma linha. A primeira rampa dá passos iguais de luminosidade HSL, e a linha dela se curva: os quatro primeiros passos são quase o mesmo amarelo claro e os três últimos caem forte. A segunda dá passos iguais em OKLCH, um espaço feito para combinar com a percepção, e a linha dela cai reta.\"><text x=\"40.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">passos iguais em HSL</text><rect x=\"40.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#fbfbda\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"76.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#f4f49d\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"112.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#eded60\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"148.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#e7e723\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"184.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#b1b114\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"220.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#74740d\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"256.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#373706\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M40.0 250.0 L288.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M40.0 110.0 L40.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M57.7 113.6 L93.1 119.1 L128.6 124.0 L164.0 127.7 L199.4 156.1 L234.9 190.2 L270.3 227.9\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"57.7\" cy=\"113.6\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"93.1\" cy=\"119.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"128.6\" cy=\"124.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"164.0\" cy=\"127.7\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"199.4\" cy=\"156.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"234.9\" cy=\"190.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"270.3\" cy=\"227.9\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"340.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">passos iguais em OKLCH</text><rect x=\"340.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#fdf7d0\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"376.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#dcd5a6\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"412.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#bdb47d\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"448.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#9e9454\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"484.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#817428\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"520.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#655600\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"556.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#4a3900\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M340.0 250.0 L588.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M340.0 110.0 L340.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M357.7 115.1 L393.1 133.3 L428.6 151.3 L464.0 169.4 L499.4 187.7 L534.9 205.5 L570.3 223.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"357.7\" cy=\"115.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"393.1\" cy=\"133.3\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"428.6\" cy=\"151.3\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"464.0\" cy=\"169.4\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"499.4\" cy=\"187.7\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"534.9\" cy=\"205.5\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"570.3\" cy=\"223.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"40.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">luminosidade percebida (L do OKLab)</text></svg>", "caption": "Passos iguais num espaço perceptual parecem iguais; passos iguais em HSL não. Uma paleta sequencial só é honesta se um passo de classe for o mesmo passo visual em todo lugar."}
```

As duas rampas vão do amarelo claro a um oliva escuro em sete passos. Embaixo de cada uma, a linha
mostra o quanto cada passo parece claro, medido como a luminosidade do OKLab. A rampa da esquerda dá
**passos iguais de luminosidade HSL**, e a linha dela se curva: os quatro primeiros passos são quase o
mesmo amarelo claro, e os três últimos caem forte. Um mapa de calor pintado com ela esconderia toda
diferença entre os valores mais baixos e exageraria as do alto. A rampa da direita dá **passos iguais
de luminosidade OKLCH**, e a linha dela é reta.

Nem todo matiz sofre tanto. Uma rampa de azul em HSL sai quase uniforme, que é como uma paleta pode
parecer boa numa cor e falhar na seguinte.

## O que isso quer dizer na prática

Você não precisa calcular cores em OKLCH à mão. O que você precisa é saber que:

- **as boas paletas já são feitas assim.** O `viridis`, o `cividis` e os parentes deles no matplotlib,
  as paletas do ColorBrewer e os padrões da maioria das ferramentas modernas foram desenhados em
  espaços perceptuais e testados para passos iguais. A aula 12 é sobre escolher entre elas.
- **uma paleta que você mesmo faz deve ser conferida**, convertendo-a para cinza ou para a
  luminosidade do OKLab, como a próxima seção faz, antes de carregar dado.
- **o HSL serve para escolher um matiz**, e não para decidir quão claras as cores são.
