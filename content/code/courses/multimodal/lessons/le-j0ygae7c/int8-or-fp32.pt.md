---
title: Uma cópia menor do mesmo modelo
version: 1
---

A **quantização** guarda os pesos de um modelo com menos bits. Um modelo em precisão completa guarda cada peso como número de ponto flutuante de 32 bits (**fp32**); uma cópia **int8** guarda a maioria deles como inteiros de 8 bits mais uma escala, mais ou menos um quarto do espaço nas partes quantizadas. A pergunta é sempre a mesma: quanto a cópia menor custa em precisão?

O laboratório tem as duas cópias de cada Whisper, lado a lado:

```
ana@lab:~/mm$ cd /opt/multimodal/share && ls -l sherpa-onnx-whisper-base/*.onnx | awk "{print \$5, \$9}"
130672026 sherpa-onnx-whisper-base/base-decoder.int8.onnx
196548998 sherpa-onnx-whisper-base/base-decoder.onnx
29120534 sherpa-onnx-whisper-base/base-encoder.int8.onnx
95087154 sherpa-onnx-whisper-base/base-encoder.onnx
```

Então a pergunta pode ser medida em vez de discutida:

```python
"""The same Whisper at full precision and at int8: size on disk, time to load, time to transcribe, words wrong."""
import os
import time

import mmlab
from measure import transcript, wer

TRUTH = open("media/truth/call-1042.txt").read()
samples = mmlab.read_audio("media/call-1042.wav")
for size in ("tiny", "base"):
    for int8 in (False, True):
        q = ".int8" if int8 else ""
        d = os.path.join(mmlab.SHARE, f"sherpa-onnx-whisper-{size}")
        mb = sum(os.path.getsize(f"{d}/{size}-{part}{q}.onnx") for part in ("encoder", "decoder")) / 1e6
        started = time.time()
        model = mmlab.whisper(size, language="en", int8=int8)
        loaded = time.time() - started
        started = time.time()
        text, _ = transcript(samples, model)
        ran = time.time() - started
        print(f"{size:4} {'int8' if int8 else 'fp32':4}  {mb:6.1f} MB  load {loaded:4.1f} s  "
              f"transcribe {ran:5.1f} s  WER {wer(TRUTH, text):6.1%}")
```

```
ana@lab:~/mm$ python precision.py
tiny fp32   152.2 MB  load  1.2 s  transcribe   7.5 s  WER  17.2%
tiny int8   102.8 MB  load  0.5 s  transcribe   7.1 s  WER  16.6%
base fp32   291.6 MB  load  2.6 s  transcribe  13.9 s  WER  11.9%
base int8   159.8 MB  load  1.1 s  transcribe  11.2 s  WER  12.6%
```

**Nesta ligação, o int8 não custou nada mensurável.** O tiny int8 fez 16,6% contra 17,2% do fp32, e o base int8 12,6% contra 11,9%. Um subiu e outro desceu, menos de uma palavra em cem, em 151 palavras de fala: isso é o ruído de uma gravação só, não uma diferença entre as cópias. O que o int8 comprou é claro: **o base com 160 MB em vez de 292**, carregado em 1,1 segundo em vez de 2,6, e transcrevendo em 11,2 segundos em vez de 13,9.

Os tamanhos não caíram bem a um quarto, porque nem toda parte de um modelo é quantizada. Os codificadores encolheram umas três vezes; os decodificadores bem menos, já que uma grande parte de um decodificador do Whisper é a tabela de vocabulário, que esta exportação mantém com mais precisão.

Dois cuidados impedem que isto vire regra:

- **Uma ligação não é um conjunto de teste.** O conselho da aula 7 vale: rode as duas cópias nas gravações que importam antes de escolher. Os erros de quantização costumam aparecer nos casos difíceis, como sotaques, ruído e nomes, e uma ligação de 151 palavras tem poucos deles.
- **Nem todo modelo se quantiza tão bem.** Modelos pequenos e geradores de imagem podem perder visivelmente em int8; alguns formatos vão além (4 bits) e perdem mais. A medida acima é o método; o resultado é deste modelo.

Para um laboratório, um notebook ou um celular, a cópia int8 é o ponto de partida que vale, e este laboratório a usa em todo lugar pelo `mmlab.whisper`.
