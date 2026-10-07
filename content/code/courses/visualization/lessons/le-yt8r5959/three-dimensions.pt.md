---
title: Três dimensões da cor
version: 1
---

Uma tela faz toda cor com três luzes, vermelha, verde e azul, cada uma entre 0 e 255. `#2b52c9`, o azul
dos gráficos deste curso, é 43 de vermelho, 82 de verde e 201 de azul. Essa descrição, **RGB**, é como
o equipamento funciona, e é quase inútil para escolher cores: ninguém sabe dizer como é 43, 82, 201,
nem como deixá-la um pouco mais clara.

As pessoas descrevem a cor com três perguntas diferentes, e o desenho de gráficos usa as mesmas três.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 210\" role=\"img\" data-fig=\"l11-three\" aria-label=\"Três fileiras de amostras de cor. A primeira muda o matiz por toda a volta, vermelho, laranja, amarelo, verde, ciano, azul, roxo, magenta e de volta ao vermelho, em saturação máxima. A segunda mantém um matiz azul e muda a saturação, do cinza ao azul vivo. A terceira mantém o mesmo azul e muda a luminosidade, do preto ao branco.\"><rect x=\"130.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#ff0000\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#808080\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#030812\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"168.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#ff8000\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"168.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#747c8b\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"168.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#081837\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"206.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#ffff00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"206.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#687897\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"206.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#0d285c\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#80ff00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#5d74a2\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#133882\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"282.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#00ff00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"282.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#5170ae\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"282.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#1848a7\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#00ff80\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#466cb9\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#1d58cc\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"358.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#00ffff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"358.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#3a68c5\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"358.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#336de2\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"396.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#007fff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"396.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#2e64d1\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"396.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#5888e7\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"434.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#0000ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"434.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#2361dc\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"434.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#7da2ec\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#7f00ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#175de8\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#a3bdf2\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#ff00ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#0c59f3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#c8d8f7\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"548.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#ff0080\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"548.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#0055ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"548.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#edf2fc\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"118.0\" y=\"42.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">matiz</text><text x=\"118.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">saturação</text><text x=\"118.0\" y=\"166.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">luminosidade</text></svg>", "caption": "Três perguntas sobre qualquer cor: que família de cor (matiz), quanta cor contra o cinza (saturação), quão clara ou escura (luminosidade)."}
```

- **Matiz** responde *que cor?* Vermelho, laranja, amarelo, verde, azul, roxo. É medido como um ângulo
  numa volta, de 0 a 360 graus, com o vermelho em 0, o verde perto de 120 e o azul perto de 240, e a
  volta fecha de novo no vermelho.
- **Saturação**, também chamada de **croma**, responde *quanta cor, contra o cinza?* Em zero uma cor é
  um cinza; na saturação máxima ela é tão viva quanto pode ser.
- **Luminosidade** responde *quão clara ou escura?* Do preto, passando pela cor, até o branco.

## O que cada dimensão faz num gráfico

A aula 1 dividiu a cor em dois canais. Agora eles têm nome.

| dimensão | carrega ordem? | uso num gráfico |
|---|---|---|
| matiz | **não**: a volta não tem começo | separar categorias |
| luminosidade | **sim**: todo mundo ordena do claro ao escuro | mostrar mais e menos |
| saturação | fracamente | ênfase: viva no que importa, apagada no resto |

**A luminosidade é a dimensão que carrega quantidade**, e é também a que o olho lê com mais
confiança. Ela sobrevive à luz fraca, a um projetor ruim e a uma impressão em preto e branco, e, como
explica a aula 14, sobrevive para a maioria das pessoas que enxergam cores de outro jeito.

**A saturação é a dimensão da ênfase.** Uma única cor viva entre cores apagadas é para onde o olho vai
primeiro, o que a aula 13 usa de propósito e o que um gráfico cheio de cores vivas desperdiça.

## A versão do seletor de cores

A maioria dos programas expõe as três como **HSL** (matiz, saturação, luminosidade) ou o primo dele,
**HSV**. São fáceis de usar e não são o que dizem ser, que é a próxima seção.
