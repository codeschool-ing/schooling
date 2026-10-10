---
title: Por que nada deveria rodar a 100%
version: 1
---

A lei de Little diz quantos pedidos estão dentro; ela não diz quanto eles esperam, e isso depende do
quão ocupado o servidor está. Um servidor 50% ocupado fica parado metade do tempo, então um pedido que
chega costuma encontrá-lo livre. A 95% ele quase nunca está livre, e todo pedido espera atrás dos
anteriores.

Este programa simula um servidor que leva 10 ms por pedido em média, com pedidos chegando ao acaso,
numa fração crescente do que ele consegue fazer. Salve-o como `queueing.py`:

```python
# queueing.py
"""One server that takes 10 ms a request on average, and requests arriving at
random, at a rising share of what it can do. How long does a request spend,
waiting plus being served?"""
import random

SERVICE = 0.010          # seconds of work per request, on average
REQUESTS = 200_000
random.seed(1)

print("busy   mean ms   p99 ms   formula ms")
for busy in (0.5, 0.7, 0.8, 0.9, 0.95):
    arrival_rate = busy / SERVICE              # requests per second
    clock = free_at = 0.0
    times = []
    for _ in range(REQUESTS):
        clock += random.expovariate(arrival_rate)        # the next arrival
        start = max(clock, free_at)                      # waits if the server is busy
        free_at = start + random.expovariate(1 / SERVICE)
        times.append(free_at - clock)
    times.sort()
    mean = sum(times) / len(times)
    print(f"{busy:4.0%}  {mean * 1000:8.1f}  {times[int(0.99 * len(times))] * 1000:7.1f}"
          f"  {SERVICE / (1 - busy) * 1000:11.1f}")
```

```
ana@lab:~/tickets$ python3 queueing.py
busy   mean ms   p99 ms   formula ms
 50%      20.0     91.8         20.0
 70%      33.6    154.2         33.3
 80%      50.8    235.6         50.0
 90%      96.3    437.0        100.0
 95%     176.1    966.2        200.0
```

A 50% de ocupação, um pedido de 10 ms leva 20 ms em média. A 80%, 51 ms; a 90%, 96 ms; a 95%, 176 ms
em média e quase um segundo no percentil 99. A coluna da direita é a fórmula clássica para esse tipo
de fila, a M/M/1: **tempo = tempo de serviço ÷ (1 − utilização)**. A simulação a acompanha de perto e
fica um pouco abaixo a 95%, onde a fila é tão longa que nem 200.000 pedidos bastam para ver os piores
momentos dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Uma curva do tempo médio contra o quão ocupado o servidor está, para um pedido que leva 10 ms de trabalho. Ela fica baixa e quase plana até uns 70 por cento, em 33 ms, e então sobe forte: 50 ms em 80 por cento, 100 ms em 90 por cento e 200 ms em 95 por cento. Uma faixa de 60 a 70 por cento está marcada como a meta de planejamento.\"><path d=\"M440.0 220 L440.0 30.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M500.0 220 L500.0 30.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"470.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">planeje aqui</text><path d=\"M80 220 L680 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 220 L80 30\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M 80.0 210.5 L 86.0 210.4 L 92.0 210.3 L 98.0 210.2 L 104.0 210.1 L 110.0 210.0 L 116.0 209.9 L 122.0 209.8 L 128.0 209.7 L 134.0 209.6 L 140.0 209.4 L 146.0 209.3 L 152.0 209.2 L 158.0 209.1 L 164.0 209.0 L 170.0 208.8 L 176.0 208.7 L 182.0 208.6 L 188.0 208.4 L 194.0 208.3 L 200.0 208.1 L 206.0 208.0 L 212.0 207.8 L 218.0 207.7 L 224.0 207.5 L 230.0 207.3 L 236.0 207.2 L 242.0 207.0 L 248.0 206.8 L 254.0 206.6 L 260.0 206.4 L 266.0 206.2 L 272.0 206.0 L 278.0 205.8 L 284.0 205.6 L 290.0 205.4 L 296.0 205.2 L 302.0 204.9 L 308.0 204.7 L 314.0 204.4 L 320.0 204.2 L 326.0 203.9 L 332.0 203.6 L 338.0 203.3 L 344.0 203.0 L 350.0 202.7 L 356.0 202.4 L 362.0 202.1 L 368.0 201.7 L 374.0 201.4 L 380.0 201.0 L 386.0 200.6 L 392.0 200.2 L 398.0 199.8 L 404.0 199.3 L 410.0 198.9 L 416.0 198.4 L 422.0 197.9 L 428.0 197.4 L 434.0 196.8 L 440.0 196.2 L 446.0 195.6 L 452.0 195.0 L 458.0 194.3 L 464.0 193.6 L 470.0 192.9 L 476.0 192.1 L 482.0 191.2 L 488.0 190.3 L 494.0 189.4 L 500.0 188.3 L 506.0 187.2 L 512.0 186.1 L 518.0 184.8 L 524.0 183.5 L 530.0 182.0 L 536.0 180.4 L 542.0 178.7 L 548.0 176.8 L 554.0 174.8 L 560.0 172.5 L 566.0 170.0 L 572.0 167.2 L 578.0 164.1 L 584.0 160.6 L 590.0 156.7 L 596.0 152.1 L 602.0 146.9 L 608.0 140.8 L 614.0 133.6 L 620.0 125.0 L 626.0 114.4 L 632.0 101.2 L 638.0 84.3 L 644.0 61.7 L 650.0 30.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"500.0\" cy=\"188.33333333333334\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"492.0\" y=\"188.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">33 ms</text><circle cx=\"560.0\" cy=\"172.5\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"552.0\" y=\"172.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">50 ms</text><circle cx=\"620.0\" cy=\"124.99999999999999\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"612.0\" y=\"124.99999999999999\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">100 ms</text><circle cx=\"650.0\" cy=\"30.00000000000017\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"642.0\" y=\"30.00000000000017\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">200 ms</text><text x=\"80\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0%</text><text x=\"230.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25%</text><text x=\"380.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50%</text><text x=\"530.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">75%</text><text x=\"680.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><text x=\"70\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"70\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200 ms</text><text x=\"680\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">utilização</text></svg>", "caption": "O tempo cresce com 1 ÷ (1 − utilização): plano, depois vertical."}
```

A curva é o motivo de toda regra de *folga* (*headroom*) no planejamento de capacidade. **A latência
não cresce em proporção à carga; ela cresce com 1 ÷ (1 − utilização)**, que fica plana por muito
tempo e depois vira vertical. Ir de 50% para 70% custa 13 ms; ir de 90% para 95% custa 80. Um sistema
planejado para rodar a 90% no pico não tem espaço para o pico ser um pouco maior que o planejado, e
os picos sempre são.

Servidores reais não são exatamente M/M/1. Os pedidos não chegam completamente ao acaso, os tempos de
serviço não são exponenciais, e uma bilheteria tem várias threads numa CPU. A forma sobrevive a tudo
isso, e as metas comuns vêm dela: **planejar 60 a 70% no pico esperado**, e tratar qualquer coisa
acima de 80% como alarme.
