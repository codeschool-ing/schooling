---
title: Variáveis numéricas
version: 1
---

Uma **variável numérica** registra uma quantidade: algo medido ou contado, em que o número é a quantia.
A *cesta* da Horta é uma, em reais. Também são numéricas *minutos*, o tempo entre o pedido e a
campainha, e *itens*, o número de coisas na sacola.

O teste é o oposto do categórico. O valor responde *quanto?* ou *quantos?*, e **a aritmética sobre ele
significa algo**. Uma cesta de R$ 86,40 tem R$ 31,90 a mais que uma cesta de R$ 54,50, e essa diferença
é dinheiro que uma pessoa pagou.

## Uma variável numérica tem lugar numa reta

Como os valores são quantidades, dá para colocá-los numa reta numérica, e os intervalos entre eles são
distâncias de verdade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 150\" role=\"img\" data-fig=\"l01-minutes-dots\" aria-label=\"Um gráfico de pontos com os doze tempos de entrega numa reta de 25 a 65 minutos. A maioria fica entre 27,5 e 44; dois se destacam à direita, em 52,5 e 61.\"><path d=\"M40.0 95.0 L590.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M40.0 95.0 L40.0 99.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"40.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25</text><path d=\"M108.8 95.0 L108.8 99.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"108.8\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M177.5 95.0 L177.5 99.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"177.5\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">35</text><path d=\"M246.2 95.0 L246.2 99.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"246.2\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M315.0 95.0 L315.0 99.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"315.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">45</text><path d=\"M383.8 95.0 L383.8 99.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"383.8\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><path d=\"M452.5 95.0 L452.5 99.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"452.5\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">55</text><path d=\"M521.2 95.0 L521.2 99.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"521.2\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M590.0 95.0 L590.0 99.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"590.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">65</text><text x=\"315.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tempo de entrega, em minutos</text><circle cx=\"74.4\" cy=\"83.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"95.0\" cy=\"83.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"129.4\" cy=\"83.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"150.0\" cy=\"83.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"170.6\" cy=\"83.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"191.2\" cy=\"83.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"225.6\" cy=\"83.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"232.5\" cy=\"69.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"260.0\" cy=\"83.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"301.2\" cy=\"83.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"418.1\" cy=\"83.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><circle cx=\"535.0\" cy=\"83.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle></svg>", "caption": "Uma variável numérica tem lugar numa reta, então as distâncias significam algo: 61 está tão longe de 52,5 quanto 36 está de 27,5."}
```

Esse desenho já diz coisas que nenhum número sozinho diz. A maioria das entregas levou entre meia hora
e três quartos de hora. Duas demoraram mais, 52,5 e 61 minutos, e as duas foram para Barão Geraldo, o
bairro mais longe do depósito da Horta. Uma lista de doze números esconde isso; uma reta mostra num
relance.

## O que dá para fazer com quantidades

Tudo o que dava para fazer com uma categoria, e muito mais.

- **Somar.** As doze cestas totalizam R$ 950,05.
- **Tirar a média.** A aula 3 faz isso direito, e a aula 4 mostra quando uma média engana.
- **Medir o quanto se espalham.** Dois entregadores com o mesmo tempo médio de entrega podem ser muito
  diferentes na hora de confiar neles; a aula 5 mede isso.
- **Comparar por subtração e por razão.** 61 minutos são 33,5 minutos a mais que 27,5, e um pouco mais
  que o dobro do tempo.

O último item esconde uma sutileza que a aula 2 abre. Para algumas quantidades uma razão significa
algo, e para outras não. "O dobro do tempo" é uma frase justa sobre um tempo de entrega. "O dobro do
calor" não é uma frase justa sobre 30 °C contra 15 °C.

## Contagens também são numéricas

*itens* é uma contagem: 1, 2, 3, nunca 2,5. Mesmo assim é uma variável numérica. Os valores são
quantidades, os intervalos são reais, e a média de itens por pedido, 6,25, é um número útil, mesmo que
nenhum pedido tenha tido 6,25 itens. A aula 2 chama esse tipo de **discreto** e dá a ele um nome
próprio porque alguns métodos o tratam de outro jeito.

O que torna uma variável numérica não é ela estar escrita em dígitos. A próxima seção trata das
colunas escritas em dígitos que não são nada disso.
