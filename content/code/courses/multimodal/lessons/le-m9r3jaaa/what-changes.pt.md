---
title: O que muda quando o modelo enxerga e ouve
version: 2
---

**Um modelo multimodal não é outro tipo de inteligência. É um modelo cujas entradas e saídas não são só texto.** Essa é a definição inteira, e vale guardá-la, porque quase tudo o que dá errado em produtos multimodais vem de esquecê-la. O modelo continua prevendo; continua tendo uma janela; continua cobrando pelo que lê e escreve. O que muda é o tamanho e o formato do que entra.

Uma **modalidade** é um tipo de dado: texto, imagem, áudio, vídeo. Um modelo é descrito pelas modalidades que recebe e pelas que devolve. O Whisper recebe áudio e devolve texto. Um gerador de imagens recebe texto e devolve uma imagem. Um modelo de visão recebe texto e imagens e devolve texto. Um modelo de áudio nativo recebe áudio e devolve áudio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quatro tipos de entrada à esquerda, texto, imagem, áudio e vídeo, cada um com uma seta para uma caixa no meio chamada modelo. Três tipos de saída à direita, texto, imagem e áudio. Sob cada seta da esquerda está o que a entrada vira antes de o modelo a ler: tokens, blocos ou recortes, quadros de som, e imagens amostradas mais uma trilha de áudio.\"><defs><marker id=\"l01dir-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01dir-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"29.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">texto</text><text x=\"30\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tokens</text><line x1=\"192\" y1=\"37\" x2=\"300\" y2=\"125\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-phosphor)\"></line><rect x=\"20\" y=\"72\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">imagem</text><text x=\"30\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">blocos ou recortes</text><line x1=\"192\" y1=\"95\" x2=\"300\" y2=\"125\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-phosphor)\"></line><rect x=\"20\" y=\"130\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">áudio</text><text x=\"30\" y=\"161.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quadros de som</text><line x1=\"192\" y1=\"153\" x2=\"300\" y2=\"125\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-phosphor)\"></line><rect x=\"20\" y=\"188\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"203.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">vídeo</text><text x=\"30\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">imagens + trilha</text><line x1=\"192\" y1=\"211\" x2=\"300\" y2=\"125\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-phosphor)\"></line><rect x=\"302\" y=\"95\" width=\"116\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"312\" y=\"117.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">modelo</text><text x=\"312\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma chamada</text><line x1=\"420\" y1=\"125\" x2=\"586\" y2=\"65\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-amber)\"></line><rect x=\"590\" y=\"45\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">texto</text><line x1=\"420\" y1=\"125\" x2=\"586\" y2=\"125\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-amber)\"></line><rect x=\"590\" y=\"105\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">imagem</text><line x1=\"420\" y1=\"125\" x2=\"586\" y2=\"185\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l01dir-ah-amber)\"></line><rect x=\"590\" y=\"165\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">áudio</text></svg>", "caption": "Toda modalidade vira algo que o modelo conta antes de ler, e o custo segue a contagem.", "same": ["tokens"]}
```

## Tudo vira algo que se conta

Um modelo de linguagem lê tokens. Antes de chegar a um modelo de visão, a imagem é redimensionada e cortada em blocos ou em pequenos recortes quadrados, e cada um custa tokens. Na aula 8 você vai contá-los: uma regra cobra 765 tokens pela capa de um livro de bolso, e a mesma regra cobra 85 se você pedir a versão de baixo detalhe. O áudio é cortado em quadros curtos de som; o Whisper escuta em janelas de 30 segundos. Um vídeo são imagens amostradas dele mais a trilha de áudio, e quantas imagens amostrar é uma decisão sua, com custo (aula 4).

Então a primeira coisa que muda é **o tamanho de uma entrada**. Esta é a mídia do curso, os arquivos com que toda aula trabalha, listada por um programa curto. Você monta a máquina e a mídia nas seções 07 e 08 desta aula; até lá, leia as transcrições, e rode-as depois.

`inventory.py`:

```python
"""What is in ~/mm/media: one line per file, and what a model would be handed."""
import json
import os
import subprocess

for name in sorted(os.listdir("media")):
    path = os.path.join("media", name)
    if not os.path.isfile(path):
        continue
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json", path],
                           capture_output=True, text=True, check=True)
    info = json.loads(probe.stdout)
    kinds, timed = [], False
    for s in info["streams"]:
        if s["codec_type"] == "video" and s["codec_name"] in ("png", "mjpeg"):
            kinds.append(f"image {s['width']}x{s['height']}")
        elif s["codec_type"] == "video":
            kinds.append(f"video {s['width']}x{s['height']} {s['codec_name']}")
            timed = True
        elif s["codec_type"] == "audio":
            kinds.append(f"audio {s['sample_rate']} Hz {s['codec_name']}")
            timed = True
    seconds = f"{float(info['format']['duration']):6.1f} s" if timed else "       -"
    print(f"{name:22} {os.path.getsize(path):>10,} B {seconds}  " + " + ".join(kinds))
```

```
ana@lab:~/mm$ python inventory.py
call-1042-noisy.wav     1,772,316 B   55.4 s  audio 16000 Hz pcm_s16le
call-1042-phone.wav       443,126 B   55.4 s  audio 8000 Hz pcm_mulaw
call-1042.wav           1,772,316 B   55.4 s  audio 16000 Hz pcm_s16le
cat_and_dog.jpg            69,041 B        -  image 640x416
cover-b39.png              19,605 B        -  image 600x900
invoice-0931-scan.jpg      95,891 B        -  image 827x1170
invoice-0931.png           87,530 B        -  image 1240x1754
returns.mp4               495,585 B   32.6 s  video 1280x720 h264 + audio 44100 Hz aac
voicemail-pt.wav          399,120 B   12.5 s  audio 16000 Hz pcm_s16le
```

Cinquenta e cinco segundos de uma ligação são 1.772.316 bytes como foram gravados, e a mesma ligação por uma linha telefônica, a 8000 amostras por segundo, é um quarto disso. Uma página inteira de nota fiscal tem menos de 100 kilobytes. Nada disso é grande para um disco, e tudo isso é grande para um modelo. Uma página de texto puro tem algumas centenas de tokens.

## Outras três coisas mudam junto

**A resposta é mais difícil de conferir.** Quando um modelo resume um texto, você pode ler o texto. Quando ele diz o que está escrito numa nota fiscal, ou o que alguém disse ao telefone, a verdade está numa imagem ou numa gravação, e conferir significa olhar ou ouvir você mesmo. Quase todo este curso trata de medir um modelo contra uma verdade conhecida, e o laboratório foi construído para que a verdade seja conhecida: cada gravação foi falada a partir de um roteiro, e cada imagem foi desenhada a partir de uma especificação.

**Os erros parecem conteúdo.** Uma transcrição com uma palavra errada se lê com a mesma fluência de uma sem erro. O Whisper ouve o nome *Caio* na ligação do laboratório e escreve *Kau*, sem nenhuma marca de dúvida ao lado.

**Os dados são mais pessoais.** Uma fotografia tem rostos, uma gravação tem uma voz, e um documento tem um nome e um endereço. A aula 8 tira os metadados de uma imagem antes que ela saia da máquina, e os motivos estão na seção sobre quando não usar nada disso.
