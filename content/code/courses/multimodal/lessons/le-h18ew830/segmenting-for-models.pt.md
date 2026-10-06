---
title: Cortando áudio longo para um modelo
version: 1
---

Todo modelo de fala tem um pedaço máximo que aceita de uma vez. O do Whisper é de **30 segundos**: o modelo foi treinado com janelas de 30 segundos, e qualquer coisa mais longa precisa ser cortada em pedaços transcritos um após o outro. APIs hospedadas acrescentam os próprios limites, por tamanho de arquivo e não por duração (a aula 10 encontra o de 25 MB).

**Onde você corta decide o que dá errado.** Corte a cada 30 segundos fixos e o corte cai no meio de uma palavra quase metade das vezes; a palavra se divide entre dois pedaços, é mal transcrita nos dois ou se perde de vez. A aula 4 já viu a versão mais branda disso, em que um trecho que começou um instante tarde perdeu a palavra *Fourth*. A regra é **cortar só no silêncio**, e o detector de fala diz onde estão os silêncios:

```python
"""Cut a recording into pieces of at most 30 seconds, and only at a silence."""
import sys

import mmlab

LIMIT = 30.0
samples = mmlab.read_audio(sys.argv[1])
chunks, start, last_end = [], 0.0, 0.0
for s, e in mmlab.speech_segments(samples):
    if e - start > LIMIT and last_end > start:
        cut = (last_end + s) / 2          # the middle of the silence before this stretch
        chunks.append((start, cut))
        start = cut
    last_end = e
chunks.append((start, len(samples) / mmlab.RATE))
for a, b in chunks:
    print(f"{a:6.2f} -> {b:6.2f}  ({b - a:4.1f} s)")
```

```
ana@lab:~/mm$ python chunks.py media/call-1042.wav
  0.00 ->  29.57  (29.6 s)
 29.57 ->  55.38  (25.8 s)
```

Dois pedaços: 29,6 segundos e 25,8 segundos, cortados no meio do intervalo antes do trecho que teria levado o primeiro pedaço além de 30 segundos. Ninguém estava falando em 29,57; o arquivo de verdade tem a fala da Bia terminando em 29,375 e a seguinte do Caio começando em 29,975.

Três refinamentos importam para gravações longas, e cada um troca uma coisa por outra.

**Sobreposição.** Alguns processos dão a cada pedaço um ou dois segundos do anterior, para que uma palavra perto do corte seja ouvida inteira em pelo menos um pedaço, e depois tiram as palavras duplicadas ao juntar. Custa um pouco de transcrição a mais e algum cuidado na junção.

**Contexto entre pedaços.** O Whisper pode receber o texto do pedaço anterior como *prompt*, o que o ajuda a manter nomes e grafia coerentes entre cortes. A exportação ONNX que este laboratório roda não tem como receber um, então isso não é demonstrado aqui; a aula 10 mostra onde a API o aceita.

**Pedaços menores que o limite.** Os próprios trechos do Silero, uma ou duas frases cada, já ficam bem abaixo de 30 segundos, e transcrever cada um sozinho foi o que a aula 4 fez. Pedaços menores dão tempos mais finos e perdem contexto; os pedaços de 30 segundos daqui guardam mais contexto e dão tempos mais grosseiros. Legendas querem o primeiro; um resumo quer o segundo.

Os três modelos desta aula (achar a fala, separar quem fala, cortar em pedaços) costumam rodar nessa ordem, e depois o transcritor das aulas 7 e 10 assume.
