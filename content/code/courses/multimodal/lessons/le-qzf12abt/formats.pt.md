---
title: O formato em que o áudio viaja
version: 2
---

Uma voz produz números; o que chega a quem ouve é um arquivo ou um fluxo em algum formato, e o formato decide o tamanho e onde ele toca. O endpoint de fala da OpenAI oferece cinco, com os nomes do campo `response_format`, e outros provedores oferecem quase a mesma lista. O ffmpeg faz cada um deles a partir da mesma voz Piper, nas taxas de bits que um serviço de fala usa:

`formats.py`:

```python
"""One sentence from a Piper voice, in the five formats speech APIs offer, and what each one weighs."""
import subprocess

import numpy as np

import mmlab

FORMATS = {"wav": ("wav", ["-c:a", "pcm_s16le"]),
           "flac": ("flac", ["-c:a", "flac"]),
           "mp3": ("mp3", ["-c:a", "libmp3lame", "-b:a", "64k"]),
           "aac": ("adts", ["-c:a", "aac", "-b:a", "64k"]),
           "opus": ("ogg", ["-c:a", "libopus", "-b:a", "32k"])}

audio = mmlab.piper("en_US-lessac-medium").generate("Your order has shipped. It should arrive on Thursday.", sid=0, speed=1.0)
pcm = (np.clip(np.asarray(audio.samples), -1, 1) * 32767).astype("<i2").tobytes()   # 16-bit samples, as a file holds them
for name, (container, codec) in FORMATS.items():
    out = subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-f", "s16le", "-ar", str(audio.sample_rate),
                          "-ac", "1", "-i", "-", *codec, "-map_metadata", "-1", "-fflags", "+bitexact",
                          "-f", container, "-"], input=pcm, capture_output=True, check=True).stdout
    print(f"{name:5} {len(out):7,} bytes")
```

```
ana@lab:~/mm$ python formats.py
wav   121,900 bytes
flac   66,655 bytes
mp3    22,589 bytes
aac    23,368 bytes
opus   10,974 bytes
```

| formato | o que é | tamanho aqui | use para |
|---|---|---|---|
| WAV | as amostras cruas, sem compressão | 121.900 bytes | processamento posterior; nunca para entrega |
| FLAC | as mesmas amostras, comprimidas sem perda | 66.655 bytes | guardar uma cópia mestra |
| MP3 | com perda, a 64 kbit/s aqui | 22.589 bytes | tudo o que precisa tocar em qualquer lugar |
| AAC | com perda, a 64 kbit/s aqui | 23.368 bytes | aparelhos da Apple, arquivos de vídeo |
| Opus | com perda, feito para fala, a 32 kbit/s aqui | 10.974 bytes | a web, sistemas de telefonia, chat de voz |

**O Opus tem um décimo do tamanho do WAV** e é o formato desenhado para fala em redes: todo navegador atual o toca, e ele foi feito para funcionar nas taxas baixas que chamadas usam. Numa linha telefônica o áudio é convertido mais uma vez na borda da rede de telefonia, para 8.000 amostras por segundo, que é como soava a gravação de telefone da aula 5.

Os tamanhos importam duas vezes: uma para cada resposta mandada a quem ligou, e outra na conta, já que alguns provedores cobram fala sintetizada por caractere de entrada e outros por segundo de áudio produzido. A aula 13 faz essa conta com preços reais.
