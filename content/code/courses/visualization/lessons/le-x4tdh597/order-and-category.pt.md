---
title: O que um canal consegue dizer
version: 1
---

Antes de escolher um canal, pergunte que tipo de valor ele vai carregar. Há só dois tipos que
importam neste ponto.

- Uma **quantidade** tem um montante: pedidos, minutos, reais, quilômetros. Um valor pode ser o
  dobro de outro, e a distância entre 10 e 20 é a mesma que entre 30 e 40.
- Uma **categoria** é um nome: uma região, uma linha de produto, um meio de pagamento. As
  categorias são diferentes umas das outras, e só.

Algumas categorias têm ordem sem ter montante: *pequeno, médio, grande*, ou os meses do ano. Elas
ficam entre os dois tipos e pegam um pouco de cada um, o que volta a importar na aula 12.

## Canais com ordem, e canais sem

O erro comum é pensar na cor como um canal só. Ela é pelo menos dois, e os dois se comportam de
jeitos opostos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 200\" role=\"img\" data-fig=\"l01-ordered\" aria-label=\"Duas fileiras de seis quadrados. A de cima muda a luminosidade, de um azul claro a um escuro, e qualquer pessoa põe em ordem. A de baixo muda o matiz, vermelho, laranja, verde, azul, roxo e rosa, e não há ordem em que duas pessoas concordem.\"><rect x=\"250.0\" y=\"30.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#dbe4f7\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"250.0\" y=\"120.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#d1495b\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"302.0\" y=\"30.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#b0c4ee\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"302.0\" y=\"120.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#ed8b2d\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"354.0\" y=\"30.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#7f9fe3\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"354.0\" y=\"120.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#5aa65a\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"406.0\" y=\"30.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#5079d4\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"406.0\" y=\"120.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#3b7dd8\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"458.0\" y=\"30.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#2b52c9\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"458.0\" y=\"120.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#8a5cc7\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"510.0\" y=\"30.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#1a3380\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"510.0\" y=\"120.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#d665a8\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"236.0\" y=\"52.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">luminosidade: todo mundo ordena</text><text x=\"236.0\" y=\"142.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">matiz: ninguém concorda com a ordem</text></svg>", "caption": "Um canal que tem ordem pode carregar uma quantidade. O matiz não tem nenhuma, então serve para separar categorias e nunca para dizer qual é mais."}
```

**A luminosidade tem ordem.** Mostre a qualquer pessoa seis quadrados do azul claro ao escuro e ela
os ordena do mesmo jeito, então a luminosidade carrega uma quantidade, ainda que por alto. **O matiz
não tem ordem.** Vermelho, verde e roxo são diferentes, e nenhum leitor concorda sobre qual vem
primeiro. O matiz serve para separar categorias.

Isso dá uma regra que resolve a maioria das escolhas antes de elas começarem:

| canal | carrega quantidade? | separa categorias? |
|---|---|---|
| posição numa escala comum | sim, com precisão | sim |
| comprimento | sim, com precisão | mal, sozinho |
| ângulo, inclinação | sim, por alto | não |
| área | sim, mal | não |
| luminosidade, saturação | sim, por alto, como ordem | poucas, no máximo |
| matiz | **não** | **sim** |
| forma | **não** | sim, umas poucas |

## Os dois erros que isso evita

**Uma quantidade desenhada em matiz.** Um mapa em que a contagem de pedidos de cada estado escolhe
uma cor de um arco-íris não dá ao leitor jeito de saber se roxo é mais que laranja sem uma legenda,
e ele vai ler a legenda errado metade das vezes. A aula 12 é sobre as paletas que consertam isso.

**Uma categoria desenhada num canal com ordem.** Cinco linhas de produto desenhadas em cinco tons do
mesmo azul fazem o leitor procurar uma ordem que não existe: a linha mais escura parece a mais
importante. Cinco categorias pedem cinco matizes, ou cinco posições.

Nenhum dos dois gráficos está quebrado no sentido que um programa detecta. Os dois desenham certo,
e os dois dizem algo que o dado não diz.
