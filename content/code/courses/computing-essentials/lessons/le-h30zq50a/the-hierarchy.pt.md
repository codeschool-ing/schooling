---
title: Cinco distâncias, e por que todo conselho é sobre uma delas
version: 1
---

Tudo nesta aula até aqui foi uma ideia só, abordada por quatro lados, e esta seção a diz
diretamente.

Um processador não tem um lugar de onde buscar dados. Tem cinco, eles estão arrumados por
distância, e cada passo para fora é **não um pouco mais lento — é uma ordem de grandeza mais
lento ou pior.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"Cinco linhas, da mais perto para a mais longe, cada uma com uma barra que cresce lista abaixo. Registradores, menos de um nanossegundo. Cache, uns cinco nanossegundos. Memória, uns cem nanossegundos. Um disco de estado sólido, uns cem mil nanossegundos. Um disco rígido, uns dez milhões de nanossegundos. Uma terceira coluna dá os mesmos tempos numa escala humana em que um nanossegundo é um segundo: um segundo, cinco segundos, dois minutos, um dia e meio, e quatro meses. Uma nota diz que as barras não estão nem perto da escala e que, em escala, a última teria quatrocentos metros.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Onde um processador pode buscar um dado, do mais perto — e quanto custa a espera.</text><text x=\"14\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">onde</text><text x=\"420\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quanto custa</text><text x=\"706\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">se um nanossegundo fosse um segundo</text><text x=\"14\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">registradores</text><rect x=\"108\" y=\"53\" width=\"6\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">menos de 1 ns</text><text x=\"706\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">um segundo</text><text x=\"14\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cache</text><rect x=\"108\" y=\"87\" width=\"16\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">uns 5 ns</text><text x=\"706\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">cinco segundos</text><text x=\"14\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">memória</text><rect x=\"108\" y=\"121\" width=\"46\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">uns 100 ns</text><text x=\"706\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--amber)\">dois minutos</text><text x=\"14\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SSD</text><rect x=\"108\" y=\"155\" width=\"130\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">uns 100 000 ns</text><text x=\"706\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--amber)\">um dia e meio</text><text x=\"14\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">disco rígido</text><rect x=\"108\" y=\"189\" width=\"280\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">uns 10 000 000 ns</text><text x=\"706\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--amber)\">quatro meses</text><path d=\"M14 226 L706 226\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"14\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">As barras não estão nem perto da escala. Em escala, a última teria quatrocentos metros.</text></svg>", "caption": "A coluna da direita é a que vale guardar. Um processador esperando um disco rígido é uma pessoa esperando quatro meses por uma resposta que precisava num segundo.", "same": ["cache", "SSD"]}
```

A coluna da direita é um truque conhecido e vale o papel em que está impressa. Escale cada
número de modo que **um nanossegundo vire um segundo**, e isso põe estas distâncias num relógio
humano:

- um registrador: **um segundo**
- cache: **cinco segundos**
- memória: **dois minutos** — você iria fazer um café
- um SSD: **um dia e meio**
- um disco rígido: **quatro meses**

Esses não são cinco pontos numa reta. São cinco tipos diferentes de experiência, e todo o ofício
de fazer um computador parecer rápido é manter o trabalho nos dois de cima.

## Cache é a que você ainda não conhecia

Os dois primeiros níveis moram dentro do próprio processador. Os **registradores** são o punhado
de valores que ele está operando neste instante. A **cache** é uma cópia pequena e muito rápida
da memória que ele andou usando — tipicamente alguns megabytes, contra gigabytes de RAM.

Você não gerencia a cache e não compra mais dela em separado. Vale nomeá-la por um motivo: é por
ela que dois processadores de mesmo clock e mesmo número de núcleos podem diferir num terço no
trabalho real. Um tem mais cache, então chega ao nível de dois minutos menos vezes.

## O que isso explica, tudo de uma vez

Cada regra de bolso desta aula agora é a mesma regra:

| o conselho | o que ele diz de verdade |
|---|---|
| feche umas abas | impedir a máquina de cair da *memória* para o *SSD* |
| compre mais RAM | o mesmo, e para valer |
| ponha um SSD | se tiver de cair, cair um dia e meio e não quatro meses |
| mais cache é melhor | cair para a memória menos vezes |

**Ninguém otimiza um computador. As pessoas impedem o trabalho de cair um nível.** É essa a
frase que a aula existe para entregar, e ela vale tanto para um celular ou um servidor quanto
para a máquina na sua frente.
