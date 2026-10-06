---
title: Achando onde as pessoas falam
version: 1
---

A **detecção de atividade de voz (VAD)** responde à pergunta mais simples sobre uma gravação: fala ou não fala, momento a momento. Todo outro passo deste curso se apoia nela. Ela decide onde cortar o áudio antes de transcrever (aula 4), onde uma legenda começa e termina (aula 14) e quanto de uma gravação longa você paga para transcrever (aula 13). O Silero VAD é um modelo de 632 kilobytes que lê o áudio em janelas de 32 milissegundos e diz, para cada uma, quão provável é que seja fala.

Contra a verdade do roteiro, na ligação limpa:

```python
"""Where Silero hears speech, against where the script says somebody was speaking."""
import json
import sys

import mmlab

path, silence = sys.argv[1], float(sys.argv[2])
turns = json.load(open("media/truth/call-1042.json"))["turns"]
found = mmlab.speech_segments(mmlab.read_audio(path), min_silence=silence)
print(f"{path}, silences under {silence} s ignored: {len(found)} stretches for {len(turns)} turns")
for start, end in found:
    inside = [t["who"] for t in turns if t["start"] < end and t["end"] > start]
    print(f"  {start:6.2f} {end:6.2f}  {'+'.join(inside)}")
```

```
ana@lab:~/mm$ python vad.py media/call-1042.wav 0.25
media/call-1042.wav, silences under 0.25 s ignored: 11 stretches for 9 turns
    0.26   4.36  caio
    4.58   5.32  caio
    6.05  14.31  bia
   15.01  16.39  caio
   16.61  23.88  caio
   25.00  29.16  bia
   29.99  38.21  caio
   39.69  41.32  bia
   41.89  49.57  caio
   50.34  51.46  bia
   52.17  55.36  caio
ana@lab:~/mm$ python vad.py media/call-1042.wav 1.0 | head -4
media/call-1042.wav, silences under 1.0 s ignored: 4 stretches for 9 turns
    0.26  20.48  caio+bia+caio
   20.58  23.90  caio
   25.00  47.26  bia+caio+bia+caio
ana@lab:~/mm$ python vad.py media/call-1042-noisy.wav 0.25
media/call-1042-noisy.wav, silences under 0.25 s ignored: 5 stretches for 9 turns
    0.33  14.63  caio+bia
   15.01  35.90  caio+bia+caio
   36.20  38.89  caio
   39.17  50.09  bia+caio
   50.37  55.36  bia+caio
ana@lab:~/mm$ python vad.py call-gtcrn.wav 0.25 | head -1
call-gtcrn.wav, silences under 0.25 s ignored: 13 stretches for 9 turns
```

Na ligação limpa o Silero achou **11 trechos para 9 falas**, e cada fronteira fica a cerca de um quarto de segundo da verdade. Duas falas do Caio saíram como dois trechos cada: ele faz uma pausa no meio da frase (*Good morning, you're through to Marginalia support. My name is Caio.*), e a pausa passou dos 0,25 segundo que o `mmlab.speech_segments` ignora por padrão.

**A configuração que mais importa é quanto um silêncio precisa durar para contar.** Com 1,0 segundo, o segundo comando junta trocas inteiras: o primeiro trecho vai de 0,26 a 20,48 segundos e contém três falas, Caio, Bia e Caio de novo, porque nenhum intervalo entre elas chegou a um segundo. Silêncios curtos dão pedaços que seguem frases; longos dão pedaços que seguem assuntos. Qual você quer depende do que vem depois: legendas querem pedaços curtos, um resumidor fica bem com longos.

**O ruído a quebra na direção oposta.** Na ligação ruidosa o detector achou 5 trechos, cada um atravessando duas ou três falas: os intervalos de meio segundo entre as pessoas se encheram de chiado, e o chiado pareceu fala o bastante. Depois do GTCRN ele achou 13. Esse é o argumento mais forte a favor de um redutor de ruído nesta aula, e não tem nada a ver com as palavras.
