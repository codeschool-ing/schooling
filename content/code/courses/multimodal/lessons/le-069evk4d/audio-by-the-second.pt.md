---
title: Áudio é cobrado por segundo e limitado por byte
version: 1
---

Uma transcrição é cobrada pelos segundos, então a codificação não muda o preço. Ela muda duas outras coisas: se o arquivo cabe no limite de envio, e o que o modelo ouve. Este programa codifica a ligação de quatro jeitos, manda cada uma ao Whisper base pelo `audio_server.py` da aula 10 (inicie-o antes, num segundo terminal), e compara o que voltou com o roteiro da ligação:

```python
"""One call in four encodings: the bytes, how many minutes fit under 25 MB, and what Whisper heard."""
import os
import subprocess

import jiwer
from openai import OpenAI

LIMIT = 25 * 1024 * 1024
truth = open("media/truth/call-1042.txt").read()
norm = jiwer.Compose([jiwer.ToLowerCase(), jiwer.RemovePunctuation(), jiwer.RemoveMultipleSpaces(),
                      jiwer.Strip(), jiwer.ReduceToListOfListOfWords()])
seconds = 55.38

print("%-24s %9s %10s %6s" % ("encoding", "bytes", "min/25MB", "WER"))
for name, args, ext in (("wav 16 kHz 16-bit", ["-ar", "16000", "-ac", "1"], "wav"),
                        ("mp3 64 kbit/s", ["-ar", "16000", "-ac", "1", "-b:a", "64k"], "mp3"),
                        ("mp3 32 kbit/s", ["-ar", "16000", "-ac", "1", "-b:a", "32k"], "mp3"),
                        ("opus 16 kbit/s", ["-ar", "16000", "-ac", "1", "-b:a", "16k"], "ogg")):
    out = f"call.{name.split()[0]}{name.split()[1]}.{ext}"
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", "media/call-1042.wav", *args, out], check=True)
    size = os.path.getsize(out)
    with open(out, "rb") as f:
        heard = OpenAI(base_url="http://localhost:8700/v1").audio.transcriptions.create(
            model="whisper-base", file=f, response_format="text")
    wer = jiwer.wer(truth, heard, reference_transform=norm, hypothesis_transform=norm)
    print("%-24s %9d %10.0f %5.1f%%" % (name, size, LIMIT / size * seconds / 60, 100 * wer))
```

```
ana@lab:~/mm$ python audio_sizes.py
encoding                     bytes   min/25MB    WER
wav 16 kHz 16-bit          1772350         14  12.6%
mp3 64 kbit/s               444141         54  14.6%
mp3 32 kbit/s               222129        109  13.9%
opus 16 kbit/s              120226        201  14.6%
```

Os bytes caem quase 15 vezes do WAV para o Opus, e por isso os **minutos que cabem nos 25 MB da OpenAI** sobem de 14 para 201. O WAV é o formato com que a aula 10 bateu no limite; um MP3 a 32 kbit/s guarda uma hora e três quartos num só pedido, o que cobre a maioria das ligações sem cortá-las em pedaços.

A taxa de erro foi de 12,6% para algo entre 13,9% e 14,6%. Numa ligação de 151 palavras, isso são três ou quatro palavras, o mesmo tamanho de diferença que a aula 11 se recusou a chamar de resultado. O que ela diz é que **a compressão não quebrou a transcrição**, e uma loja que quer saber se 16 kbit/s lhe custa precisão roda a comparação no conjunto de teste da aula 7, não numa ligação.

Vídeo é a mesma história contada em quadros. A aula 4 mandou alguns quadros em vez do arquivo, e o custo foram os tokens dos quadros; quantos quadros por segundo um provedor amostra, e em que tamanho, é regra dele e muda a conta do mesmo jeito que a regra de blocos.
