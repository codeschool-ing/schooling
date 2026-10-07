---
title: A terceira dimensão
version: 1
---

As planilhas oferecem uma versão 3D de quase todo gráfico, e é o único efeito do menu que nunca
melhora um gráfico que mostra números. A profundidade acrescenta tinta que não carrega dado, e a
perspectiva que a faz parecer sólida muda os tamanhos que o leitor compara.

A pizza é o pior caso. Aqui está a receita da Horta por categoria, inclinada e com profundidade, ao
lado de um gráfico de barras simples dos mesmos seis números:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 270\" role=\"img\" data-fig=\"l16-three-d\" aria-label=\"A receita por categoria como uma pizza inclinada com profundidade, ao lado de um gráfico de barras com os mesmos números. Na pizza, Bebidas fica na frente e a parede lateral aparece, então ocupa 21,9% da tinta sendo 14,0% da receita, a segunda menor fatia. Hortaliças, a maior com 21,0%, fica atrás e ocupa 16,1%. As barras mostram a ordem real.\"><path d=\"M47.3 126.5 A110 46.2 0 0 1 40.0 110.0 L40.0 138.0 A110 46.2 0 0 0 47.3 154.5 Z\" stroke=\"#20263c\" stroke-width=\"0.8\" fill=\"#E69F00\" fill-opacity=\"0.75\"></path><path d=\"M260.0 110.0 A110 46.2 0 0 1 258.3 118.1 L258.3 146.1 A110 46.2 0 0 0 260.0 138.0 Z\" stroke=\"#20263c\" stroke-width=\"0.8\" fill=\"#009E73\" fill-opacity=\"0.75\"></path><path d=\"M258.3 118.1 A110 46.2 0 0 1 196.8 151.8 L196.8 179.8 A110 46.2 0 0 0 258.3 146.1 Z\" stroke=\"#20263c\" stroke-width=\"0.8\" fill=\"#F0E442\" fill-opacity=\"0.75\"></path><path d=\"M196.8 151.8 A110 46.2 0 0 1 103.2 151.8 L103.2 179.8 A110 46.2 0 0 0 196.8 179.8 Z\" stroke=\"#20263c\" stroke-width=\"0.8\" fill=\"#CC79A7\" fill-opacity=\"0.75\"></path><path d=\"M103.2 151.8 A110 46.2 0 0 1 47.3 126.5 L47.3 154.5 A110 46.2 0 0 0 103.2 179.8 Z\" stroke=\"#20263c\" stroke-width=\"0.8\" fill=\"#D55E00\" fill-opacity=\"0.75\"></path><path d=\"M150.0 110.0 L47.3 126.5 A110 46.2 0 0 1 86.5 72.3 Z\" stroke=\"#20263c\" stroke-width=\"0.8\" fill=\"#E69F00\"></path><path d=\"M150.0 110.0 L86.5 72.3 A110 46.2 0 0 1 214.1 72.5 Z\" stroke=\"#20263c\" stroke-width=\"0.8\" fill=\"#56B4E9\"></path><path d=\"M150.0 110.0 L214.1 72.5 A110 46.2 0 0 1 258.3 118.1 Z\" stroke=\"#20263c\" stroke-width=\"0.8\" fill=\"#009E73\"></path><path d=\"M150.0 110.0 L258.3 118.1 A110 46.2 0 0 1 196.8 151.8 Z\" stroke=\"#20263c\" stroke-width=\"0.8\" fill=\"#F0E442\"></path><path d=\"M150.0 110.0 L196.8 151.8 A110 46.2 0 0 1 103.2 151.8 Z\" stroke=\"#20263c\" stroke-width=\"0.8\" fill=\"#CC79A7\"></path><path d=\"M150.0 110.0 L103.2 151.8 A110 46.2 0 0 1 47.3 126.5 Z\" stroke=\"#20263c\" stroke-width=\"0.8\" fill=\"#D55E00\"></path><text x=\"150.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Bebidas: 14,0% da receita</text><text x=\"150.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">21,9% da tinta</text><path d=\"M400.0 26.0 L400.0 244.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M400.0 32.0 h168.2 v24.0 h-168.2 Z\" fill=\"#E69F00\" stroke=\"#E69F00\" stroke-width=\"1.2\"></path><text x=\"392.0\" y=\"44.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Verduras</text><text x=\"574.2\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">21,0%</text><path d=\"M400.0 67.0 h157.6 v24.0 h-157.6 Z\" fill=\"#56B4E9\" stroke=\"#56B4E9\" stroke-width=\"1.2\"></path><text x=\"392.0\" y=\"79.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Frutas</text><text x=\"563.6\" y=\"79.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">19,7%</text><path d=\"M400.0 102.0 h143.3 v24.0 h-143.3 Z\" fill=\"#009E73\" stroke=\"#009E73\" stroke-width=\"1.2\"></path><text x=\"392.0\" y=\"114.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Laticínios</text><text x=\"549.3\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">17,9%</text><path d=\"M400.0 137.0 h121.6 v24.0 h-121.6 Z\" fill=\"#F0E442\" stroke=\"#F0E442\" stroke-width=\"1.2\"></path><text x=\"392.0\" y=\"149.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Padaria</text><text x=\"527.6\" y=\"149.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">15,2%</text><path d=\"M400.0 172.0 h111.8 v24.0 h-111.8 Z\" fill=\"#CC79A7\" stroke=\"#CC79A7\" stroke-width=\"1.2\"></path><text x=\"392.0\" y=\"184.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Bebidas</text><text x=\"517.8\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">14,0%</text><path d=\"M400.0 207.0 h97.6 v24.0 h-97.6 Z\" fill=\"#D55E00\" stroke=\"#D55E00\" stroke-width=\"1.2\"></path><text x=\"392.0\" y=\"219.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Mercearia</text><text x=\"503.6\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">12,2%</text></svg>", "caption": "Inclinar uma pizza dá às fatias da frente uma parede lateral, tinta que as fatias de trás nunca recebem. A segunda menor categoria acaba parecendo a maior."}
```

Duas coisas acontecem quando uma pizza é inclinada:

- **As fatias da frente crescem e as de trás encolhem.** Achatar o círculo numa elipse mantém as
  áreas em proporção, mas as fatias da frente agora mostram a parede lateral além do topo.
- **A parede lateral só existe na frente.** Bebidas é 14,0% da receita, a segunda menor categoria, e
  acaba com 21,9% da tinta. Hortaliças, a maior com 21,0%, fica atrás e recebe 16,1%.

Então o leitor, que já comparava ângulos mal (aula 2), agora compara ângulos que foram entortados.
Girar a pizza alguns graus muda qual categoria parece a maior, o que quer dizer que a imagem está
relatando a rotação, e não a receita.

## Barras em 3D

Barras com profundidade têm uma versão mais discreta do mesmo problema. O topo de uma barra 3D é
desenhado acima da face da frente, então o leitor não sabe qual borda ler contra a linha de grade, e um
valor de 50 pode parecer chegar a 52 ou a 48 conforme o ângulo de visão.

## A regra

Use uma terceira dimensão só quando o dado tem três dimensões e o leitor pode girar a imagem, como num
gráfico científico interativo. Numa página ou num slide, desenhe plano.
