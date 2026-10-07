---
title: Dedos, não ponteiros
version: 1
---

Um ponteiro de mouse tem um pixel de largura. Um dedo não, e ele cobre o que está tentando tocar.
Duas coisas decorrem disso para um painel no celular.

## Alvos grandes o bastante para acertar

Cada controle que o leitor toca, um filtro, uma aba, um botão que abre um detalhe, precisa ser grande
o bastante para ser acertado sem acertar o vizinho.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 170\" role=\"img\" data-fig=\"l19-targets\" aria-label=\"Quatro quadrados comparados na mesma escala: 16 pixels CSS, o tamanho de uma setinha de filtro; 24, o mínimo que a WCAG 2.2 pede no nível AA; 44 pontos, a recomendação da Apple; e 48 pixels independentes de densidade, a recomendação do Material, do Google.\"><rect x=\"30.0\" y=\"88.0\" width=\"32.0\" height=\"32.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">16 px: uma setinha</text><rect x=\"166.0\" y=\"72.0\" width=\"48.0\" height=\"48.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"166.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">24 px: mínimo da WCAG 2.2</text><rect x=\"302.0\" y=\"32.0\" width=\"88.0\" height=\"88.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"302.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">44 pt: Apple</text><rect x=\"438.0\" y=\"24.0\" width=\"96.0\" height=\"96.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"438.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">48 dp: Material</text></svg>", "caption": "Um dedo não é um ponteiro de mouse. O piso da WCAG é 24 por 24 pixels CSS; os guias das plataformas pedem quase o dobro, e os filtros de um painel devem segui-los.", "same": ["44 pt: Apple", "48 dp: Material"]}
```

- A **WCAG 2.2** pede, no nível AA, alvos de **pelo menos 24 por 24 pixels CSS**, ou espaço suficiente
  em volta de um menor para que um círculo de 24 pixels centrado nele não toque nenhum outro alvo.
- As Human Interface Guidelines da **Apple** recomendam pelo menos **44 por 44 pontos**, e o Material
  Design do **Google**, **48 por 48 pixels independentes de densidade**. As duas unidades são
  próximas de um pixel CSS.

O número da WCAG é o piso contra o qual um site pode ser auditado; os das plataformas são o que é
confortável. Os filtros de um painel devem mirar no segundo. A setinha que abre um menu suspenso em
muitos painéis de computador tem uns 16 pixels, pequena demais até para o piso.

## Nada que dependa de passar o mouse

Uma dica que aparece quando o ponteiro para sobre um ponto é um hábito de computador, e no celular
não há ponteiro parado. Telas de toque transformam o passar do mouse num toque, na melhor das
hipóteses, e o toque muitas vezes dispara outra coisa.

Então tudo de que o leitor precisa deve estar **visível sem passar o mouse**:

- os valores principais escritos no gráfico, como rótulos diretos;
- as unidades no título ou no eixo;
- a comparação no cartão, não numa dica atrás dele.

Uma dica ainda pode acrescentar detalhe para quem quiser, desde que ninguém precise dela para
entender o gráfico.
