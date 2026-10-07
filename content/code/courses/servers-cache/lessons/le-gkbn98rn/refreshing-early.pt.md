---
title: Atualizando antes de a chave vencer
version: 1
---

Um estouro acontece no instante do vencimento. **Se um leitor atualiza a chave pouco antes desse
instante, o instante nunca chega.** A pergunta é qual leitor, e a resposta que não precisa de lock nem
de coordenação é: aquele que por acaso tirar um número baixo.

A regra se chama **expiração antecipada probabilística**, publicada em 2015 como *XFetch*. Cada leitor,
antes de usar um valor em cache, calcula o tempo que falta e decide, com uma probabilidade que cresce à
medida que o vencimento se aproxima, atualizar agora:

```python
now - delta * beta * math.log(1 - random.random()) >= expiry
```

`delta` é quanto tempo leva uma atualização, que o valor guarda ao lado de si, e `beta`, 1 por padrão,
puxa a decisão para mais cedo quando é maior. O logaritmo de um número entre 0 e 1 é negativo, então
cada leitor finge que é um pouco mais tarde do que é: em geral por uma fração de `delta`, de vez em
quando por várias. Longe do vencimento, ninguém finge tanto. Um segundo antes, alguém finge.

Esta simulação não toca o Redis. Ela roda a regra para uma chave que vence aos 300 segundos, com uma
atualização de 120 milissegundos e uma leitura a cada 10 milissegundos, mil vezes:

```python
import math
import random

random.seed(2026)
EXPIRY, DELTA, GAP = 300.0, 0.12, 0.01  # expires at 300 s; a refresh takes 120 ms; a read every 10 ms


def should_refresh(now, expiry, delta, beta=1.0):
    return now - delta * beta * math.log(1 - random.random()) >= expiry


for beta in (1.0, 2.0):
    early = []
    for trial in range(1000):
        now = EXPIRY - 5
        while not should_refresh(now, EXPIRY, DELTA, beta):
            now += GAP
        early.append(EXPIRY - now)
    early.sort()
    print(f"beta {beta}: median {early[500]:.2f} s before expiry, latest {early[0]:.2f} s before, "
          f"{sum(e <= 0 for e in early)} of 1000 reached expiry")
```

```
ana@web:~/work$ python3 early.py
beta 1.0: median 0.34 s before expiry, latest 0.08 s before, 0 of 1000 reached expiry
beta 2.0: median 0.86 s before expiry, latest 0.29 s before, 0 of 1000 reached expiry
```

**Em 1.000 tentativas, a chave nunca chegou ao vencimento.** Com `beta` 1, a atualização veio um terço
de segundo antes na tentativa típica, e nunca depois de 80 milissegundos antes. Com `beta` 2, mais cedo
ainda. Uma chave movimentada é atualizada pouco antes do vencimento por um leitor; **uma chave quieta pode
simplesmente vencer**, e tudo bem, porque uma chave quieta não tem ninguém para estourar.

A força dela é que cada leitor decide sozinho. A fraqueza é a palavra *probabilística*: dois leitores
podem tirar números baixos juntos e os dois atualizarem, então ela reduz um estouro a poucas consultas,
e não exatamente a uma. Na prática ela costuma ser combinada com a marca de atualização da seção
anterior.
