---
title: "O endereço MAC: seis bytes e dois bits"
version: 1
---

Um endereço MAC parece um número de série, e isso está meio certo. **São seis bytes, escritos como
doze dígitos hexadecimais em pares, e o primeiro byte carrega dois bits que mudam o significado do
resto.** A placa do pc1, da seção da placa de rede, é `02:25:70:bc:29:c6`: seis pares, seis bytes,
48 bits.

A descrição de sempre diz que os três primeiros bytes nomeiam o fabricante e os três últimos são o
número da própria placa. Para um endereço gravado na placa na fábrica, é assim mesmo: o IEEE vende a
cada fabricante um bloco chamado **OUI** (*Organizationally Unique Identifier*), o fabricante numera
as suas placas dentro do bloco, e as duas metades juntas devem ser únicas no mundo. Muitas
ferramentas consultam os três primeiros bytes e mostram o nome de um fabricante.

Nem todo endereço funciona assim, e os do laboratório são o exemplo. Todo MAC deste curso começa com
`02`. Olhe esse byte bit a bit:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"O endereço MAC 02:25:70:bc:29:c6, o do pc1, como seis caixas de um byte cada. Os três primeiros bytes, 02:25:70, são onde ficaria o prefixo de um fabricante, o OUI; os três últimos, bc:29:c6, são o número da própria placa. O primeiro byte, 02, está aberto em seus oito bits: 0 0 0 0 0 0 1 0. O bit mais baixo, à direita, é o bit I/G, 0 aqui, que quer dizer que o quadro é para uma placa; 1 quer dizer um grupo. O bit ao lado é o bit U/L, 1 aqui, que quer dizer que o endereço foi definido localmente, e não gravado por um fabricante.\"><defs><marker id=\"l2-mac-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"130\" y=\"40\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"165\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">02</text><rect x=\"208\" y=\"40\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"243\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">25</text><rect x=\"286\" y=\"40\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"321\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">70</text><rect x=\"364\" y=\"40\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"399\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">bc</text><rect x=\"442\" y=\"40\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"477\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">29</text><rect x=\"520\" y=\"40\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"555\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">c6</text><text x=\"243\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">três primeiros bytes: o OUI</text><text x=\"477\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">três últimos: o número da placa</text><path d=\"M130 74 L150 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M200 74 L560 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"150\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"173\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><rect x=\"202\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><rect x=\"254\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"277\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><rect x=\"306\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"329\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><rect x=\"358\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"381\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><rect x=\"410\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"433\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><rect x=\"462\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><rect x=\"514\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"537\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><text x=\"140\" y=\"157\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">byte 02</text><path d=\"M537 174 L537 200 L590 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M485 174 L485 238 L590 238\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"596\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">I/G = 0</text><text x=\"596\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma placa, não um grupo</text><text x=\"596\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">U/L = 1</text><text x=\"596\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">definido localmente</text></svg>", "caption": "O endereço MAC do pc1, e os dois bits do primeiro byte que mudam o seu significado.", "same": ["byte 02"]}
```

`02` é `00000010` em binário, e os dois bits mais baixos são os que importam:

- **Bit 0, o bit I/G** (*individual/group*). 0 quer dizer que o endereço é de uma placa; 1 quer
  dizer que ele nomeia um grupo, e um quadro enviado a ele é para cada placa que entrou nesse grupo.
  O endereço de broadcast `ff:ff:ff:ff:ff:ff` tem todos os bits ligados, este incluído.
- **Bit 1, o bit U/L** (*universal/local*). 0 quer dizer que o endereço foi atribuído sob o OUI de
  um fabricante; **1 quer dizer que alguém o definiu localmente**, e os três primeiros bytes não
  nomeiam fabricante algum.

Então `02` se lê: uma placa, administrada localmente. O laboratório escolheu isso de propósito. O
script dá a cada placa um endereço feito de `02` e cinco bytes calculados a partir dos nomes do
equipamento e da interface, para que o pc1 tenha o mesmo MAC toda vez que o laboratório é montado e
uma transcrição gravada hoje bata com uma gravada no mês que vem. O servidor, `02:9e:43:3e:ca:ae`, e
o roteador, `02:1f:23:e7:e9:d5`, seguem a mesma regra.

Um jeito rápido de reconhecer um endereço local: **olhe o segundo dígito hexadecimal**. Se for 2, 6,
a ou e, o bit U/L está ligado e o bit I/G desligado. Máquinas virtuais e contêineres usam endereços
locais, e celulares escolhem um endereço local aleatório para cada rede Wi-Fi em que entram, para
que o mesmo celular não seja seguido pelo MAC da rede de um café até a do próximo.

Duas consequências valem guardar:

- **Um endereço MAC se troca em um segundo**, por quem controla a máquina. Ele identifica uma placa
  num enlace; não prova nada sobre quem a está usando. A aula 18 volta a isso quando uma porta de
  switch é travada em um endereço.
- **Ele não significa nada fora do seu enlace.** Um roteador o lê, o descarta e monta um quadro novo
  com endereços novos, então o servidor do outro lado de um roteador nunca fica sabendo o MAC do
  pc1. A seção do gateway mostra o quadro que prova isso.
