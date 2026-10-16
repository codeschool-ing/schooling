---
title: Variação aleatória
version: 1
---

O recuo sozinho tem uma falha que só aparece com muitos chamadores. Suponha que o payments pare por
um momento e mil vendas falhem juntas. Com recuo exponencial puro, cada uma delas espera exatamente
200 ms e tenta de novo, todas no mesmo instante; falha de novo, espera exatamente 400 ms, e tenta de
novo junto com as outras. Os chamadores não espalharam nada: eles marcaram uma série de picos
sincronizados, cada um do tamanho da falha original, e um serviço tentando se recuperar encontra mil
pedidos no mesmo milissegundo, uma vez atrás da outra.

A **variação aleatória** (*jitter*) torna cada espera aleatória. Com **variação total** (*full
jitter*), a escolha da bilheteria, a espera é um número aleatório uniforme entre zero e o teto
exponencial, então as novas tentativas se espalham pelo intervalo inteiro em vez de cair no fim dele.
Este programa simula os mil chamadores dos dois jeitos e conta onde caem as novas tentativas. Salve-o
como `storm.py`:

```python
# storm.py
"""A thousand clients see the same failure at the same moment, and each retries
four times with exponential backoff. Where do the retries land, with and
without jitter? Every attempt fails, as it would while a service is down."""
import random

CLIENTS, BASE, CAP = 1000, 0.1, 2.0
random.seed(1)


def retries(jitter):
    times = []
    for _ in range(CLIENTS):
        t = 0.0
        for attempt in range(1, 5):
            ceiling = min(CAP, BASE * 2 ** attempt)
            t += random.uniform(0, ceiling) if jitter else ceiling
            times.append(t)
    return times


for jitter in (False, True):
    times = retries(jitter)
    fine = [0] * 320
    for t in times:
        fine[min(int(t * 100), 319)] += 1
    print("full jitter" if jitter else "no jitter",
          f"- at most {max(fine)} retries in any 10 ms")
    for start in range(0, 320, 20):
        n = sum(fine[start:start + 20])
        print(f"  {start / 100:3.1f} s {n:5}  " + "#" * round(n / 25))
```

Ele só precisa do Python:

```
ana@lab:~/tickets$ python3 storm.py
no jitter - at most 1000 retries in any 10 ms
  0.0 s     0  
  0.2 s  1000  ########################################
  0.4 s     0  
  0.6 s  1000  ########################################
  0.8 s     0  
  1.0 s     0  
  1.2 s     0  
  1.4 s  1000  ########################################
  1.6 s     0  
  1.8 s     0  
  2.0 s     0  
  2.2 s     0  
  2.4 s     0  
  2.6 s     0  
  2.8 s     0  
  3.0 s  1000  ########################################
full jitter - at most 85 retries in any 10 ms
  0.0 s  1267  ###################################################
  0.2 s   639  ##########################
  0.4 s   511  ####################
  0.6 s   291  ############
  0.8 s   321  #############
  1.0 s   266  ###########
  1.2 s   168  #######
  1.4 s   109  ####
  1.6 s   105  ####
  1.8 s   127  #####
  2.0 s    81  ###
  2.2 s    69  ###
  2.4 s    35  #
  2.6 s    11  
  2.8 s     0  
  3.0 s     0  
```

**Sem variação, todas as mil novas tentativas de cada rodada caem nos mesmos 10 ms**, quatro vezes.
Com variação total, o máximo que cai em quaisquer 10 ms é 85, e as rodadas se fundem numa só rampa
que desce: as novas tentativas chegam no ritmo em que iam chegar de qualquer jeito, só que não todas
de uma vez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas linhas do tempo de novas tentativas ao longo de três segundos. Em cima, sem variação: quatro picos altos em 0,2, 0,6, 1,4 e 3,0 segundos, cada um com todas as mil tentativas de uma rodada. Embaixo, com variação total: as mesmas quatro mil tentativas espalhadas numa rampa que é mais alta no começo e vai caindo, sem nenhum pico.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">sem variação</text><path d=\"M120 90 L680 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"152.0\" y=\"20\" width=\"6\" height=\"70\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"222.0\" y=\"20\" width=\"6\" height=\"70\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"362.0\" y=\"20\" width=\"6\" height=\"70\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"642.0\" y=\"20\" width=\"6\" height=\"70\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">variação total</text><path d=\"M120 190 L680 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"122.0\" y=\"165.0\" width=\"31.0\" height=\"25.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"157.0\" y=\"177.39147592738752\" width=\"31.0\" height=\"12.60852407261247\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"192.0\" y=\"179.91712707182322\" width=\"31.0\" height=\"10.082872928176796\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"227.0\" y=\"184.25808997632203\" width=\"31.0\" height=\"5.741910023677979\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"262.0\" y=\"183.6661404893449\" width=\"31.0\" height=\"6.33385951065509\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"297.0\" y=\"184.75138121546962\" width=\"31.0\" height=\"5.248618784530387\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"332.0\" y=\"186.68508287292818\" width=\"31.0\" height=\"3.314917127071823\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"367.0\" y=\"187.8492501973165\" width=\"31.0\" height=\"2.1507498026835044\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"402.0\" y=\"187.9281767955801\" width=\"31.0\" height=\"2.071823204419889\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"437.0\" y=\"187.49408050513023\" width=\"31.0\" height=\"2.505919494869771\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"472.0\" y=\"188.4017363851618\" width=\"31.0\" height=\"1.5982636148382006\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"507.0\" y=\"188.63851617995263\" width=\"31.0\" height=\"1.361483820047356\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"542.0\" y=\"189.30939226519337\" width=\"31.0\" height=\"0.6906077348066298\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"577.0\" y=\"189.78295185477506\" width=\"31.0\" height=\"0.2170481452249408\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"295.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 s</text><text x=\"470.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2 s</text><text x=\"645.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3 s</text><text x=\"680\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">1000 em 10 ms</text><text x=\"680\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">no máximo 85 em 10 ms</text></svg>", "caption": "As mesmas tentativas, sincronizadas e espalhadas."}
```

Há outras formas. A *variação igual* (*equal jitter*) espera metade do teto mais uma metade
aleatória, então nenhuma espera é muito curta; a *variação descorrelacionada* (*decorrelated
jitter*) baseia cada espera na anterior em vez do número da tentativa. Elas diferem nos detalhes e
concordam no ponto: **qualquer aleatoriedade quebra a sincronia**, e a sincronia é o que transforma
um soluço numa queda.

O mesmo erro aparece longe das novas tentativas: tarefas do cron que toda máquina começa à
meia-noite, caches que expiram todos na hora cheia, clientes que se reconectam todos quando um
servidor reinicia. Onde muitos chamadores reagem a um mesmo evento, um pouco de aleatoriedade em
quando reagem é uma proteção barata.
