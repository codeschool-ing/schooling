---
title: Onde a luminosidade do HSL mente
version: 1
---

O HSL foi criado nos anos 1970 para ser fácil de calcular, não para combinar com o olho. A
"luminosidade" dele é a média do canal RGB mais forte e do mais fraco de uma cor, e essa média ignora
algo de que o olho faz muita questão: **as três luzes não parecem igualmente brilhantes**. O verde
parece muito mais brilhante que o vermelho, e o vermelho muito mais que o azul.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 300\" role=\"img\" data-fig=\"l11-same-l\" aria-label=\"Seis cores de saturação máxima que o HSL diz estarem todas em 50% de luminosidade: vermelho, amarelo, verde, ciano, azul e magenta. Embaixo de cada uma, o cinza com o mesmo brilho para o olho, e uma barra da sua luminância relativa. O cinza do amarelo é quase branco e a barra dele chega a 0,93; o cinza do azul é quase preto e a barra dele é 0,07.\"><rect x=\"170.0\" y=\"20.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#ff0000\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"170.0\" y=\"90.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#7f7f7f\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M176.0 248.7 h40.0 v21.3 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"196.0\" y=\"238.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0,21</text><rect x=\"238.0\" y=\"20.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#ffff00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"238.0\" y=\"90.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#f7f7f7\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M244.0 177.2 h40.0 v92.8 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"264.0\" y=\"167.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0,93</text><rect x=\"306.0\" y=\"20.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#00ff00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"306.0\" y=\"90.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#dcdcdc\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M312.0 198.5 h40.0 v71.5 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"332.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0,72</text><rect x=\"374.0\" y=\"20.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#00ffff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"374.0\" y=\"90.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#e5e5e5\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M380.0 191.3 h40.0 v78.7 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"400.0\" y=\"181.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0,79</text><rect x=\"442.0\" y=\"20.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#0000ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"442.0\" y=\"90.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#4c4c4c\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M448.0 262.8 h40.0 v7.2 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"468.0\" y=\"252.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0,07</text><rect x=\"510.0\" y=\"20.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#ff00ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"90.0\" width=\"52.0\" height=\"52.0\" rx=\"2\" fill=\"#919191\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M516.0 241.5 h40.0 v28.5 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"536.0\" y=\"231.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0,28</text><path d=\"M160.0 270.0 L580.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"156.0\" y=\"46.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">luminosidade HSL: 50% cada</text><text x=\"156.0\" y=\"116.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o cinza que o olho vê</text><text x=\"156.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">luminância relativa</text></svg>", "caption": "O HSL chama as seis de \"50% de luminosidade\". O olho discorda: o amarelo é treze vezes mais brilhante que o azul. Uma paleta construída na luminosidade do HSL já nasce desigual."}
```

As seis cores de cima têm saturação máxima e luminosidade HSL de exatamente 50%. A fileira de cinzas
embaixo mostra o quanto cada uma parece brilhante de fato, e as barras medem isso como **luminância
relativa**, a soma ponderada do vermelho, do verde e do azul lineares que normas como a WCAG usam
(aula 14):

```localised
luminância relativa = 0,2126 × vermelho + 0,7152 × verde + 0,0722 × azul
```

com cada canal convertido antes dos valores da tela para luz linear. O verde leva mais de 70% do peso
e o azul menos de 8%.

Então **o amarelo, em 0,93, é quase tão claro quanto o branco, e o azul, em 0,07, é quase tão escuro
quanto o preto**, enquanto o seletor de cores dá os mesmos 50% para os dois. A diferença é de umas
treze vezes.

## Por que isso importa para gráficos

- **Uma paleta escolhida pelo HSL é desigual.** Seis categorias escolhidas "com a mesma luminosidade"
  vão ter uma ou duas que gritam e uma ou duas que somem. Linhas amarelas numa página branca são o caso
  famoso.
- **Uma rampa feita em passos de HSL também é desigual.** Passos iguais de luminosidade HSL parecem
  saltos grandes em alguns lugares e minúsculos em outros, então uma paleta sequencial num mapa de
  calor sugere fronteiras que o dado não tem. A próxima seção mostra isso.
- **Texto sobre uma cor precisa do brilho real.** Se texto branco ou preto se lê num fundo colorido
  depende da luminância, e não da luminosidade do HSL.

A correção é escolher as cores num espaço feito para combinar com a percepção.
