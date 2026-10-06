---
title: Entonação, ritmo e dizer do mesmo jeito duas vezes
version: 1
---

**Entonação é como a altura da voz se move por uma frase**, e em inglês ela carrega sentido: uma afirmação cai no fim, uma pergunta sobe. O Piper se guia pela pontuação, que o espeak-ng repassa como uma marca do tipo de oração. As mesmas quatro palavras com ponto final e com ponto de interrogação:

```
ana@lab:~/mm$ python say.py en_US-lessac-medium "Your order has shipped." /tmp/a.wav 1.0
/tmp/a.wav: 1.14 s of audio at 22050 Hz, made in 0.11 s
ana@lab:~/mm$ python say.py en_US-lessac-medium "Your order has shipped?" /tmp/b.wav 1.0
/tmp/b.wav: 1.15 s of audio at 22050 Hz, made in 0.11 s
ana@lab:~/mm$ python say.py en_US-lessac-medium "Your order has shipped!" /tmp/c.wav 1.0
/tmp/c.wav: 1.14 s of audio at 22050 Hz, made in 0.12 s
ana@lab:~/mm$ python say.py en_US-lessac-medium "Your order has shipped." /tmp/d.wav 0.8
/tmp/d.wav: 1.31 s of audio at 22050 Hz, made in 0.13 s
ana@lab:~/mm$ python say.py en_US-lessac-medium "Your order has shipped." /tmp/e.wav 1.25
/tmp/e.wav: 1.00 s of audio at 22050 Hz, made in 0.09 s
```

As durações quase não mudam, 1,14 contra 1,15 segundo. A altura muda, medida por um programinha que estima a frequência fundamental da voz a cada 30 milissegundos:

```python
"""The voice's pitch over the first half of a sentence and over its last word."""
import sys

import numpy as np
import soundfile as sf


def pitch(frame, rate):
    """One frame's fundamental frequency, by autocorrelation, or None when it is not voiced."""
    frame = frame - frame.mean()
    ac = np.correlate(frame, frame, "full")[len(frame) - 1:]
    lo, hi = rate // 400, rate // 70                     # look for a pitch between 70 and 400 Hz
    lag = lo + int(np.argmax(ac[lo:hi]))
    return rate / lag if ac[lag] > 0.3 * ac[0] else None


for path in sys.argv[1:]:
    x, rate = sf.read(path)
    step = int(0.03 * rate)
    f0 = [(i / rate, pitch(x[i:i + step], rate)) for i in range(0, len(x) - step, step)]
    voiced = [(t, f) for t, f in f0 if f]
    end = voiced[-1][0]
    early = np.median([f for t, f in voiced if t < end / 2])
    late = np.median([f for t, f in voiced if t > end - 0.35])
    print(f"{path}: {early:5.0f} Hz in the first half, {late:5.0f} Hz over the last word")
```

```
ana@lab:~/mm$ python pitch.py /tmp/a.wav /tmp/b.wav
/tmp/a.wav:   184 Hz in the first half,   125 Hz over the last word
/tmp/b.wav:   204 Hz in the first half,   174 Hz over the last word
```

A afirmação começa perto de 184 Hz e cai para 125 Hz na última palavra. A pergunta começa mais alta e fica lá em cima, 174 Hz na última palavra. Essa é a diferença que quem ouve percebe entre *Your order has shipped.* e *Your order has shipped?*, e ela veio de um caractere. **A pontuação é o controle mais barato que você tem sobre uma voz**: uma vírgula para uma pausa, um ponto para um fim, uma interrogação para uma pergunta, e um travessão onde você quer uma pausa mais longa que a de uma vírgula.

O **ritmo** é uma configuração. O `speed` do Piper escala a duração de cada som: com 0,8 a frase levou 1,31 segundo, com 1,25 levou 1,00. Menus telefônicos costumam ser um pouco mais lentos, porque quem ouve não pode voltar e um número ouvido rápido demais tem de ser pedido de novo.

## O que as vozes comerciais acrescentam

A maioria dos serviços de TTS hospedados aceita **SSML** (Speech Synthesis Markup Language), um dialeto XML para exatamente esses controles: `<break time="500ms"/>` para uma pausa, `<prosody rate="slow">` para o ritmo, `<say-as interpret-as="characters">` para ler um código letra a letra, `<phoneme>` para uma pronúncia. Google Cloud, Amazon Polly e Azure dão suporte, cada um com o seu subconjunto. Os modelos de fala da OpenAI não aceitam SSML; o mais novo recebe em vez disso um campo `instructions` em linguagem comum ("fale devagar e com calor"). O Piper não aceita nenhum dos dois, e por isso esta aula faz o mesmo trabalho no texto.

## A mesma frase, duas vezes

Os modelos VITS do Piper acrescentam um pouco de aleatoriedade ao falar, como uma pessoa nunca diz uma frase do mesmo jeito duas vezes. Isso costuma ser bom para uma passagem longa e ruim para um teste:

```python
"""The same sentence spoken twice, with Piper's own noise and without it."""
import hashlib

import numpy as np

import mmlab

TEXT = "Your order has shipped."
for noise in (True, False):
    tts = mmlab.piper("en_US-lessac-medium", noise=noise)
    takes = [tts.generate(TEXT, sid=0, speed=1.0) for _ in range(2)]
    sums = [hashlib.sha256(np.asarray(t.samples).tobytes()).hexdigest()[:12] for t in takes]
    lengths = [f"{len(t.samples) / t.sample_rate:.2f} s" for t in takes]
    print(f"noise {'on ' if noise else 'off'}  {sums[0]} {lengths[0]}   {sums[1]} {lengths[1]}   "
          f"{'the same' if sums[0] == sums[1] else 'different'}")
```

```
ana@lab:~/mm$ python twice.py
noise on   ae68a97ed74a 1.22 s   78f3a3307264 1.24 s   different
noise off  8ca881e0ebb4 1.14 s   8ca881e0ebb4 1.14 s   the same
```

Com o ruído próprio da voz (`noise_scale` 0,667 na configuração da lessac), a mesma frase saiu como dois arquivos diferentes, de 1,20 e 1,13 segundo. Com o ruído desligado, as duas tomadas são idênticas até a última amostra. **Este laboratório o desliga em todo lugar**, que é a única configuração que o `mmlab.piper` faz: uma gravação que mudasse a cada reconstrução do laboratório não poderia ser citada por aula nenhuma. Um produto poderia escolher o contrário, para uma voz que soe menos mecânica numa ligação longa.
