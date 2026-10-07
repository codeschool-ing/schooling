---
title: Área, volume e pictogramas
version: 1
---

A aula 2 pôs as codificações em ordem de quão bem as pessoas as leem, e a área ficou bem abaixo do
comprimento. A aula 6 deu a regra para bolhas: dimensione pela área, nunca pelo raio. Esta seção segue
o mesmo erro até os lugares onde ele se esconde.

O Norte recebeu 7.384 pedidos em 2024 e 11.852 em 2025, uma alta de 60,5%. Desenhe cada ano como um
círculo e faça o **raio** 1,6 vez maior, e a **área**, que é o que o olho compara, fica 2,58 vezes
maior:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 240\" role=\"img\" data-fig=\"l16-area\" aria-label=\"Os pedidos do Norte em 2024, 7.384, e 2025, 11.852, uma alta de 60,5%, desenhados de três jeitos. Primeiro, dois círculos cujo raio cresce 1,61 vezes: o segundo círculo tem 2,58 vezes a área e parece isso. Segundo, dois círculos cuja área cresce 1,61 vezes: o raio cresce só 1,27. Terceiro, duas barras.\"><text x=\"30.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">raio na escala</text><circle cx=\"75.0\" cy=\"156.0\" r=\"34.0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"184.6\" cy=\"135.4\" r=\"54.6\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"75.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2024</text><text x=\"184.6\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2025</text><text x=\"30.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">parece 2,6×</text><text x=\"250.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">área na escala</text><circle cx=\"295.0\" cy=\"156.0\" r=\"34.0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"393.1\" cy=\"146.9\" r=\"43.1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"295.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2024</text><text x=\"393.1\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2025</text><text x=\"250.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">é 1,6×</text><text x=\"480.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">barras</text><path d=\"M480.0 190.0 L610.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M492.0 103.9 h40.0 v86.1 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"512.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2024</text><text x=\"512.0\" y=\"95.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">7.384</text><path d=\"M557.0 51.7 h40.0 v138.3 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"577.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2025</text><text x=\"577.0\" y=\"43.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">11.852</text></svg>", "caption": "O olho lê um círculo pela área. Ponha o raio na escala do dado e a área cresce pelo quadrado dele; um pictograma escalado em altura e largura faz o mesmo, e um cubo nas três dimensões vai ao cubo."}
```

Este é o erro mais comum dos infográficos, e é cometido de boa-fé: a ferramenta de desenho dimensiona
uma forma pela largura, então a pessoa escala a largura.

## A regra

- **Escale a área, não o raio.** O raio cresce pela raiz quadrada da razão: √1,605 = 1,267. Como a
  aula 6 disse, o `scatter` do matplotlib já recebe `s` como área; as ferramentas de desenho que
  dimensionam uma forma pela largura não.
- **Um pictograma escalado em duas dimensões tem o mesmo problema.** Uma sacola de compras desenhada
  1,6 vez mais alta e 1,6 vez mais larga cobre 2,58 vezes o espaço.
- **O volume é pior.** Um cubo ou um cilindro escalado nas três dimensões cresce pelo cubo: 1,605³ =
  4,13. E o olho nem lê o volume como volume; ele lê a área do desenho, que fica em algum ponto no
  meio.

## A escolha mais segura

Mesmo desenhadas certo, áreas se leem com menos precisão que comprimentos. Quando a comparação
importa, use barras. Quando a imagem é o ponto, como num gráfico de ícones, **repita** um ícone de
tamanho fixo em vez de aumentar um só: doze sacolas para 12.000 pedidos e sete para 7.000 se contam,
não se estimam.
