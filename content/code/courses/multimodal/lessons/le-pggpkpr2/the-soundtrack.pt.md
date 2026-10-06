---
title: Ouvindo a trilha de áudio
version: 1
---

O segundo fluxo é a narração, e ela carrega o que os slides não dizem: os motivos de cada passo e os detalhes que o narrador acrescenta de passagem. O `mmlab.read_audio` pede ao ffmpeg o fluxo de áudio de qualquer arquivo, então a mesma função que lê um WAV lê a trilha de um MP4, reamostrada para as 16.000 amostras por segundo que o Whisper espera.

```python
"""The video's soundtrack, cut at its silences and transcribed piece by piece."""
import json
import sys

import mmlab

samples = mmlab.read_audio(sys.argv[1])
whisper = mmlab.whisper("base", language="en")
said = []
for start, end in mmlab.speech_segments(samples):
    text, _ = mmlab.transcribe(whisper, samples[int(start * mmlab.RATE):int(end * mmlab.RATE)])
    said.append({"start": round(start, 2), "end": round(end, 2), "text": text})
    print(f"{start:6.2f} {end:6.2f}  {text}")
json.dump(said, open("said.json", "w"), indent=1)
```

```
ana@lab:~/mm$ python soundtrack.py media/returns.mp4
  0.42   5.19  Here is how to return a book you bought from Marginelia. It takes four steps and the label is free.
  6.34  10.89  First, sign and end open the order the book came in. You will find it under account then orders.
 12.04  14.98  Second, press return this item and choose a reason from the list.
 16.10  20.01  Third, print the prepared label we send you by email and tape it over the old address.
 21.83  25.70  Drop the parcel at any post office and keep the receipt until your refund arrives.
 26.89  31.91  Refunds go back to the card you paid with, a damage to book as refunded and full, shipping included.
```

Dois modelos rodaram aqui. O **Silero VAD** (detecção de atividade de voz) achou seis trechos de fala e os silêncios entre eles; a aula 5 olha para ele de perto. O **Whisper base** transcreveu cada trecho separadamente, o que dá a cada pedaço de texto um início e um fim no relógio do vídeo.

Leia a transcrição contra o roteiro que o narrador falou (está em `media/truth/returns.json`) e os erros são de três tipos:

- **Palavras ouvidas como outras palavras.** *Marginelia* por Marginalia, *sign and end* por *sign in*, *prepared label* por *prepaid label*, *a damage to book as refunded and full* por *a damaged book is refunded in full*. Cada uma é uma frase plausível em inglês, e a última muda o sentido.
- **Uma palavra perdida na borda.** O quarto passo começa com *Fourth,* e a transcrição não: o detector de fala julgou que o trecho começava em 21,83 segundos, um instante depois da palavra. Uma palavra cortada na borda de um trecho é um erro característico de cortar o áudio antes de transcrever.
- **Nada para o que não foi dito.** De 20,72 a 21,12 não há fala nenhuma, então a transcrição não tem nada para o cartão. Isso não é erro do Whisper. É o motivo de um vídeo não poder ser entendido só pela trilha.

A aula 7 mede os erros do Whisper direito, com uma taxa de erro de palavras, e a aula 14 transforma transcrições como esta em legendas, onde cada um desses erros estaria na tela.
