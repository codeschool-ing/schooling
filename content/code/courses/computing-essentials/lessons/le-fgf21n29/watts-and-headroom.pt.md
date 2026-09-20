---
title: Watts, folga, e o número que as pessoas erram nas duas direções
version: 1
---

Uma fonte é classificada em watts: `550 W`, `750 W`, `1000 W`. Esse é o máximo que ela entrega,
não o que ela puxa. Uma fonte de 750 W numa máquina que pede 200 W puxa uns 200 W.

Ou seja: a pergunta não é "quão grande" e sim "grande o bastante para quê".

## Somando, por alto

Você não precisa de planilha. Dois números dominam e o resto é arredondamento:

| | consumo típico sob carga |
|---|---|
| processador | 65 W a 125 W |
| placa de vídeo | 75 W a 350 W |
| todo o resto junto | uns 50 W |

Uma máquina sem placa de vídeo fica perto de 150 W. A mesma máquina com uma placa intermediária
fica perto de 400 W. **A placa é a decisão**, exatamente como a seção anterior disse.

## Folga, e por que mais não é mais seguro

Some uns 30% e arredonde para cima. 400 W de componentes pedem uma fonte de 550 W. Há duas
razões para a margem e nenhuma delas é medo:

- os componentes puxam picos curtos muito acima da média, e uma fonte no limite desliga em vez
  de ceder;
- uma fonte é mais eficiente perto da metade do valor dela, então ficar por volta de 70% sob
  carga é perto do ponto bom.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 264\" role=\"img\" aria-label=\"Uma curva da eficiência de uma fonte contra o quanto a máquina pede dela. Ela sobe rápido a partir de parada, tem o pico por volta da metade do valor nominal, marcado mais eficiente aqui, e cai devagar em direção aos 750 watts nominais à direita. Uma nota diz que uma fonte é mais eficiente perto da metade do que vale e que a máquina passa quase a vida perto de parada.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Quão eficiente é uma fonte de 750 W, contra o quanto a máquina pede dela.</text><path d=\"M60 206 L700 206\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M60 40 L60 206\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"380\" y=\"228\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">o que a máquina pede</text><path d=\"M60 206 L124 148 L188 122 L252 106 L316 94 L380 88 L444 90 L508 96 L572 106 L636 120 L700 136\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></path><path d=\"M380 206 L380 88\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></path><circle cx=\"380\" cy=\"88\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"392\" y=\"80\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">mais eficiente aqui</text><text x=\"92\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parada</text><text x=\"600\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sob carga</text><text x=\"700\" y=\"222\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">os 750 W nominais</text><text x=\"60\" y=\"32\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eficiência</text><text x=\"14\" y=\"250\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Uma fonte é mais eficiente perto da metade do que ela vale, e a máquina passa quase a vida perto de parada.</text></svg>", "caption": "Comprar o dobro dos watts de que você precisa não deixa a máquina mais segura. Move ela para a esquerda desta curva, onde a fonte é menos eficiente."}
```

Passado isso, mais watts não compram nada. Uma fonte de 1000 W numa máquina de 200 W não é mais
segura — ela passa a vida a 20% de carga, onde é menos eficiente, e custa mais para comprar.
**Folga é uma faixa, não uma direção.**

## E o número a conferir antes de tudo

O fabricante de uma placa de vídeo declara uma **potência de fonte recomendada** exatamente por
isso, e ela já conta com os picos. Se a placa diz 650 W, o número é esse, e aritmética nenhuma
sua passa por cima.
