---
title: Medindo o ruído
version: 1
---

**Ruído é tudo na gravação que não é o sinal que você quer.** Antes de tirá-lo, meça: quão alto ele é contra a fala, e onde no espectro ele está. As duas coisas decidem o que vai funcionar.

O laboratório consegue medir com exatidão, porque tem a ligação limpa e a ruidosa, e o ruído é simplesmente a diferença entre as duas:

```python
"""How loud the noise is against the voices, and where in the spectrum it sits."""
import numpy as np

import mmlab

clean = mmlab.read_audio("media/call-1042.wav")
noise = mmlab.read_audio("media/call-1042-noisy.wav") - clean
db = lambda x: 10 * np.log10((x ** 2).mean())
print(f"signal-to-noise ratio: {db(clean) - db(noise):.1f} dB")

freqs = np.fft.rfftfreq(len(clean), 1 / mmlab.RATE)
for name, x in (("voices", clean), ("noise", noise)):
    power = np.abs(np.fft.rfft(x)) ** 2
    bands = [(0, 100), (100, 300), (300, 1000), (1000, 3400), (3400, 8000)]
    share = [power[(freqs >= a) & (freqs < b)].sum() / power.sum() for a, b in bands]
    print(f"{name:7}", "  ".join(f"{a}-{b} Hz {s:5.1%}" for (a, b), s in zip(bands, share)))
print(f"loudest single frequency in the noise: {freqs[np.argmax(np.abs(np.fft.rfft(noise)))]:.0f} Hz")
```

```
ana@lab:~/mm$ python noise.py
signal-to-noise ratio: 4.9 dB
voices  0-100 Hz 11.0%  100-300 Hz 51.7%  300-1000 Hz 25.2%  1000-3400 Hz  9.0%  3400-8000 Hz  3.1%
noise   0-100 Hz 54.2%  100-300 Hz 11.5%  300-1000 Hz 12.6%  1000-3400 Hz 12.7%  3400-8000 Hz  8.9%
loudest single frequency in the noise: 60 Hz
```

**A relação sinal-ruído (SNR) é de 4,9 dB**: as vozes carregam umas três vezes a potência do ruído (10^0,49 ≈ 3,1). Para comparar, uma gravação num escritório silencioso costuma passar de 30 dB, e uma ligação de dentro de um carro ou da rua pode cair para 10 dB ou menos. 4,9 dB é uma linha ruim, e foi construída para ser.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Barras em par para cinco faixas de frequência, mostrando que parte da energia cada um dos dois sons tem na faixa. Abaixo de 100 Hz: vozes 11,0%, ruído 54,2%. De 100 a 300 Hz: vozes 51,7%, ruído 11,5%. De 300 a 1000 Hz: vozes 25,2%, ruído 12,6%. De 1000 a 3400 Hz: vozes 9,0%, ruído 12,7%. De 3400 a 8000 Hz: vozes 3,1%, ruído 8,9%. Metade do ruído está abaixo de 100 Hz, onde as vozes têm pouco.\"><line x1=\"60\" y1=\"190\" x2=\"700\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"90\" y=\"162.5\" width=\"30\" height=\"27.5\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"105\" y=\"153.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">11,0%</text><rect x=\"124\" y=\"54.5\" width=\"30\" height=\"135.5\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"139\" y=\"45.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">54,2%</text><text x=\"122\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0-100</text><rect x=\"215\" y=\"60.75\" width=\"30\" height=\"129.25\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"230\" y=\"51.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">51,7%</text><rect x=\"249\" y=\"161.25\" width=\"30\" height=\"28.75\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"264\" y=\"152.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">11,5%</text><text x=\"247\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">100-300</text><rect x=\"340\" y=\"127.0\" width=\"30\" height=\"63.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"355\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">25,2%</text><rect x=\"374\" y=\"158.5\" width=\"30\" height=\"31.5\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"389\" y=\"149.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">12,6%</text><text x=\"372\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">300-1000</text><rect x=\"465\" y=\"167.5\" width=\"30\" height=\"22.5\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"480\" y=\"158.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">9,0%</text><rect x=\"499\" y=\"158.25\" width=\"30\" height=\"31.75\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"149.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">12,7%</text><text x=\"497\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1000-3400</text><rect x=\"590\" y=\"182.25\" width=\"30\" height=\"7.75\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"605\" y=\"173.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">3,1%</text><rect x=\"624\" y=\"167.75\" width=\"30\" height=\"22.25\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"639\" y=\"158.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">8,9%</text><text x=\"622\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3400-8000</text><text x=\"380\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Hz</text><rect x=\"470\" y=\"12\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"488\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vozes</text><rect x=\"570\" y=\"12\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"588\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ruído</text></svg>", "caption": "Onde o ruído mora decide como ele pode ser tirado: um zumbido abaixo de 100 Hz pode ser cortado, um chiado na faixa das próprias vozes não."}
```

**Onde o ruído mora é o número mais útil.** Mais da metade dele, 54,2%, está abaixo de 100 Hz, e a frequência isolada mais alta é exatamente 60 Hz: esse é o zumbido, o tipo que a rede elétrica deixa num microfone barato num país cuja rede funciona a 60 Hz, como a do Brasil. As vozes têm 11,0% da energia ali embaixo. O resto do ruído é um chiado espalhado por todas as faixas, incluindo de 100 a 3.400 Hz, onde as vozes carregam 85,9% da sua.

Essa divisão é toda a estratégia da próxima seção numa frase. **Um ruído fora da faixa da fala pode ser cortado com um filtro; um ruído dentro dela não pode**, porque qualquer filtro que o tire leva as vozes junto. Esse segundo tipo precisa de algo que saiba como a fala soa.

Num produto real a gravação limpa não existe, então o ruído é medido nos intervalos: um trecho que o detector de fala diz ser silêncio só tem ruído, e o nível e o espectro dele valem pelo ruído que está sob as palavras. Os filtros `astats` e `silencedetect` do ffmpeg fazem isso sem escrever código.
