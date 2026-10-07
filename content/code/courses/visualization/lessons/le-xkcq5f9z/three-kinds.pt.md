---
title: Três tipos de dado, três tipos de paleta
version: 1
---

A aula 1 disse que o matiz separa e a luminosidade ordena. A aula 11 mediu os dois. Esta aula os
transforma na decisão que todo gráfico com cor tem de tomar: **de que tipo de paleta este dado
precisa?** São três, e quem decide é o dado, não o gosto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 220\" role=\"img\" data-fig=\"l12-three-kinds\" aria-label=\"Três fileiras de amostras. Categórica: oito matizes bem diferentes de peso parecido, laranja, azul-celeste, verde, amarelo, azul, vermelhão, rosa e preto. Sequencial: sete passos do viridis, do roxo escuro, passando por azul e verde, ao amarelo vivo, sempre clareando. Divergente: sete passos de uma escala do vermelho ao azul, vermelho escuro, vermelho claro, quase branco no meio, azul claro, azul escuro.\"><text x=\"20.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">categórica: tipos de coisa</text><rect x=\"20.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#E69F00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"60.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#56B4E9\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"100.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#009E73\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"140.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#F0E442\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"180.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#0072B2\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"220.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#D55E00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"260.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#CC79A7\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"300.0\" y=\"30.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#000000\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"20.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sequencial: do baixo ao alto</text><rect x=\"20.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#440154\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"60.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#443983\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"100.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#31688e\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"140.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#21918c\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"180.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#35b779\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"220.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#90d743\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"260.0\" y=\"96.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#fde725\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"20.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">divergente: abaixo e acima de um meio</text><rect x=\"20.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#67001f\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"60.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#c94741\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"100.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#f7b799\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"140.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#f6f7f7\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"180.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#a7d0e4\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"220.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#3783bb\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"260.0\" y=\"162.0\" width=\"36.0\" height=\"30.0\" rx=\"2\" fill=\"#053061\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect></svg>", "caption": "Três tipos de paleta para três tipos de dado. O matiz separa tipos; a luminosidade ordena quantidades; dois matizes que se encontram num meio claro mostram de que lado de uma referência um valor está."}
```

| o dado | a paleta | feita de |
|---|---|---|
| categorias sem ordem: regiões, produtos | **categórica** | matizes diferentes com luminosidade parecida |
| quantidades do baixo ao alto: pedidos, receita | **sequencial** | uma direção de luminosidade, do claro ao escuro |
| quantidades em volta de um meio com significado: variação, diferença para uma meta, correlação | **divergente** | dois matizes que se encontram num centro claro |

A pergunta que resolve é **"o meio significa alguma coisa?"** Se os valores só sobem, é sequencial.
Se o zero, ou uma meta, ou uma média os divide em dois lados com significado, é divergente. Se os
valores são nomes, é categórica.

## Os erros são todos descompassos

- **Uma paleta categórica em quantidades.** Cada valor ganha um matiz sem relação com os outros, e o
  leitor tem de consultar uma legenda para saber que verde é mais que roxo.
- **Uma paleta sequencial em categorias.** Cinco produtos em cinco tons de azul, e o leitor procura
  uma ordem que os produtos não têm, como a aula 1 avisou.
- **Uma paleta divergente em quantidades sem meio.** Contagens de pedidos pintadas do vermelho ao
  azul fazem a metade de baixo parecer um problema, quando ela só é menor.
- **Uma paleta sequencial em dado com meio.** Um mapa de lucro e prejuízo num matiz só esconde quais
  regiões perdem dinheiro, porque a linha entre os dois é só mais um tom.

As próximas duas seções tratam de cada tipo.
