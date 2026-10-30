---
title: Classes de tamanho, onde o layout pode mudar de forma
version: 1
---

**Uma classe de tamanho é uma faixa de tamanhos de janela com nome, e um app muda o layout só quando
a janela passa de uma faixa para outra.** Isso mantém o número de layouts pequeno e igual em todas
as telas do app. O Android e o iOS têm as suas, com faixas diferentes e o mesmo propósito.

## Android: classes de tamanho de janela em dp

A documentação do Android sobre classes de tamanho de janela dá os pontos de quebra de largura em
dp, com o que cada faixa costuma conter:

| classe de largura | ponto de quebra | o que a documentação diz que ela representa |
|---|---|---|
| compact | abaixo de 600 dp | 99,96% dos celulares em retrato |
| medium | de 600 dp a menos de 840 dp | 93,73% dos tablets em retrato, a maioria das telas internas grandes desdobradas em retrato |
| expanded | de 840 dp a menos de 1200 dp | 97,22% dos tablets em paisagem, a maioria das telas internas grandes desdobradas em paisagem |
| large | de 1200 dp a menos de 1600 dp | telas de tablets grandes |
| extra-large | 1600 dp ou mais | telas de desktop |

**As alturas também têm faixas**: compact abaixo de 480 dp, que a mesma tabela diz cobrir 99,78%
dos celulares em paisagem; medium de 480 a menos de 900 dp; expanded a partir de 900 dp. A
documentação acrescenta que a maioria dos apps decide o layout só pela largura, e dá o caso em que a
altura importa: um celular em paisagem muitas vezes é medium de largura e compact de altura, e dois
painéis lado a lado não funcionam numa janela tão baixa. Os percentuais são do Google, como
publicados naquela página quando foi lida em 30 de outubro de 2026; os pontos de quebra são a parte
que um app escreve no código.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 168\" role=\"img\" data-fig=\"l08-ruler\" aria-label=\"Uma régua de larguras de janela de 0 a 1800 dp, dividida pelos pontos de quebra de largura do Android: compact abaixo de 600 dp, medium de 600 a 840, expanded de 840 a 1200, large de 1200 a 1600 e extra-large a partir de 1600. Quatro janelas de exemplo estão marcadas: um celular em retrato com 360 dp, um dobrável aberto em retrato com 700, o mesmo dobrável virado com 880 e um tablet em paisagem com 1280.\"><defs><marker id=\"l08-ruler-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">largura da janela em dp, e a classe que o Android dá a ela</text><rect x=\"40.0\" y=\"100\" width=\"213.3\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"146.65\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">compact</text><rect x=\"253.3\" y=\"100\" width=\"85.3\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"295.95\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">medium</text><rect x=\"338.7\" y=\"100\" width=\"128.0\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"402.7\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">expanded</text><rect x=\"466.7\" y=\"100\" width=\"142.2\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"537.8\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">large</text><rect x=\"608.9\" y=\"100\" width=\"71.1\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"644.4499999999999\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">extra-large</text><path d=\"M40.0 130 L40.0 140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"40.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M253.3 130 L253.3 140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"253.3\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">600</text><path d=\"M338.7 130 L338.7 140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"338.7\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">840</text><path d=\"M466.7 130 L466.7 140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"466.7\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1200</text><path d=\"M608.9 130 L608.9 140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"608.9\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1600</text><text x=\"680.0\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">dp</text><text x=\"168.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">celular, retrato</text><text x=\"168.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">360</text><path d=\"M168.0 55 L168.0 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-ruler-ah-paper-dim)\"></path><text x=\"288.9\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">dobrável, aberto</text><text x=\"288.9\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">700</text><path d=\"M288.9 83 L288.9 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-ruler-ah-paper-dim)\"></path><text x=\"352.9\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">dobrável, virado</text><text x=\"352.9\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">880</text><path d=\"M352.9 55 L352.9 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-ruler-ah-paper-dim)\"></path><text x=\"495.1\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tablet, paisagem</text><text x=\"495.1\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1280</text><path d=\"M495.1 83 L495.1 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-ruler-ah-paper-dim)\"></path></svg>", "caption": "As classes de largura do Android como faixas numa régua. As janelas de exemplo são números redondos, não medidas de aparelhos reais; o que importa é em que faixa uma janela cai, e que o mesmo aparelho cai em faixas diferentes conforme a janela muda."}
```

## iOS: compact ou regular, em cada eixo

**As Human Interface Guidelines da Apple dão a cada eixo uma de duas classes de tamanho, compact ou
regular**, então uma janela é uma de quatro combinações: largura compact e altura compact, largura
compact e altura regular, e assim por diante. O sistema as define a partir do aparelho, da janela e
da multitarefa, e as diretrizes dizem para decidir o layout pelas classes de tamanho e não pelo tipo
de aparelho ou pela orientação, porque esses não dizem quanto espaço existe. A Apple não publica as
classes como números ao estilo dos dp para o app comparar; o app lê em qual classe está.

## React Native: o tamanho da janela, e uma regra sua

O React Native não tem classes de tamanho. **`useWindowDimensions` devolve a largura e a altura da
janela nas unidades independentes de densidade dele**, e a documentação diz que ele as atualiza
quando o tamanho da janela ou a escala da fonte muda, então um componente que o lê é desenhado de
novo quando a janela muda. Onde as faixas caem é decisão do app, e a escolha honesta mais simples é
usar os números do Android nas duas plataformas, que é o que o programa desta aula faz.

## A mesma pergunta em três grafias

Os trechos abaixo perguntam se a janela é larga o bastante para dois painéis. Eles foram adaptados
da documentação de cada plataforma, e **não foram compilados nem rodados para este curso**.

```kotlin
// Compose: the window size class, from the Material 3 adaptive library
val sizeClass = currentWindowAdaptiveInfo().windowSizeClass
val twoPanes = sizeClass.isWidthAtLeastBreakpoint(WindowSizeClass.WIDTH_DP_EXPANDED_LOWER_BOUND)
```

```swift
// SwiftUI: the horizontal size class, from the environment
@Environment(\.horizontalSizeClass) private var widthClass
var twoPanes: Bool { widthClass == .regular }
```

```tsx
// React Native: the window's width in dp or points, and a breakpoint the app chose
const { width } = useWindowDimensions();
const twoPanes = width >= 840;
```

**Cada um dos três é lido de novo quando a janela muda**: o Compose e o SwiftUI redesenham o que
depende do valor, e o `useWindowDimensions` se atualiza. Nenhum deles pergunta "isto é um tablet".
O do SwiftUI é mais grosso que os outros dois, com dois valores para o eixo em vez de cinco, e um
app que precisa de uma linha mais fina lê também a largura da janela.
