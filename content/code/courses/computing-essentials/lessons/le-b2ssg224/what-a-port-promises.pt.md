---
title: Uma porta são três promessas vestindo um formato só
version: 1
---

Cada soquete de uma máquina é na verdade três fatos separados empilhados um sobre o outro, e só
o primeiro está à vista:

1. **O formato** — o que encaixa fisicamente.
2. **O protocolo** — que língua roda por aqueles fios.
3. **A velocidade** — em que ritmo esse protocolo está rodando aqui, nesta máquina.

Um conector te mostra o primeiro e não diz nada sobre os outros dois. Quase toda tarde
frustrante com um cabo vem de supor que ele diz.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma caixa à esquerda rotulada como um único soquete USB-C, com quatro linhas se abrindo dela para quatro caixas à direita. As quatro são USB 2.0 a 480 megabits por segundo e sem vídeo, USB 3.2 Gen 2 a 10 gigabits e talvez vídeo, USB4 a 40 gigabits com vídeo, e Thunderbolt 4 a 40 gigabits com vídeo e um disco em velocidade plena. Uma nota no pé diz que nada do lado de fora da máquina informa qual dos quatro você tem.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Um formato de soquete, quatro coisas diferentes atrás dele</text><rect x=\"24\" y=\"110\" width=\"180\" height=\"68\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"114\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um soquete USB-C</text><path d=\"M204 144 L280 60\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M204 144 L280 116\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M204 144 L280 172\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M204 144 L280 228\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><rect x=\"280\" y=\"40\" width=\"416\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"296\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">USB 2.0</text><text x=\"680\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">480 Mb/s, e imagem nenhuma</text><rect x=\"280\" y=\"96\" width=\"416\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"296\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">USB 3.2 Gen 2</text><text x=\"680\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10 Gb/s, e imagem se você tiver sorte</text><rect x=\"280\" y=\"152\" width=\"416\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"296\" y=\"172\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">USB4</text><text x=\"680\" y=\"172\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">40 Gb/s, e imagem</text><rect x=\"280\" y=\"208\" width=\"416\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"296\" y=\"228\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Thunderbolt 4</text><text x=\"680\" y=\"228\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">40 Gb/s, imagem, e um disco em velocidade plena</text><text x=\"24\" y=\"278\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Nada do lado de fora da máquina informa qual dos quatro você tem.</text></svg>", "caption": "O formato é a única das três promessas que dá para ver, e é a que menos importa."}
```

## Como descobrir o que um soquete é de verdade

Não existe truque que funcione do outro lado da sala. Existem três que funcionam:

- **O símbolo ao lado dele.** Um raio significa Thunderbolt; um formato de `D` significa que sai
  DisplayPort dali; `SS` significa SuperSpeed, que é `5 Gb/s` ou melhor. Um soquete pelado, sem
  símbolo, é o lento, e essa ausência é deliberada.
- **A cor dentro de um USB-A retangular.** Preto ou branco é USB 2.0. Azul é USB 3.x. Vermelho ou
  amarelo normalmente significa que ele continua energizado com a máquina dormindo. Isso é
  convenção e não norma, então é uma pista forte e não um fato.
- **A especificação do modelo.** A única confiável, e a razão de as outras duas valerem é que
  você raramente a tem à mão.

## A regra que sai disso

**Uma corrente anda na velocidade do elo mais fraco, e aqui são quatro elos.** A porta, o cabo, o
aparelho e o que a máquina está fazendo com as pistas que lhe sobram. Uma porta de `40 Gb/s` com
um cabo só de carga dentro não transfere nada, e nenhuma das duas pontas reporta erro.

Vale guardar isso, porque significa que **"não funciona" e "funciona devagar" têm o mesmo
conjunto de causas aqui**, e se acham pelo mesmo método: trocar um elo de cada vez.
