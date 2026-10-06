---
title: Um modelo maior, e o que ele compra
version: 1
---

O Whisper vem em tamanhos, do *tiny* (39 milhões de parâmetros) passando por *base*, *small*, *medium* e *large*, e o laboratório tem os dois menores. Os dois, nas três gravações da ligação da aula 5:

```python
"""Whisper tiny and base on three versions of the call: errors by kind, and the time each took."""
import time

import jiwer

import mmlab
from measure import transcript, words

TRUTH = words(open("media/truth/call-1042.txt").read())
for size in ("tiny", "base"):
    whisper = mmlab.whisper(size, language="en")
    for name in ("call-1042", "call-1042-phone", "call-1042-noisy"):
        started = time.time()
        text, _ = transcript(mmlab.read_audio(f"media/{name}.wav"), whisper)
        took = time.time() - started
        o = jiwer.process_words(TRUTH, words(text))
        print(f"{size:4} {name:16} WER {o.wer:6.1%}  substituted {o.substitutions:2}  deleted {o.deletions:2}  "
              f"inserted {o.insertions:2}  {took:4.1f} s")
```

```
ana@lab:~/mm$ python score.py
tiny call-1042        WER  16.6%  substituted 15  deleted  7  inserted  3   6.7 s
tiny call-1042-phone  WER  13.2%  substituted 16  deleted  2  inserted  2   6.7 s
tiny call-1042-noisy  WER  20.5%  substituted 21  deleted  4  inserted  6   7.2 s
base call-1042        WER  12.6%  substituted 12  deleted  6  inserted  1  11.2 s
base call-1042-phone  WER  11.9%  substituted 14  deleted  3  inserted  1  10.8 s
base call-1042-noisy  WER  20.5%  substituted 14  deleted 17  inserted  0  11.6 s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Barras em par com a taxa de erro de palavras do Whisper tiny e do Whisper base em três gravações da mesma ligação. Limpa: tiny 16,6%, base 12,6%. Linha telefônica: tiny 13,2%, base 11,9%. Ruidosa: tiny 20,5%, base 20,5%. O base é melhor na limpa e na de telefone e não é melhor na ruidosa.\"><line x1=\"60\" y1=\"190\" x2=\"640\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"110\" y=\"90.4\" width=\"44\" height=\"99.6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"132\" y=\"81.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">16,6%</text><rect x=\"160\" y=\"114.4\" width=\"44\" height=\"75.6\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"182\" y=\"105.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">12,6%</text><text x=\"157\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">limpa</text><rect x=\"290\" y=\"110.8\" width=\"44\" height=\"79.2\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"312\" y=\"101.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">13,2%</text><rect x=\"340\" y=\"118.6\" width=\"44\" height=\"71.4\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"362\" y=\"109.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">11,9%</text><text x=\"337\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">telefone</text><rect x=\"470\" y=\"67.0\" width=\"44\" height=\"123.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"492\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">20,5%</text><rect x=\"520\" y=\"67.0\" width=\"44\" height=\"123.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"542\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">20,5%</text><text x=\"517\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ruidosa</text><rect x=\"480\" y=\"12\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"498\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tiny</text><rect x=\"560\" y=\"12\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"578\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">base</text><text x=\"20\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Taxa de erro de palavras contra o roteiro; menor é melhor.</text></svg>", "caption": "O modelo maior ajuda onde o áudio é bom e deixa de ajudar onde o problema é o áudio."}
```

Quatro achados, e o último é o que importa.

**O base é melhor onde o áudio é bom**: 12,6% contra 16,6% na ligação limpa. Fez menos substituições (12 contra 15) e menos remoções.

**A linha telefônica quase não custou nada.** O base fez 11,9% na versão de telefone, um pouco melhor que na limpa. Isso está dentro do ruído de uma única ligação de 151 palavras, e confirma a aula 5: a fala sobrevive à faixa do telefone.

**O base é mais lento**: uns 11 segundos para a ligação contra uns 7 do tiny, em quatro núcleos de processador. Os dois são mais rápidos que o tempo real (a ligação tem 55 segundos), e os dois tempos incluem o detector de fala.

**Na ligação ruidosa, os dois fizeram 20,5%.** O modelo maior não comprou nada, e o jeito como o base falhou diz muito: 17 remoções e nenhuma inserção, onde o tiny fez 4 remoções e 6 inserções. O base, diante do ruído, disse menos; o tiny chutou mais. A mesma nota esconde dois comportamentos diferentes, e qual você prefere depende de se uma palavra faltando ou uma inventada faz mais estrago lá na frente.

**Um modelo maior não é a primeira correção para áudio ruim.** O filtro da aula 5 levou a ligação ruidosa de 20,5% para 13,2% com o mesmo modelo base. A ordem de ataque é: a gravação primeiro, a limpeza segundo, o modelo terceiro.

## Escolhendo um tamanho

| se | então |
|---|---|
| a transcrição alimenta um índice de busca ou um resumo | o menor modelo cujo WER for aceitável no seu áudio; a etapa seguinte perdoa erros pequenos |
| ela é mostrada às pessoas como legenda | o maior modelo que você puder pagar, porque todo erro aparece na tela (aula 14) |
| ela precisa rodar no aparelho ou em tempo real | tiny ou base, medidos naquele aparelho |
| ela passa por uma API hospedada | o modelo do provedor; a aula 10 manda a mesma ligação ao Whisper do labmm no formato da API da OpenAI |
