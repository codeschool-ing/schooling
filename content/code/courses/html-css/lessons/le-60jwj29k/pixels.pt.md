---
title: Pixels: o pixel CSS e o pixel do dispositivo
version: 1
---

`px` é a unidade com que todo mundo começa, e ela esconde uma surpresa: **um pixel CSS não é um pixel da sua tela**. É uma unidade de comprimento que o navegador mapeia nos pixels reais da tela, os **pixels do dispositivo**, usando a **densidade de pixels do dispositivo** que a aula 4 usou para escolher uma imagem.

O mesmo cartão, medido numa tela de densidade 1 e numa de densidade 3:

```
ana@laptop:~/site$ probe --dpr 1 sizes.html window box .card
window: 1024×768, device pixel ratio 1
article.card  x 0      y 0      width 400    height 50
ana@laptop:~/site$ probe --dpr 3 sizes.html window box .card
window: 1024×768, device pixel ratio 3
article.card  x 0      y 0      width 400    height 50
```

A janela tem 1024 pixels CSS de largura nas duas, e o cartão tem **400 pixels CSS de largura nas duas**. Na segunda tela, cada pixel CSS é desenhado com 3 pixels do dispositivo na horizontal, então o cartão ocupa 1200 deles e parece exatamente do mesmo tamanho para o leitor, só que mais nítido. Esse é o sentido da unidade: uma fonte de 16 pixels tem mais ou menos o mesmo tamanho físico num notebook e num celular segurado à distância de leitura, seja qual for o hardware.

O padrão define o pixel de referência como o tamanho de um pixel numa tela de 96 pontos por polegada vista à distância de um braço, e é por isso que as unidades absolutas se relacionam com ele por proporções fixas: `1in` é `96px`, `1cm` é cerca de `37.8px`, `1pt` é `1.333px`. Essas unidades são para folhas de estilo de impressão; na tela, `px` é a unidade absoluta a usar.

## Quando os pixels estão errados

**Pixels estão certos para coisas que não devem crescer com o texto**: uma borda de 1 pixel, uma sombra de 4 pixels, a espessura de uma linha. Estão **errados para tamanhos de fonte e para o espaço em volta do texto**, porque um leitor pode pedir ao navegador um texto maior, e um tamanho fixo em pixels é um tamanho que recusa. A próxima seção é a unidade que não recusa.
