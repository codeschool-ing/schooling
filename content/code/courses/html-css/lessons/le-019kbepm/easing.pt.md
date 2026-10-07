---
title: Easing: como o tempo é gasto
version: 2
---

A **função de tempo** (*timing function*) decide como o progresso de uma transição se distribui pela duração. Quatro pontos andam 200 pixels em 400 ms quando a trilha recebe o hover, cada um com uma função de tempo diferente, no `transition.html`, que também tem o botão da seção 05:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 16px; font-family: system-ui, sans-serif; }
      .button {
        padding: 8px 16px;
        border: 0;
        color: white;
        background-color: #2f6f4e;
        transition: background-color 200ms ease-out;
      }
      .button:hover { background-color: #1e4a33; }

      .track { height: 160px; }
      .dot { width: 24px; height: 24px; margin-bottom: 16px; background: #8a1c1c; }
      .linear   { transition: translate 400ms linear; }
      .ease     { transition: translate 400ms ease; }
      .ease-in  { transition: translate 400ms ease-in; }
      .ease-out { transition: translate 400ms ease-out; }
      .track:hover .dot { translate: 200px; }
    </style>
  </head>
  <body>
    <button class="button" type="button">Reserve a place</button>
    <div class="track">
      <div class="dot linear"></div>
      <div class="dot ease"></div>
      <div class="dot ease-in"></div>
      <div class="dot ease-out"></div>
    </div>
  </body>
</html>
```

Aqui estão eles em 100 ms e em 200 ms:

```
ana@laptop:~/site$ probe transition.html hover .track at 100 style .dot translate
div.dot.linear  translate: 50px
div.dot.ease  translate: 81.7021px
div.dot.ease-in  translate: 18.6929px
div.dot.ease-out  translate: 75.6276px
ana@laptop:~/site$ probe transition.html hover .track at 200 style .dot translate
div.dot.linear  translate: 100px
div.dot.ease  translate: 160.481px
div.dot.ease-in  translate: 63.0713px
div.dot.ease-out  translate: 136.929px
```

Em 100 ms, um quarto do tempo, o **`linear`** fez um quarto da distância, **50**. O **`ease`**, o padrão, está em **81,7**, já 41% do caminho. O **`ease-in`** mal começou, **18,7**. O **`ease-out`** está em **75,6**. Na metade do tempo, o linear está na metade, 100, enquanto o `ease` está em **160,5** e o `ease-in` em só **63,1**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 222\" role=\"img\" aria-label=\"Distância percorrida em função do tempo para quatro funções de tempo, em 400 milissegundos e 200 pixels. Linear é uma reta. Ease sobe forte e achata. Ease-in começa plana e sobe tarde. Ease-out sobe rápido e assenta. Pontos medidos em 100 ms: linear 50, ease 81,7, ease-in 18,7, ease-out 75,6. Em 200 ms: linear 100, ease 160,5, ease-in 63,1, ease-out 136,9.\"><line x1=\"60\" y1=\"196\" x2=\"360\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"60\" y1=\"196\" x2=\"60\" y2=\"26\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><text x=\"60\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0</text><text x=\"135\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">100</text><text x=\"210\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">200</text><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">400 ms</text><text x=\"52\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0</text><text x=\"52\" y=\"26\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">200px</text><path d=\"M 60 196 L 65.0 193.2 L 70.0 190.3 L 75.0 187.5 L 80.0 184.7 L 85.0 181.8 L 90.0 179.0 L 95.0 176.2 L 100.0 173.3 L 105.0 170.5 L 110.0 167.7 L 115.0 164.8 L 120.0 162.0 L 125.0 159.2 L 130.0 156.3 L 135.0 153.5 L 140.0 150.7 L 145.0 147.8 L 150.0 145.0 L 155.0 142.2 L 160.0 139.3 L 165.0 136.5 L 170.0 133.7 L 175.0 130.8 L 180.0 128.0 L 185.0 125.2 L 190.0 122.3 L 195.0 119.5 L 200.0 116.7 L 205.0 113.8 L 210.0 111.0 L 215.0 108.2 L 220.0 105.3 L 225.0 102.5 L 230.0 99.7 L 235.0 96.8 L 240.0 94.0 L 245.0 91.2 L 250.0 88.3 L 255.0 85.5 L 260.0 82.7 L 265.0 79.8 L 270.0 77.0 L 275.0 74.2 L 280.0 71.3 L 285.0 68.5 L 290.0 65.7 L 295.0 62.8 L 300.0 60.0 L 305.0 57.2 L 310.0 54.3 L 315.0 51.5 L 320.0 48.7 L 325.0 45.8 L 330.0 43.0 L 335.0 40.2 L 340.0 37.3 L 345.0 34.5 L 350.0 31.7 L 355.0 28.8 L 360.0 26.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" stroke-dasharray=\"5 4\"></path><rect x=\"131.5\" y=\"150\" width=\"7\" height=\"7\" rx=\"3.5\" fill=\"var(--paper-dim)\"></rect><rect x=\"206.5\" y=\"107.5\" width=\"7\" height=\"7\" rx=\"3.5\" fill=\"var(--paper-dim)\"></rect><line x1=\"420\" y1=\"40\" x2=\"450\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" stroke-dasharray=\"5 4\"></line><text x=\"460\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">linear</text><path d=\"M 60 196 L 65.0 194.6 L 70.0 192.8 L 75.0 190.4 L 80.0 187.5 L 85.0 184.0 L 90.0 179.9 L 95.0 175.2 L 100.0 170.1 L 105.0 164.5 L 110.0 158.5 L 115.0 152.2 L 120.0 145.8 L 125.0 139.3 L 130.0 132.9 L 135.0 126.6 L 140.0 120.4 L 145.0 114.4 L 150.0 108.7 L 155.0 103.3 L 160.0 98.1 L 165.0 93.2 L 170.0 88.5 L 175.0 84.1 L 180.0 80.0 L 185.0 76.0 L 190.0 72.3 L 195.0 68.9 L 200.0 65.6 L 205.0 62.5 L 210.0 59.6 L 215.0 56.9 L 220.0 54.3 L 225.0 51.9 L 230.0 49.6 L 235.0 47.5 L 240.0 45.5 L 245.0 43.7 L 250.0 41.9 L 255.0 40.3 L 260.0 38.8 L 265.0 37.4 L 270.0 36.1 L 275.0 34.9 L 280.0 33.7 L 285.0 32.7 L 290.0 31.8 L 295.0 30.9 L 300.0 30.1 L 305.0 29.4 L 310.0 28.8 L 315.0 28.2 L 320.0 27.8 L 325.0 27.3 L 330.0 27.0 L 335.0 26.7 L 340.0 26.4 L 345.0 26.2 L 350.0 26.1 L 355.0 26.0 L 360.0 26.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><rect x=\"131.5\" y=\"123.05\" width=\"7\" height=\"7\" rx=\"3.5\" fill=\"var(--phosphor)\"></rect><rect x=\"206.5\" y=\"56.09\" width=\"7\" height=\"7\" rx=\"3.5\" fill=\"var(--phosphor)\"></rect><line x1=\"420\" y1=\"66\" x2=\"450\" y2=\"66\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"460\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">ease</text><path d=\"M 60 196 L 65.0 195.9 L 70.0 195.7 L 75.0 195.2 L 80.0 194.7 L 85.0 194.0 L 90.0 193.1 L 95.0 192.1 L 100.0 191.0 L 105.0 189.8 L 110.0 188.4 L 115.0 187.0 L 120.0 185.4 L 125.0 183.7 L 130.0 182.0 L 135.0 180.1 L 140.0 178.2 L 145.0 176.1 L 150.0 174.0 L 155.0 171.8 L 160.0 169.5 L 165.0 167.1 L 170.0 164.6 L 175.0 162.1 L 180.0 159.5 L 185.0 156.8 L 190.0 154.0 L 195.0 151.2 L 200.0 148.3 L 205.0 145.4 L 210.0 142.4 L 215.0 139.3 L 220.0 136.2 L 225.0 133.0 L 230.0 129.7 L 235.0 126.4 L 240.0 123.0 L 245.0 119.6 L 250.0 116.1 L 255.0 112.6 L 260.0 109.0 L 265.0 105.4 L 270.0 101.7 L 275.0 97.9 L 280.0 94.1 L 285.0 90.3 L 290.0 86.4 L 295.0 82.4 L 300.0 78.4 L 305.0 74.4 L 310.0 70.3 L 315.0 66.1 L 320.0 61.9 L 325.0 57.6 L 330.0 53.3 L 335.0 48.9 L 340.0 44.5 L 345.0 40.0 L 350.0 35.4 L 355.0 30.8 L 360.0 26.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><rect x=\"131.5\" y=\"176.61\" width=\"7\" height=\"7\" rx=\"3.5\" fill=\"var(--amber)\"></rect><rect x=\"206.5\" y=\"138.89\" width=\"7\" height=\"7\" rx=\"3.5\" fill=\"var(--amber)\"></rect><line x1=\"420\" y1=\"92\" x2=\"450\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"460\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">ease-in</text><path d=\"M 60 196 L 65.0 191.2 L 70.0 186.6 L 75.0 182.0 L 80.0 177.5 L 85.0 173.1 L 90.0 168.7 L 95.0 164.4 L 100.0 160.1 L 105.0 155.9 L 110.0 151.7 L 115.0 147.6 L 120.0 143.6 L 125.0 139.6 L 130.0 135.6 L 135.0 131.7 L 140.0 127.9 L 145.0 124.1 L 150.0 120.3 L 155.0 116.6 L 160.0 113.0 L 165.0 109.4 L 170.0 105.9 L 175.0 102.4 L 180.0 99.0 L 185.0 95.6 L 190.0 92.3 L 195.0 89.0 L 200.0 85.8 L 205.0 82.7 L 210.0 79.6 L 215.0 76.6 L 220.0 73.7 L 225.0 70.8 L 230.0 68.0 L 235.0 65.2 L 240.0 62.5 L 245.0 59.9 L 250.0 57.4 L 255.0 54.9 L 260.0 52.5 L 265.0 50.2 L 270.0 48.0 L 275.0 45.9 L 280.0 43.8 L 285.0 41.9 L 290.0 40.0 L 295.0 38.3 L 300.0 36.6 L 305.0 35.0 L 310.0 33.6 L 315.0 32.2 L 320.0 31.0 L 325.0 29.9 L 330.0 28.9 L 335.0 28.0 L 340.0 27.3 L 345.0 26.8 L 350.0 26.3 L 355.0 26.1 L 360.0 26.0\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></path><rect x=\"131.5\" y=\"128.22\" width=\"7\" height=\"7\" rx=\"3.5\" fill=\"var(--paper)\"></rect><rect x=\"206.5\" y=\"76.11\" width=\"7\" height=\"7\" rx=\"3.5\" fill=\"var(--paper)\"></rect><line x1=\"420\" y1=\"118\" x2=\"450\" y2=\"118\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"460\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">ease-out</text><text x=\"420\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Curvas: cada função de tempo.</text><text x=\"420\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Pontos: as posições medidas</text><text x=\"420\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">em 100 e 200 ms.</text></svg>", "caption": "A mesma distância no mesmo tempo, gasta de quatro jeitos."}
```

Para que serve cada um:

- **`ease-out`** começa rápido e desacelera no fim. Coisas que **chegam**, como um painel que desliza para dentro ou um menu que abre, parecem responder com ele: reagem na hora e assentam com suavidade.
- **`ease-in`** começa devagar e acelera. Coisas que **saem**: parece algo ganhando velocidade na saída. Como entrada, parece atrasado, porque no começo nada parece acontecer.
- **`ease`** e **`ease-in-out`** são lentos nas duas pontas, para algo que vai de um lugar da tela a outro.
- **`linear`** é constante, o que parece mecânico para movimento e é o certo para coisas que não devem parecer movimento, como um spinner ou uma barra de progresso enchendo.

Cada palavra-chave é um atalho de **`cubic-bezier(x1, y1, x2, y2)`**, uma curva que você mesmo pode desenhar no DevTools clicando no pequeno ícone de curva ao lado de uma função de tempo no painel Styles. **`steps(n)`** pula em n passos iguais em vez de se mover suavemente, para um efeito quadro a quadro.
