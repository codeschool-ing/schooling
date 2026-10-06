---
title: Quando o roteiro existe, as palavras vêm dele
version: 1
---

O reconhecimento é a ferramenta certa para uma gravação que ninguém escreveu antes: uma ligação, uma entrevista, uma reunião. O vídeo de devoluções não é uma delas. Alguém escreveu a narração antes de uma voz falá-la, e o `media/truth/returns.json` guarda esse roteiro. **Quando o roteiro existe, as palavras reconhecidas são uma cópia pior dele**, e a parte útil do reconhecimento são só os tempos.

```python
"""Timings from recognition, words from the script: each segment takes the script line it is closest to."""
import json

import jiwer
from cues import stamp

said = [s["said"] for s in json.load(open("media/truth/returns.json"))["slides"] if s["said"]]
heard = json.load(open("recognised.json"))

print("recognised against the script: WER %.1f%%" % (100 * jiwer.wer(" ".join(said).lower(), " ".join(t for _, _, t in heard).lower())))
for start, end, text in heard:
    line = min(said, key=lambda s: jiwer.cer(s.lower(), text.lower()))
    print("%s  cer %4.1f%%  %s" % (stamp(start)[3:], 100 * jiwer.cer(line.lower(), text.lower()), line[:52]))
```

```
ana@lab:~/mm$ python script_captions.py
recognised against the script: WER 13.7%
00:00.420  cer  2.0%  Here is how to return a book you bought from Margina
00:06.340  cer  4.2%  First, sign in and open the order the book came in. 
00:12.040  cer  0.0%  Second, press Return this item and choose a reason f
00:16.100  cer  4.6%  Third, print the prepaid label we send you by e-mail
00:21.830  cer  9.9%  Fourth, drop the parcel at any post office, and keep
00:26.890  cer  7.2%  Refunds go back to the card you paid with. A damaged
```

O texto reconhecido tem 13,7% de erro contra o roteiro. Casado segmento por segmento, cada um acha a sua linha do roteiro com taxa de erro de caracteres entre 0% e 9,9%, então o casamento não deixa dúvida, e as legendas pegam **as palavras do roteiro com os tempos do reconhecedor**. "Marginalia", "sign in" e "Fourth," voltam; a velocidade de leitura continua alta, porque as palavras nunca foram o motivo dela.

É assim que esta plataforma trata os próprios vídeos. O `docs/VIDEO.md` faz do roteiro falado uma fonte escrita por autores, guardada em `content/` ao lado da prosa, e a transcrição que um aluno lê **é** esse roteiro. Nas palavras dele, "chamar o roteiro de transcrição é uma afirmação sobre o vídeo", e se uma versão renderizada se afasta dele, é o roteiro que se corrige. Um curso escrito desse jeito tem o texto das legendas antes de o vídeo existir. O que ainda falta são os tempos, a metade que um reconhecedor faz bem.
