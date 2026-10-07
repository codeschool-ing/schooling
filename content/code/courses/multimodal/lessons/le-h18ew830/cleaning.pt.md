---
title: Limpando uma gravação, e medindo se ajudou
version: 2
---

Três jeitos de limpar a ligação ruidosa, do mais bruto ao mais esperto, cada um entregue ao Whisper e pontuado contra o roteiro com a taxa de erro de palavras (WER, na sigla em inglês) do `measure.py`:

```python
"""Two measurements the audio lessons share: words wrong, and speech found."""
import jiwer

import mmlab


def words(text):
    """Lower case, no punctuation, one space: what a word error rate should compare."""
    return " ".join(jiwer.RemovePunctuation()(text.lower()).split())


def transcript(samples, whisper):
    """Cut at silences, transcribe each piece, join them: the pipeline of lesson 4."""
    pieces = mmlab.speech_segments(samples)
    text = " ".join(mmlab.transcribe(whisper, samples[int(s * mmlab.RATE):int(e * mmlab.RATE)])[0] for s, e in pieces)
    return text, pieces


def wer(truth, heard):
    return jiwer.wer(words(truth), words(heard))
```

```python
"""The noisy call cleaned three ways, each one transcribed and scored against the script."""
import subprocess
import time

import numpy as np
import soundfile as sf

import mmlab
from measure import transcript, wer

TRUTH = open("media/truth/call-1042.txt").read()
noisy = mmlab.read_audio("media/call-1042-noisy.wav")


def ffmpeg(audio_filter, out):
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", "media/call-1042-noisy.wav",
                    "-af", audio_filter, out], check=True)
    return mmlab.read_audio(out)


started = time.time()
denoised = np.asarray(mmlab.denoiser()(noisy, mmlab.RATE).samples, dtype=np.float32)
print(f"GTCRN took {time.time() - started:.1f} s for {len(noisy) / mmlab.RATE:.1f} s of audio")
sf.write("call-gtcrn.wav", denoised, mmlab.RATE)

versions = {
    "clean (the truth)": mmlab.read_audio("media/call-1042.wav"),
    "noisy, as recorded": noisy,
    "high-pass at 120 Hz": ffmpeg("highpass=f=120", "/tmp/hp.wav"),
    "high-pass + afftdn": ffmpeg("highpass=f=120,afftdn=nf=-25", "/tmp/fftdn.wav"),
    "GTCRN": denoised,
}
whisper = mmlab.whisper("base", language="en")
for name, samples in versions.items():
    text, pieces = transcript(samples, whisper)
    print(f"{name:20} WER {wer(TRUTH, text):6.1%}   {len(pieces):2} stretches of speech found")
```

```
ana@lab:~/mm$ python clean.py
GTCRN took 3.2 s for 55.4 s of audio
clean (the truth)    WER  12.6%   11 stretches of speech found
noisy, as recorded   WER  20.5%    5 stretches of speech found
high-pass at 120 Hz  WER  14.6%    4 stretches of speech found
high-pass + afftdn   WER  13.2%    3 stretches of speech found
GTCRN                WER  17.9%   13 stretches of speech found
```

- Um **filtro passa-alta em 120 Hz** tira tudo abaixo de 120 Hz. Isso leva o zumbido, e o WER cai de 20,5% para 14,6%.
- O **afftdn** é o redutor de ruído espectral do ffmpeg: ele estima o espectro do ruído e o subtrai, quadro a quadro. Somado ao passa-alta, chega a 13,2%, perto dos 12,6% que o Whisper faz na própria ligação limpa.
- O **GTCRN** é uma pequena rede neural treinada para separar fala de ruído. Levou 3,2 segundos para 55 segundos de áudio, e o Whisper fez 17,9% na saída dele: melhor do que não fazer nada e pior que qualquer um dos filtros.

Então a ferramenta mais esperta perdeu, nesta medida. **Não é que o GTCRN seja ruim**: para quem ouve, a saída dele é a mais limpa das quatro, com o chiado eliminado e não só reduzido. Mas um redutor treinado para deixar a fala agradável para pessoas também altera a fala em pequenos detalhes, e o Whisper foi treinado com quantidades enormes de áudio ruidoso e lida melhor com um chiado do que com uma voz sutilmente alterada. **O que soa mais limpo para você não é o que se transcreve melhor por um modelo.** O único jeito de saber de qual o seu processo precisa é a medida desta seção, nas suas próprias gravações.

A última coluna conta outra história, e é por ela que o GTCRN fica no laboratório. **A ligação ruidosa deixou o detector de fala achar só 5 trechos de fala, onde a ligação limpa tem 11.** Com o chão de ruído tão alto, os silêncios entre as falas deixam de parecer silêncio. Os dois filtros deixaram isso ainda pior, com 4 e 3. O GTCRN trouxe de volta para 13. A seção 05 mostra o que esses trechos longos fazem com a tarefa de separar quem fala.

## A ordem importa

Limpe primeiro, depois reamostre, depois corte, depois transcreva. Um filtro em áudio a 8 kHz não devolve o que a linha telefônica tirou; um redutor de ruído rodado em cada pedacinho depois do corte vê ruído de menos para aprender a forma dele. E guarde o original: um arquivo limpo é um derivado, e as legendas da aula 14 são cronometradas contra o original.
