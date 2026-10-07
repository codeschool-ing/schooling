---
title: O que uma imagem é para um modelo
version: 1
---

**Uma imagem é uma grade de números, e um modelo só lê a grade.** Uma fotografia de 640 por 416 pixels em cores são 640 × 416 × 3 = 798.720 números entre 0 e 255, um para vermelho, verde e azul em cada ponto. Não há "texto" nem "gato" no arquivo. O que há no arquivo é o padrão de números que uma pessoa lê como texto ou gato, e um modelo é algo treinado para transformar esses padrões em respostas.

Duas consequências, e as duas pesam mais do que a escolha do modelo.

**O modelo vê um tamanho fixo.** Quase todo modelo de imagem redimensiona o que recebe antes de ler. O detector de objetos do MediaPipe trabalha num quadrado de 320 pixels; um modelo de visão e linguagem corta a imagem em blocos ou recortes de tamanho fixo e paga por cada um (a aula 8 os conta). O que o modelo lê é a cópia redimensionada, então o detalhe que o redimensionamento joga fora nunca foi visto.

**Resolução é informação, e abaixo de certo tamanho ela some.** Aqui está a nota limpa, reduzida passo a passo e lida pelo Tesseract a cada vez:

```python
"""The clean invoice made smaller and smaller, and read each time."""
import subprocess

import jiwer
from PIL import Image

TRUTH = " ".join(open("media/truth/invoice-0931.txt").read().split())
page = Image.open("media/invoice-0931.png")
for width in (1240, 620, 413, 310):
    small = page.resize((width, round(page.height * width / page.width)), Image.LANCZOS)
    small.save(f"/tmp/invoice-{width}.png")
    out = subprocess.run(["tesseract", f"/tmp/invoice-{width}.png", "-", "--psm", "6"],
                         capture_output=True, text=True, check=True).stdout
    print(f"{width:5} px wide ({width * 150 // 1240:3} dpi)  CER {jiwer.cer(TRUTH, ' '.join(out.split())):6.1%}")
```

```
ana@lab:~/mm$ python shrink.py
 1240 px wide (150 dpi)  CER   0.4%
  620 px wide ( 75 dpi)  CER   1.4%
  413 px wide ( 49 dpi)  CER  20.7%
  310 px wide ( 37 dpi)  CER  92.7%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um gráfico de barras com a taxa de erro de caracteres do Tesseract na nota limpa em quatro tamanhos. Com 1240 pixels de largura, 150 dpi, 0,4%. Com 620 pixels, 75 dpi, 1,4%. Com 413 pixels, 49 dpi, 20,7%. Com 310 pixels, 37 dpi, 92,7%, quase todo caractere errado.\"><line x1=\"80\" y1=\"190\" x2=\"690\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">taxa de erro de caracteres</text><rect x=\"110\" y=\"188\" width=\"70\" height=\"2\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"145\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,4%</text><text x=\"145\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1240 px</text><text x=\"145\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">150 dpi</text><rect x=\"260\" y=\"187.9\" width=\"70\" height=\"2.1\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"295\" y=\"177.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1,4%</text><text x=\"295\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">620 px</text><text x=\"295\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">75 dpi</text><rect x=\"410\" y=\"158.95\" width=\"70\" height=\"31.05\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"445\" y=\"148.95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20,7%</text><text x=\"445\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">413 px</text><text x=\"445\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">49 dpi</text><rect x=\"560\" y=\"50.94999999999999\" width=\"70\" height=\"139.05\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"595\" y=\"40.94999999999999\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">92,7%</text><text x=\"595\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">310 px</text><text x=\"595\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">37 dpi</text></svg>", "caption": "Corte a largura pela metade e o erro mal se move; corte de novo e as letras já não estão lá para ler."}
```

Reduzir a largura de 1240 para 620 pixels quase não custou nada: 0,4% de caracteres errados virou 1,4%. Com 413 pixels, um quinto dos caracteres está errado, e com 310, quase todos. A página não ficou mais difícil de entender; as letras deixaram de estar lá. A 37 pontos por polegada uma letra minúscula tem três ou quatro pixels de altura, e nenhum modelo lê uma forma que não está na grade.

A mesma conta vale ao contrário quando você está pagando. Uma API de visão cobra pelo quanto da imagem ela lê, e mandar uma página com 4000 pixels de largura quando 1240 leem perfeitamente é pagar por pixels que não acrescentam nada. A aula 13 manda a menor imagem que ainda se lê, e esta medição é o jeito de achá-la: reduza até o erro começar a subir, depois volte um passo.

## De onde vieram os números

A nota foi desenhada pelo `make_media.py` a 150 pontos por polegada a partir de uma especificação, então `media/truth/invoice-0931.txt` guarda exatamente o que está impresso nela, linha por linha. A **taxa de erro de caracteres** (CER, na sigla em inglês) destas transcrições é o número de caracteres que você teria de trocar, apagar ou inserir para transformar a leitura na verdade, dividido pelo tamanho da verdade. O `jiwer.cer` calcula isso. 0,4% dos 492 caracteres da página são dois caracteres, e a próxima seção os encontra.
