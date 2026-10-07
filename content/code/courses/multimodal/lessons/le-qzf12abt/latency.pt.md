---
title: O silêncio antes da primeira palavra
version: 1
---

Numa linha telefônica, uma resposta que leva dois segundos para começar soa como ligação caída. **Latência em fala é o tempo até o primeiro som**, não o tempo para fazer tudo, e os dois são números muito diferentes:

```python
"""How long a caller waits before the first word: the whole reply at once, or sentence by sentence."""
import re
import time

import mmlab

REPLY = ("Your order M, one zero four two, was delivered on the twenty-fourth of September. "
         "It can be returned until the twenty-fourth of October, free of charge. "
         "We will e-mail you a prepaid label in the next few minutes. "
         "Print it, tape it over the old address, and drop the parcel at any post office. "
         "Your refund of 34 reais and 80 centavos will reach your card once the parcel arrives.")
tts = mmlab.piper("en_US-lessac-medium")
tts.generate("Warm up.", sid=0, speed=1.0)            # the first call pays for loading; leave it out

started = time.time()
whole = tts.generate(REPLY, sid=0, speed=1.0)
wait = time.time() - started
audio = len(whole.samples) / whole.sample_rate
print(f"all at once:     first sound after {wait:.2f} s, {audio:.1f} s of speech, real-time factor {wait / audio:.3f}")

sentences = re.split(r"(?<=\.) ", REPLY)
started = time.time()
first = tts.generate(sentences[0], sid=0, speed=1.0)
print(f"one sentence:    first sound after {time.time() - started:.2f} s, "
      f"{len(first.samples) / first.sample_rate:.1f} s of speech to play while the next {len(sentences) - 1} are made")
```

```
ana@lab:~/mm$ python latency.py
all at once:     first sound after 0.99 s, 18.4 s of speech, real-time factor 0.054
one sentence:    first sound after 0.20 s, 4.0 s of speech to play while the next 4 are made
```

Feita de uma vez, a resposta de cinco frases leva **0,99 segundo** antes que algo possa tocar, para 18,4 segundos de fala. O **fator de tempo real** é 0,054: o Piper faz fala dezoito vezes mais rápido do que ela toca, o que é de sobra. E mesmo assim quem ligou espera um segundo em silêncio.

Feita uma frase por vez, a primeira frase fica pronta em **0,20 segundo** e toca por 4,0 segundos, e as quatro seguintes são feitas enquanto ela toca. Enquanto cada frase for feita mais rápido do que a anterior toca, o que um fator de tempo real de 0,054 garante com folga, quem ligou nunca mais ouve um silêncio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Duas linhas do tempo a partir do momento em que a resposta está pronta. Tudo de uma vez: quem ligou não ouve nada por 0,99 segundo enquanto os 18,4 segundos de resposta são sintetizados, e depois ouve. Frase por frase: a primeira frase fica pronta em 0,20 segundo e toca por 4,0 segundos, e as outras quatro são feitas enquanto ela toca.\"><text x=\"20\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tudo de uma vez</text><rect x=\"180\" y=\"32\" width=\"23.76\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"209.76\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">silêncio: 0,99 s</text><rect x=\"203.76\" y=\"32\" width=\"441.6000000000001\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"324\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">fala</text><text x=\"20\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">frase por frase</text><rect x=\"180\" y=\"92\" width=\"4.8\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"184.8\" y=\"92\" width=\"96.0\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"232.8\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">frase 1</text><rect x=\"280.8\" y=\"92\" width=\"419.2\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"290.8\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">frases 2 a 5, feitas enquanto a 1 toca</text><text x=\"180\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 s</text><text x=\"300\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 s</text><text x=\"420\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10 s</text><text x=\"540\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15 s</text><text x=\"660\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 s</text><text x=\"20\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">O trabalho total é o mesmo. O que quem liga percebe é o primeiro silêncio.</text></svg>", "caption": "Fazer em partes não deixa a síntese mais rápida; leva a espera para onde ninguém a ouve."}
```

## De onde vem o resto da espera

A voz costuma ser a menor parte da latência de uma resposta falada. Numa cascata (aula 1), quem liga espera o transcritor decidir que a pessoa terminou de falar, depois o modelo de linguagem escrever a resposta, depois a voz. Cada etapa pode passar adiante aos poucos:

- a resposta do modelo de linguagem chega **token a token**, então a primeira frase pode ir para a voz assim que o ponto final dela chega;
- a voz pode começar essa frase enquanto o modelo escreve a segunda;
- APIs de TTS hospedadas devolvem o áudio **como um fluxo** de pedaços, então dá para começar a tocar antes de o arquivo estar completo.

A regra que une tudo é a do `latency.py`: **corte nas fronteiras das frases e passe cada pedaço adiante assim que ele existir**. Cortar mais fino que uma frase quebra a entonação, já que a voz precisa ver o ponto final para saber que a frase está terminando (seção 05).

A aula 13 acrescenta a rede a essa conta. Uma voz hospedada é mais rápida por frase do que um notebook e acrescenta uma ida e volta por pedido; uma voz local como o Piper não acrescenta rede e precisa de uma máquina para rodar. As duas são escolhas honestas, e a medida acima é o jeito de fazê-la.
