---
title: Para onde vai a memória
version: 1
---

A aula 1 achou o processo do QEMU da vm1 usando cerca de 1,5 GiB para um convidado que recebeu 1 GiB, e
prometeu descobrir por quê. Eis o mesmo tipo de convidado, com a visão que o host tem da memória dele:

```
ana@host:~$ virsh dommemstat vm1 | grep -E "^(actual|rss)"
actual 1048576
rss 1713460
ana@host:~$ sudo pmap -x $(pgrep -o qemu-system) | awk "NR > 2 && \$3 > 60000"
00007fa353fff000   65672   65552   65552 rw---   [ anon ]
00007fa383e00000 1048576  446464  446464 rw---   [ anon ]
00007fa3c4000000   65532   65532   65532 rwx--   [ anon ]
00007fa3c8000000   65532   65532   65532 rwx--   [ anon ]
00007fa3cc000000   65532   65532   65532 rwx--   [ anon ]
00007fa3d0000000   65532   65532   65532 rwx--   [ anon ]
00007fa3d4000000   65532   65532   65532 rwx--   [ anon ]
00007fa3d8000000   65532   65532   65532 rwx--   [ anon ]
00007fa3dc000000   65532   65532   65532 rwx--   [ anon ]
00007fa3e0000000   65532   65532   65532 rwx--   [ anon ]
00007fa3e4000000   65532   65532   65532 rwx--   [ anon ]
00007fa3e8000000   65532   65532   65532 rwx--   [ anon ]
00007fa3ec000000   65532   65532   65532 rwx--   [ anon ]
00007fa3f0000000   65532   65532   65532 rwx--   [ anon ]
00007fa3f4000000   65532   65532   65532 rwx--   [ anon ]
00007fa3f8000000   65532   65532   65532 rwx--   [ anon ]
00007fa3fc000000   65532   63812   63812 rwx--   [ anon ]
00007fa400000000   65532   65532   65532 rwx--   [ anon ]
total kB         3400460 1713836 1691556
ana@host:~$ sudo pmap -x $(pgrep -o qemu-system) | awk "\$5 == \"rwx--\" { n++; rss += \$3 } END { print n, \"areas of translated code,\", rss, \"KiB resident\" }"
16 areas of translated code, 1046796 KiB resident
```

`actual` é a memória que o convidado recebeu, 1048576 KiB, e `rss` é o que o processo ocupa de fato,
1713460 KiB. O `pmap` lista as áreas de memória do processo, e as que têm mais de 60 MB dizem onde ela
está. A área de exatamente 1048576 KiB é **a memória do convidado**, e só 446464 KiB dela estão
residentes: o convidado tocou menos da metade do que recebeu. As outras áreas grandes estão marcadas
`rwx`, memória que pode ser executada, e são 16, com 1046796 KiB entre elas.

Isso é **código traduzido**. Sem VT-x, o QEMU transforma as instruções do convidado em instruções para o
processador do host e guarda o resultado, para não ter de traduzir o mesmo laço duas vezes; ele reserva
até 1 GiB para isso por padrão, e um convidado que já deu boot o encheu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Para onde foi a memória do processo do QEMU, como uma barra de 1674 mebibytes residentes. 1022 MiB são código traduzido, em 16 áreas executáveis, que só existem porque o processador é imitado em software. 436 MiB são a memória do próprio convidado, a parte dos 1024 MiB dele que ele já tocou. Os 215 MiB restantes são o próprio QEMU e os dispositivos dele.\"><defs><marker id=\"mm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o processo do QEMU: 1674 MiB residentes</text><rect x=\"20\" y=\"36\" width=\"415.3380370117094\" height=\"34\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"435.3380370117094\" y=\"36\" width=\"177.14385740525933\" height=\"34\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"612.4818944169688\" y=\"36\" width=\"87.51810558303129\" height=\"34\" rx=\"0\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"20\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">código traduzido: 1022 MiB</text><text x=\"20\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só porque o processador é imitado</text><text x=\"435.3380370117094\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">memória tocada do convidado: 436 MiB</text><text x=\"435.3380370117094\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dos 1024 MiB que o convidado recebeu</text><text x=\"700\" y=\"96\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o resto: 215 MiB</text></svg>", "caption": "Mais da metade do custo deste convidado é o preço de imitar um processador, e não a memória do convidado. Sob KVM essa parte não existe, e um convidado custa mais ou menos a memória que tocou mais a do próprio QEMU."}
```

Então, neste computador, **a maior parte do que um convidado custa é o preço de imitar um processador**.
Sob KVM, as instruções do convidado rodam no processador de verdade e não há nada para traduzir, e um
convidado custa mais ou menos a memória que tocou mais a do próprio QEMU. É a diferença da aula 2 de
novo, medida em memória desta vez.
