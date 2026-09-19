---
title: O monitor, e os três números da caixa
version: 1
---

Um monitor é vendido por um número — a diagonal, em polegadas — e julgado por outros três. A
diagonal é o que menos te diz.

## Resolução é quanto cabe, não o tamanho

Resolução é uma contagem de pixels: `1920 × 1080`, `2560 × 1440`, `3840 × 2160`. Ela não diz nada
sobre o tamanho físico do painel e diz tudo sobre quanto cabe nele de uma vez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três retângulos encaixados no mesmo canto superior esquerdo, desenhados em escala uns contra os outros. O menor é 1920 por 1080, o do meio 2560 por 1440, e o maior 3840 por 2160. Uma coluna à direita dá a contagem de pixels de cada um: 2,1 milhões, 3,7 milhões e 8,3 milhões. Uma nota diz que um 4K comporta quatro telas 1080p, não duas, e uma linha no pé diz que nada disso informa o tamanho da tela.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Três resoluções comuns, desenhadas em escala umas contra as outras</text><rect x=\"24\" y=\"40\" width=\"384\" height=\"216\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"24\" y=\"40\" width=\"256\" height=\"144\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"24\" y=\"40\" width=\"192\" height=\"108\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"208\" y=\"138\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">1080p</text><text x=\"272\" y=\"174\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">1440p</text><text x=\"400\" y=\"246\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4K</text><text x=\"440\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quanto cabe nela</text><text x=\"440\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1920 x 1080</text><text x=\"700\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">2,1 milhões de pixels</text><text x=\"440\" y=\"126\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2560 x 1440</text><text x=\"700\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">3,7 milhões de pixels</text><text x=\"440\" y=\"162\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3840 x 2160</text><text x=\"700\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">8,3 milhões de pixels</text><path d=\"M440 188 L700 188\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"440\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Um 4K comporta quatro telas 1080p,</text><text x=\"440\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">não duas.</text><text x=\"24\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Nada disso diz o tamanho da tela. Tamanho e resolução são dois números diferentes.</text></svg>", "caption": "Dobrar os dois lados quadruplica os pixels, e é por isso que um painel 4K custa à placa de vídeo quatro vezes o trabalho de um 1080p para a mesma imagem.", "same": ["1080p", "1440p", "4K"]}
```

**Dobrar o nome dobra cada lado e portanto quadruplica o trabalho.** Essa é a frase para levar do
diagrama, e é por ela que a seção de vídeo da aula anterior importa aqui: o mesmo jogo em 4K pede
quatro vezes mais da placa do que em 1080p.

## Tamanho e resolução juntos são o número que realmente conta

Divida os pixels pelas polegadas e você tem a **densidade de pixels**, em pixels por polegada. É
ela que decide se o texto fica nítido.

| painel | resolução | mais ou menos |
|---|---|---|
| 24 polegadas | `1920 × 1080` | 92 ppp — o desktop comum |
| 27 polegadas | `1920 × 1080` | 82 ppp — visivelmente mais grosso, os mesmos pixels espalhados |
| 27 polegadas | `2560 × 1440` | 109 ppp — o ponto doce em que a maioria para |
| 27 polegadas | `3840 × 2160` | 163 ppp — nítido, e precisa de escala para ser usável |

A terceira linha dessa tabela é a recomendação honesta para uma mesa, e a quarta é a armadilha: a
163 ppp os menus do sistema ficam fisicamente minúsculos, então você liga a escala em 150%, e
volta para perto da área útil do painel 1440p — tendo pago por um 4K e pedido quatro vezes mais
da placa de vídeo para exibi-lo.

**O 4K se paga numa televisão do outro lado da sala e num notebook perto do rosto.** Num monitor
de 27 polegadas a um braço de distância ele é quase só um número.

## Taxa de atualização, e para quem ela é

A taxa de atualização é quantas vezes por segundo o painel redesenha: `60 Hz`, `120 Hz`,
`144 Hz`, `240 Hz`. Acima de 60 Hz o movimento fica mais liso e o ponteiro parece grudado na sua
mão.

Seja honesto sobre para quem isso é. É uma diferença real e imediatamente visível em **jogos e
movimento rápido**, e quase nada para ler, escrever, planilhas e vídeo — um filme tem 24 quadros
por segundo e sempre teve. Se a máquina não consegue produzir mais que 60 quadros por segundo de
qualquer jeito, um painel de 144 Hz mostra 60 deles.

## Tipo de painel, em uma linha cada

- **IPS** — cor fiel, e a imagem não muda quando você olha de lado. O padrão para quase todo
  mundo.
- **VA** — pretos mais fundos e mais contraste, um pouco mais lento para trocar um pixel. Bom
  para filme em sala escura.
- **TN** — rápido e barato, as cores mudam assim que sua cabeça se mexe. Comprado para jogo
  competitivo e lamentado para todo o resto.

## Duas palavras que não são sobre o painel

**Razão de contraste** numa caixa costuma ser uma figura "dinâmica", medida com a luz de fundo
subindo e descendo entre as duas medições, o que não é uma coisa que acontece dentro de uma
imagem. Ignore qualquer número acima de uns 3000:1.

**Tempo de resposta** em milissegundos é medido de um jeito diferente por cada fabricante, às
vezes entre dois tons de cinza escolhidos para lisonjear. É o número menos comparável da caixa.
