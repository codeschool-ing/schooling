---
title: A forma de uma inclinação
version: 1
---

A aula 3 insistiu que o eixo de uma barra começa no zero. **O eixo de uma linha não precisa
começar**, e a diferença está na codificação: uma barra mostra o número como comprimento a partir da
base, e uma linha o mostra como posição contra os rótulos do eixo. Nada num gráfico de linhas é lido
como comprimento a partir do zero.

Então uma linha de uma temperatura que se move entre 18 e 24 graus deve ser desenhada entre 18 e
24. Começar no zero espremeria a linha numa faixa plana no alto e esconderia toda mudança que vale a
pena ver.

Essa liberdade tem um preço. **Quem desenha um gráfico de linhas escolhe as inclinações**, e faz isso
de dois jeitos.

## A faixa do eixo

Estique o eixo vertical de 0 a 100.000 e o crescimento da Horta vira uma subida suave. Aperte de
10.000 a 21.000 e o mesmo crescimento vira um penhasco. Os dois são honestos, no sentido de que os
rótulos estão certos. Eles respondem perguntas diferentes: o primeiro pergunta se a mudança é grande
em relação ao todo; o segundo pergunta que forma a mudança tem.

**Escolha a faixa pela pergunta, e diga qual é.** Quando o tamanho de uma mudança em relação ao zero
importa, inclua o zero. Quando a forma da mudança importa, ajuste ao dado.

## A proporção do quadro

O segundo jeito é mais sutil, porque não envolve número nenhum.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 280\" role=\"img\" data-fig=\"l04-aspect\" aria-label=\"A mesma linha, os pedidos mensais do Sudeste em dois anos, desenhada duas vezes. Num quadro largo e baixo ela parece quase plana. Num quadro estreito e alto o mesmo crescimento parece íngreme. O dado e as faixas dos eixos são idênticos; só a forma do quadro mudou.\"><rect x=\"30.0\" y=\"150.0\" width=\"360.0\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M30.0 196.0 L45.7 195.2 L61.3 194.8 L77.0 193.0 L92.6 192.4 L108.3 195.8 L123.9 188.7 L139.6 189.5 L155.2 191.5 L170.9 188.3 L186.5 194.0 L202.2 164.9 L217.8 182.3 L233.5 188.1 L249.1 182.3 L264.8 186.5 L280.4 185.9 L296.1 179.4 L311.7 183.0 L327.4 180.3 L343.0 180.3 L358.7 179.0 L374.3 178.5 L390.0 159.6\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-linejoin=\"round\"></path><text x=\"30.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">largo e baixo: &quot;estável&quot;</text><rect x=\"470.0\" y=\"30.0\" width=\"90.0\" height=\"200.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M470.0 183.3 L473.9 180.7 L477.8 179.4 L481.7 173.3 L485.7 171.4 L489.6 182.7 L493.5 159.0 L497.4 161.6 L501.3 168.2 L505.2 157.6 L509.1 176.6 L513.0 79.6 L517.0 137.7 L520.9 156.9 L524.8 137.8 L528.7 151.6 L532.6 149.5 L536.5 128.1 L540.4 140.0 L544.3 130.9 L548.3 131.2 L552.2 126.8 L556.1 125.0 L560.0 61.9\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-linejoin=\"round\"></path><text x=\"515.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">estreito e alto: &quot;disparando&quot;</text></svg>", "caption": "A inclinação que o leitor vê depende tanto do quadro quanto do dado. Escolha uma proporção que deixe as inclinações importantes perto de 45 graus, e mantenha-a ao comparar."}
```

Os dois quadros mostram a mesma linha na mesma faixa do eixo. O quadro largo faz o crescimento do
Sudeste parecer constante; o alto o faz parecer explosivo. **O ângulo de uma linha depende da forma
da caixa em que ela é desenhada.**

William Cleveland, do ranking da aula 2, propôs uma regra para isso com dois colegas em 1988:
**inclinar a 45 graus**. As pessoas comparam inclinações com mais precisão quando elas estão perto
de 45 graus, então escolha a largura e a altura do gráfico para que os trechos importantes fiquem
por volta desse ângulo. Na prática:

- uma linha de **crescimento constante** se lê bem num quadro um pouco mais largo que alto;
- uma linha com **picos sazonais fortes** precisa de um quadro largo, para os picos não virarem
  paredes verticais;
- **dois gráficos feitos para comparação** têm de dividir a mesma proporção e a mesma faixa de eixo,
  senão a comparação é entre quadros, e não entre dados.
