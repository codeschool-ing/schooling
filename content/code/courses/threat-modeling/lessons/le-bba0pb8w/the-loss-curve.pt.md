---
title: A curva de excedência de perdas
version: 1
---

Uma tabela de percentis responde a perguntas que alguém já pensou em fazer. Uma **curva de
excedência de perdas** responde a todas de uma vez: para cada valor em dinheiro, **a chance de a
perda total de um ano ser maior**. É a figura mais útil que o FAIR produz, e a que se põe diante de
quem decide quanto risco o negócio carrega.

O `fair.py` imprime quatro pontos dela:

```
chance that one year's total loss is more than
  R$   100,000   46.4%
  R$   250,000   28.1%
  R$   500,000   14.1%
  R$ 1,000,000    4.8%
```

E a curva inteira, desenhada a partir dos mesmos dez mil anos:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l10-exceedance\" aria-label=\"A curva de excedência de perdas da simulação: para cada valor num eixo logarítmico de 10.000 a 3.000.000 de reais, a chance de a perda total de um ano ser maior. A curva cai de quase 100% em 10.000, passando por 46,4% em 100.000, 28,1% em 250.000 e 14,1% em 500.000, até 4,8% em 1.000.000. Uma linha tracejada marca a tolerância do daniel: no máximo 10% de chance de perder mais de 500.000 num ano. A curva passa acima desse ponto.\"><path d=\"M80.0 270.0 L690.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 25.0 L80.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 270.0 L80.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"72.0\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M76.0 208.8 L80.0 208.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 208.8 L690.0 208.8\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72.0\" y=\"208.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25%</text><path d=\"M76.0 147.5 L80.0 147.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 147.5 L690.0 147.5\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72.0\" y=\"147.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50%</text><path d=\"M76.0 86.2 L80.0 86.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 86.2 L690.0 86.2\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72.0\" y=\"86.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">75%</text><path d=\"M76.0 25.0 L80.0 25.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 25.0 L690.0 25.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72.0\" y=\"25.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><path d=\"M80.0 270.0 L80.0 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.000</text><path d=\"M326.3 270.0 L326.3 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"326.3\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100.000</text><path d=\"M572.5 270.0 L572.5 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"572.5\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.000.000</text><path d=\"M80.0 31.8 L85.1 32.7 L90.2 33.7 L95.3 34.8 L100.3 35.8 L105.4 37.0 L110.5 38.3 L115.6 39.6 L120.7 41.3 L125.7 43.3 L130.8 45.2 L135.9 46.9 L141.0 48.5 L146.1 51.0 L151.2 53.2 L156.2 55.4 L161.3 58.1 L166.4 61.4 L171.5 64.5 L176.6 67.5 L181.7 70.3 L186.8 73.2 L191.8 77.1 L196.9 80.8 L202.0 84.4 L207.1 88.1 L212.2 91.3 L217.2 95.1 L222.3 99.0 L227.4 102.5 L232.5 106.0 L237.6 109.8 L242.7 113.6 L247.8 116.9 L252.8 120.2 L257.9 123.2 L263.0 126.4 L268.1 129.3 L273.2 131.7 L278.2 134.6 L283.3 137.2 L288.4 139.4 L293.5 141.9 L298.6 144.2 L303.7 146.3 L308.8 148.4 L313.8 151.0 L318.9 153.3 L324.0 155.6 L329.1 158.1 L334.2 160.2 L339.3 162.5 L344.3 165.0 L349.4 167.3 L354.5 169.4 L359.6 171.7 L364.7 173.7 L369.7 175.7 L374.8 178.2 L379.9 181.1 L385.0 183.7 L390.1 185.8 L395.2 188.4 L400.2 190.3 L405.3 192.5 L410.4 194.5 L415.5 197.0 L420.6 199.4 L425.7 201.9 L430.7 204.5 L435.8 207.3 L440.9 209.5 L446.0 212.1 L451.1 214.4 L456.2 216.8 L461.2 219.1 L466.3 221.4 L471.4 223.7 L476.5 225.7 L481.6 228.0 L486.7 230.0 L491.8 232.9 L496.8 234.8 L501.9 236.9 L507.0 239.0 L512.1 240.7 L517.2 242.5 L522.2 244.2 L527.3 246.0 L532.4 247.8 L537.5 249.0 L542.6 250.5 L547.7 251.9 L552.8 252.8 L557.8 254.5 L562.9 256.0 L568.0 257.2 L573.1 258.4 L578.2 259.4 L583.2 260.2 L588.3 261.4 L593.4 262.3 L598.5 263.3 L603.6 263.9 L608.7 264.7 L613.8 265.2 L618.8 265.9 L623.9 266.2 L629.0 266.5 L634.1 267.1 L639.2 267.4 L644.3 267.9 L649.3 268.2 L654.4 268.5 L659.5 268.7 L664.6 268.9 L669.7 268.9 L674.8 269.2 L679.8 269.4 L684.9 269.5 L690.0 269.6\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"326.3\" cy=\"156.4\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"334.3\" y=\"146.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">46,4%</text><circle cx=\"424.2\" cy=\"201.3\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"432.2\" y=\"191.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">28,1%</text><circle cx=\"498.4\" cy=\"235.4\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"506.4\" y=\"225.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">14,1%</text><circle cx=\"572.5\" cy=\"258.2\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"580.5\" y=\"248.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">4,8%</text><path d=\"M498.4 245.5 L690.0 245.5\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M498.4 245.5 L498.4 270.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><circle cx=\"498.4\" cy=\"245.5\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"490.4\" y=\"259.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">tolerância do daniel: 10% em R$ 500.000</text><text x=\"385.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">perda total em um ano, R$ (escala log)</text><text x=\"80.0\" y=\"14.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">chance de perder mais</text></svg>", "caption": "Uma curva para o portfólio inteiro. Onde ela passa acima do ponto de tolerância, o negócio está carregando mais risco do que disse que carregaria."}
```

### Apetite de risco, como um ponto na figura

Uma curva torna respondível uma pergunta que uma lista de riscos nunca respondeu: **quanto risco o
negócio está disposto a carregar?** A resposta do daniel, depois de olhar a curva por um tempo, foi
um ponto só: *no máximo 10% de chance de perder mais de meio milhão de reais num ano.* Essa frase é o
**apetite de risco** das clínicas, ou a tolerância, escrita em unidades que qualquer um consegue
conferir.

A curva passa **acima** desse ponto: a chance de perder mais de R$ 500.000 é de 14,1%. O negócio está
carregando mais risco do que o dono diz querer, e isso, e não uma cor num gráfico, é o motivo para
gastar dinheiro com controles. A aula 11 pergunta quais controles trazem a curva para baixo do ponto
pelo menor dinheiro.

### Dois cuidados

**A ponta direita da curva é a parte menos certa.** A chance de perder mais de R$ 1.000.000 depende
quase só das caudas das faixas mais largas, que são as estimativas de que a equipe tinha menos
certeza. Leia 4,8% como "uns poucos por cento", não como uma medição.

**O apetite é uma decisão, não um cálculo.** Nenhuma fórmula produz o ponto do daniel. Ele depende do
que a Vereda aguenta, do que os donos estão dispostos a perder, do que um seguro custaria e do que os
pacientes aceitariam. O trabalho da análise é mostrar a curva ao daniel em reais; a decisão é
do daniel, e a aula 12 trata de registrá-la.
