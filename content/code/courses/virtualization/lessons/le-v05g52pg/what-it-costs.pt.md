---
title: Quanto custa a ajuda que falta
version: 1
---

O mesmo programa pequeno, um laço que soma três milhões de quadrados em Python, cronometrado duas
vezes no host e duas vezes dentro da vm1:

```
ana@host:~$ time python3 -c "sum(i * i for i in range(3000000))"

real    0m0.122s
user    0m0.115s
sys     0m0.000s
ana@vm1:~$ time python3 -c "sum(i * i for i in range(3000000))"

real    0m3.050s
user    0m2.985s
sys     0m0.060s
ana@host:~$ time python3 -c "sum(i * i for i in range(3000000))"

real    0m0.131s
user    0m0.130s
sys     0m0.000s
ana@vm1:~$ time python3 -c "sum(i * i for i in range(3000000))"

real    0m2.930s
user    0m2.867s
sys     0m0.062s
```

`real` é o tempo no relógio. No host o laço levou 0,122 e 0,131 segundos; dentro da
vm1, 3,050 e 2,930. **O convidado foi entre 22 e 25 vezes mais lento**, num laço
que não toca disco nem rede, só o processador.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"O mesmo laço em Python, cronometrado duas vezes de cada lado, em barras. No host levou 0,122 e 0,131 segundos. Dentro da vm1 levou 3,050 e 2,930 segundos, entre 22 e 25 vezes mais.\"><defs><marker id=\"sp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no host, execução 1</text><rect x=\"180\" y=\"20\" width=\"17.6\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"207.6\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,122 s</text><text x=\"20\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dentro da vm1, execução 1</text><rect x=\"180\" y=\"64\" width=\"440.0\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"630.0\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3,050 s</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no host, execução 2</text><rect x=\"180\" y=\"108\" width=\"18.898360655737708\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"208.89836065573772\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,131 s</text><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dentro da vm1, execução 2</text><rect x=\"180\" y=\"152\" width=\"422.688524590164\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"612.688524590164\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2,930 s</text></svg>", "caption": "Entre 22 e 25 vezes mais lento, num laço que só usa o processador. É o preço de um processador imitado em software, e é o que o VT-x ou o AMD-V poupam."}
```

É o custo de um processador imitado em software, e é o motivo de o laboratório deste curso ser
paciente e espera cada convidado dar boot. Com VT-x ou AMD-V, as instruções do
convidado rodam no processador de verdade e um laço como este roda perto da velocidade do host; o que
continua mais lento é tudo o que passa por um dispositivo imitado, que a aula 8 examina.

Se uma máquina virtual no computador de alguém está lenta de um jeito insuportável, **descubra se a
ajuda do processador está chegando ao hypervisor** antes de qualquer outra coisa. É a maior diferença
que existe, e costuma ser uma configuração.
