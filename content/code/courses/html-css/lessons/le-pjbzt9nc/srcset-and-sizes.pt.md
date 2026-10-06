---
title: Oferecendo vários arquivos ao navegador
version: 1
---

Uma foto na largura inteira de um monitor grande precisa de um arquivo grande. A mesma foto num celular precisa de uma fração disso, e mandar o grande mesmo assim custa ao leitor tempo e dados móveis. **`srcset` lista vários arquivos da mesma imagem em larguras diferentes, e `sizes` diz ao navegador com que largura ela será desenhada**, para o navegador poder escolher.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>The shop · Andorinha Books</title>
    <style>
      body { margin: 0; }
      img { width: 100%; height: auto; }
      @media (min-width: 800px) { img { width: 50%; } }
    </style>
  </head>
  <body>
    <img src="shelves-960.png"
         srcset="shelves-480.png 480w, shelves-960.png 960w, shelves-1600.png 1600w"
         sizes="(min-width: 800px) 50vw, 100vw"
         width="960" height="640"
         alt="The shelves of the shop, floor to ceiling">
  </body>
</html>
```

Os três arquivos são a mesma imagem com 480, 960 e 1600 pixels de largura, e o `srcset` diz isso com um `w` depois de cada largura. `sizes` diz com que largura a imagem será desenhada: `(min-width: 800px) 50vw` quer dizer metade da janela numa janela de pelo menos 800 pixels de largura, e `100vw` quer dizer a largura inteira nos outros casos. Ele repete o que o CSS do `<style>` diz, porque o navegador escolhe o arquivo antes de ter calculado o layout. `src` continua sendo o arquivo para qualquer navegador que não leia `srcset`.

## O que o navegador escolheu

Numa janela do tamanho de um celular, com 360 pixels de largura, em três densidades de pixel:

```
ana@laptop:~/site$ probe --width 360 --dpr 1 srcset.html img img
img  chose shelves-480.png (480×320 pixels), drawn 360 wide
ana@laptop:~/site$ probe --width 360 --dpr 2 srcset.html img img
img  chose shelves-960.png (960×640 pixels), drawn 360 wide
ana@laptop:~/site$ probe --width 360 --dpr 3 srcset.html img img
img  chose shelves-1600.png (1600×1067 pixels), drawn 360 wide
```

E numa janela de 1280 de largura, onde a imagem é desenhada com a metade disso:

```
ana@laptop:~/site$ probe --width 1280 --dpr 1 srcset.html img img
img  chose shelves-960.png (960×640 pixels), drawn 640 wide
ana@laptop:~/site$ probe --width 1280 --dpr 2 srcset.html img img
img  chose shelves-1600.png (1600×1067 pixels), drawn 640 wide
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Uma régua de pixels de 0 a 1600 com os três arquivos oferecidos desenhados como barras de 480, 960 e 1600 de largura. Abaixo, cinco necessidades medidas pelo probe, cada uma a largura desenhada vezes a densidade de pixels: 360, 720, 1080, 640 e 1280. Para cada uma, o navegador escolheu o menor arquivo com pelo menos essa largura: 480, 960, 1600, 960 e 1600.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">os arquivos oferecidos</text><rect x=\"150\" y=\"32\" width=\"144\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">480w</text><rect x=\"150\" y=\"54\" width=\"288\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"444\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">960w</text><rect x=\"150\" y=\"76\" width=\"480\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"636\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1600w</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">necessário</text><text x=\"20\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">largura × densidade</text><text x=\"20\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">360 × 1</text><line x1=\"150\" y1=\"152\" x2=\"258\" y2=\"152\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><rect x=\"255\" y=\"149\" width=\"6\" height=\"6\" rx=\"3\" fill=\"var(--phosphor)\"></rect><text x=\"268\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">escolheu 480w</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">360 × 2</text><line x1=\"150\" y1=\"172\" x2=\"366\" y2=\"172\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><rect x=\"363\" y=\"169\" width=\"6\" height=\"6\" rx=\"3\" fill=\"var(--phosphor)\"></rect><text x=\"376\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">escolheu 960w</text><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">360 × 3</text><line x1=\"150\" y1=\"192\" x2=\"474\" y2=\"192\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><rect x=\"471\" y=\"189\" width=\"6\" height=\"6\" rx=\"3\" fill=\"var(--phosphor)\"></rect><text x=\"484\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">escolheu 1600w</text><text x=\"20\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">640 × 1</text><line x1=\"150\" y1=\"212\" x2=\"342\" y2=\"212\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><rect x=\"339\" y=\"209\" width=\"6\" height=\"6\" rx=\"3\" fill=\"var(--phosphor)\"></rect><text x=\"352\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">escolheu 960w</text><text x=\"20\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">640 × 2</text><line x1=\"150\" y1=\"232\" x2=\"534\" y2=\"232\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><rect x=\"531\" y=\"229\" width=\"6\" height=\"6\" rx=\"3\" fill=\"var(--phosphor)\"></rect><text x=\"544\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">escolheu 1600w</text><line x1=\"150\" y1=\"262\" x2=\"645\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"150\" y1=\"258\" x2=\"150\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"150\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><line x1=\"270\" y1=\"258\" x2=\"270\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"270\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><line x1=\"390\" y1=\"258\" x2=\"390\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"390\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">800</text><line x1=\"510\" y1=\"258\" x2=\"510\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"510\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1200</text><line x1=\"630\" y1=\"258\" x2=\"630\" y2=\"266\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"630\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1600</text></svg>", "caption": "Cada necessidade é atendida pelo arquivo mais estreito que passa dela."}
```

A **densidade de pixels do dispositivo** (*device pixel ratio*), o `--dpr` destes comandos, é quantos pixels físicos uma tela tem por pixel CSS: 1 num monitor comum, 2 ou 3 na maioria dos celulares. Uma imagem desenhada com 360 pixels CSS de largura numa tela de densidade 3 tem 1080 pixels físicos de largura, e um arquivo de 480 pixels pareceria borrado. Então o navegador multiplica, e nas cinco execuções o Chromium pegou **o arquivo mais estreito com pelo menos a largura desse produto**: 480 para 360, 960 para 720 e para 640, 1600 para 1080 e para 1280.

Foi o que o Chromium fez aqui, não uma regra em que a página possa confiar. **O padrão deixa o navegador escolher qualquer candidato**, e um navegador pode pegar um arquivo menor numa conexão lenta ou manter um maior que já tem no cache. O seu trabalho é oferecer arquivos sensatos e dizer a verdade no `sizes`; a escolha é do navegador.

## Quando o `sizes` está errado

`sizes` é uma promessa sobre o layout, e nada a confere. Deixe-o de fora e o navegador supõe `100vw`, a largura inteira da janela, então na janela de 1280 acima ele teria escolhido um arquivo para 1280 ou 2560 pixels para desenhar uma imagem de 640 de largura. Acertar o `sizes` depois de uma mudança de layout é o passo que as pessoas esquecem, e o DevTools mostra o custo: o painel Network lista o arquivo que de fato foi buscado, e esse é o teste.
