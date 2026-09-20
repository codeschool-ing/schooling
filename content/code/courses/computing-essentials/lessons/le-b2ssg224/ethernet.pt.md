---
title: Ethernet, o único lugar em que os números são honestos
version: 1
---

O soquete de rede é o conector menos confuso da máquina. Um formato, chamado `RJ45`, um
protocolo, e velocidades que são o que dizem. Ele tem uma trava de plástico que quebra, e esse é
mais ou menos todo o drama dele.

O que vale saber não é a porta. É que **um enlace anda na velocidade da parte mais lenta**, e
normalmente são quatro partes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Quatro caixas em fila ligadas por setas: a porta da máquina a um gigabit, o cabo a um gigabit, o soquete da parede a cem megabits, e a porta do roteador a um gigabit. Uma caixa larga embaixo diz a que velocidade o enlace realmente anda, e dá cem megabits. Uma nota diz que são quatro partes e a mais lenta decide.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Uma parte lenta, e o enlace inteiro fica lento assim</text><rect x=\"24\" y=\"56\" width=\"150\" height=\"64\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"99\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a porta da máquina</text><text x=\"99\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1 Gb/s</text><path d=\"M180 88 L192 88 M186 83 L192 88 L186 93\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"198\" y=\"56\" width=\"150\" height=\"64\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"273\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o cabo</text><text x=\"273\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1 Gb/s</text><path d=\"M354 88 L366 88 M360 83 L366 88 L360 93\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"372\" y=\"56\" width=\"150\" height=\"64\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"447\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o soquete da parede</text><text x=\"447\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">100 Mb/s</text><path d=\"M528 88 L540 88 M534 83 L540 88 L534 93\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"546\" y=\"56\" width=\"150\" height=\"64\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"621\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a porta do roteador</text><text x=\"621\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1 Gb/s</text><rect x=\"24\" y=\"166\" width=\"672\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"44\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a que velocidade o enlace realmente anda</text><text x=\"676\" y=\"192\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">100 Mb/s</text><text x=\"24\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Quatro partes, e a mais lenta decide. Nada em lugar nenhum reporta as outras três como desperdício.</text></svg>", "caption": "A falha não tem sintoma próprio: tudo conecta, tudo funciona, e um número fica em um décimo do que deveria ser."}
```

## As velocidades, e quais você vai encontrar

| | o que é | onde |
|---|---|---|
| `100 Mb/s` | *Fast Ethernet*, e não é | soquetes de parede antigos, switches baratos, algumas impressoras |
| `1 Gb/s` | *Gigabit*, o comum | toda máquina e todo roteador vendidos há quinze anos |
| `2,5 Gb/s` | o novo meio-termo | placas-mãe recentes, roteadores melhores |
| `10 Gb/s` | para mover arquivos grandes entre máquinas | servidores, e entusiastas |

**Quase todo problema doméstico é a primeira linha aparecendo num lugar inesperado**, e os
lugares de sempre são um soquete de parede instalado anos atrás e um switch comprado por dez
reais.

## Categorias de cabo, em resumo e sem a propaganda

| | homologado para |
|---|---|
| `Cat 5e` | 1 Gb/s a 100 m. Serve para quase toda casa |
| `Cat 6` | 1 Gb/s a 100 m, 10 Gb/s até uns 55 m |
| `Cat 6a` | 10 Gb/s a 100 m |
| `Cat 7`, `Cat 8` | mais, em condições que uma casa não tem |

O `Cat 6` é o padrão sensato para qualquer coisa nova, porque a diferença de preço é pequena e é
o que você gostaria de ter posto dentro da parede. Qualquer coisa acima de `Cat 6a` numa casa é
um número na embalagem.

## Ethernet contra Wi-Fi, que não é bem uma disputa

Um cabo te dá uma velocidade **estável**, um atraso **baixo e constante**, e imunidade ao
roteador do vizinho. O Wi-Fi te dá uma velocidade que muda quando alguém passa entre os cômodos.

Para ler e escrever, ninguém nota a diferença. Para uma chamada de vídeo, um envio grande ou um
jogo, o que um cabo conserta não é a velocidade — é a **variação**. Uma conexão que tem boa média
e engasga uma vez por minuto é pior de usar que uma mais lenta que nunca engasga.

## A trava, que é a única parte que quebra

A lingueta de plástico que segura o plugue quebra, e aí o cabo cai pela metade e o enlace cai
quando alguém mexe numa cadeira. É um conserto de dois minutos com um plugue novo e um alicate de
crimpagem, e até lá é um defeito que parece exatamente uma rede instável.
