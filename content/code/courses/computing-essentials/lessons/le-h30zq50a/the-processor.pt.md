---
title: O processador, e o que "mais rápido" quer dizer de fato
version: 1
---

O processador — a CPU — faz uma coisa, alguns bilhões de vezes por segundo: pega uma instrução,
executa, e pega a próxima. Some estes dois números. Compare-os. Se o primeiro for maior, pule
para outro lugar. Todo programa que você já rodou é uma lista muito longa de instruções mais ou
menos nesse nível.

Dois números são citados sobre processadores, e são citados como se fossem o mesmo tipo de
número. Não são.

## O clock é quão rápido uma pessoa trabalha

**3,2 GHz** quer dizer que o processador dá 3,2 bilhões de passos por segundo. Mais alto é mais
rápido, para uma coisa de cada vez.

É o número que as lojas põem na fonte maior, e é o que parou de crescer. Processadores eram de
3 GHz em 2005 e são de 3 a 5 GHz hoje, porque empurrar o clock mais para cima faz calor mais
depressa do que faz velocidade. Tudo que melhorou nos vinte anos seguintes melhorou pelo outro
lado.

## Núcleos são quantas pessoas trabalham

Um **núcleo** é um processador completo por direito próprio. Uma CPU de 6 núcleos executa mesmo
seis instruções no mesmo instante, e não seis revezando depressa.

Esse é o número que cresceu: um núcleo, depois dois, depois seis, oito, dezesseis. E a razão de
ele vir citado em segundo é que só ajuda quando há mais de uma coisa a fazer — o que é quase
sempre verdade de um computador inteiro e muitas vezes falso de um programa só.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Dois painéis. À esquerda, um núcleo a 5 gigahertz com uma única barra de tarefa ocupando toda a largura, terminando em dez segundos. À direita, quatro núcleos a 3 gigahertz: a linha de cima mostra uma tarefa dividida entre os quatro, cada um terminando por volta de quatro segundos, e abaixo dela um segundo caso em que uma tarefa que não divide fica sozinha num núcleo e os outros três ficam vazios, terminando em dezessete segundos. Uma nota diz que mais núcleos ajudam quando há mais de uma coisa a fazer, e não fazem nada quando não há.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">O mesmo trabalho, em duas máquinas, duas vezes — e o segundo caso é o que ninguém avisa.</text><rect x=\"14\" y=\"38\" width=\"200\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"114\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">1 núcleo · 5 GHz</text><rect x=\"28\" y=\"76\" width=\"172\" height=\"18\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"114\" y=\"85\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">uma tarefa, ela inteira</text><text x=\"114\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">10 s</text><text x=\"114\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">rápida numa coisa</text><text x=\"114\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">e só numa</text><rect x=\"244\" y=\"38\" width=\"462\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"475\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">4 núcleos · 3 GHz</text><text x=\"258\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">trabalho que divide</text><rect x=\"258\" y=\"88\" width=\"92\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"356\" y=\"88\" width=\"92\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"454\" y=\"88\" width=\"92\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"552\" y=\"88\" width=\"92\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"668\" y=\"95\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">4 s</text><text x=\"258\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">trabalho que não divide</text><rect x=\"258\" y=\"134\" width=\"92\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"356\" y=\"134\" width=\"92\" height=\"14\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"454\" y=\"134\" width=\"92\" height=\"14\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"552\" y=\"134\" width=\"92\" height=\"14\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"668\" y=\"141\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">17 s</text><text x=\"258\" y=\"166\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">três núcleos parados, e nenhum clock que compense</text><text x=\"14\" y=\"206\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Mais núcleos ajudam quando há mais de uma coisa a fazer. Não fazem nada quando não há.</text></svg>", "caption": "A máquina de quatro núcleos é mais lenta na tarefa de baixo que a de um núcleo ao lado, e nada impresso em nenhuma das duas caixas diria isso.", "same": ["10 s", "4 s", "17 s"]}
```

Olhe a linha de baixo desse desenho, porque ela é a resposta a uma pergunta real. Alguém compra
uma máquina com mais núcleos, roda o único programa que lhe interessa, e ele é *mais lento* que
o da máquina antiga. Nada está quebrado. O programa não divide, então roda num núcleo a 3 GHz
onde a máquina antiga o rodava num núcleo a 5.

## O que os números do modelo querem dizer, grosso modo

`Intel Core i5-13400` e `AMD Ryzen 5 7600` têm o mesmo formato de nome:

| pedaço | o que diz |
|---|---|
| `Core i5` / `Ryzen 5` | a faixa — 3 é entrada, 5 é intermediária, 7 e 9 são mais |
| `13`400 / `7`600 | a geração — maior é mais nova, e só comparável dentro de uma marca |
| 13`400` / 7`600` | a posição dentro daquela geração |

**A faixa informa mais que o clock**, o que é o contrário de como as lojas apresentam. Um i5
da geração deste ano ganha de um i7 de seis anos atrás em quase tudo, e o i7 vai ter o número
maior impresso.

## O que ele precisa para ser rápido, e não controla

Um processador passa boa parte da vida sem fazer nada, esperando alguma coisa chegar. Ele não
conserta isso sendo mais rápido, e as próximas três seções são sobre onde ele espera.
