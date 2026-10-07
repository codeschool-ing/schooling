---
title: Uma linha é para mudança
version: 1
---

Um gráfico de linhas desenha um ponto por momento e **liga os pontos em ordem**. A ligação é a ideia
toda: ela diz ao leitor que os pontos pertencem a uma coisa contínua medida de novo e de novo, e a
inclinação entre dois pontos é a velocidade com que essa coisa mudou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 270\" role=\"img\" data-fig=\"l04-total\" aria-label=\"Uma linha dos pedidos totais da Horta por mês de janeiro de 2024 a dezembro de 2025. Ela sobe de 10.552 para 20.586, com um pico forte a cada dezembro, 16.663 em 2024 e 20.586 em 2025, e uma queda de volta no janeiro seguinte.\"><path d=\"M70.0 40.0 L70.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 220.0 L70.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 179.1 L600.0 179.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 179.1 L70.0 179.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"179.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5.000</text><path d=\"M70.0 138.2 L600.0 138.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 138.2 L70.0 138.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"138.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.000</text><path d=\"M70.0 97.3 L600.0 97.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 97.3 L70.0 97.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"97.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15.000</text><path d=\"M70.0 56.4 L600.0 56.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 56.4 L70.0 56.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"56.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20.000</text><text x=\"70.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pedidos por mês</text><path d=\"M70.0 220.0 L600.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 220.0 L70.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jan 2024</text><path d=\"M208.3 220.0 L208.3 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"208.3\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jul</text><path d=\"M346.5 220.0 L346.5 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"346.5\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jan 2025</text><path d=\"M484.8 220.0 L484.8 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"484.8\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jul</text><path d=\"M600.0 220.0 L600.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"600.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dez</text><path d=\"M70.0 133.7 L93.0 133.2 L116.1 130.1 L139.1 128.9 L162.2 126.7 L185.2 126.9 L208.3 125.0 L231.3 121.6 L254.3 119.3 L277.4 118.0 L300.4 118.8 L323.5 83.7 L346.5 110.6 L369.6 111.1 L392.6 106.8 L415.7 106.1 L438.7 105.4 L461.7 97.0 L484.8 101.1 L507.8 95.5 L530.9 93.5 L553.9 91.8 L577.0 91.1 L600.0 51.6\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\" stroke-linejoin=\"round\"></path><circle cx=\"323.5\" cy=\"83.7\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"600.0\" cy=\"51.6\" r=\"3.5\" fill=\"var(--amber)\"></circle></svg>", "caption": "Uma linha liga os meses em ordem, então o olho lê a inclinação como mudança: um crescimento constante, e um pico de dezembro que cai de volta todo janeiro."}
```

Os pedidos totais da Horta sobem de 10.552 em janeiro de 2024 para 20.586 em dezembro de 2025. A
linha torna visíveis de uma vez três coisas que uma tabela de 24 números esconde:

- **a tendência**: para cima, de forma constante, nos dois anos;
- **a sazonalidade**: um pico em todo dezembro, 16.663 em 2024 e 20.586 em 2025;
- **a volta**: cada pico cai de novo em janeiro, o que diz que os pedidos de dezembro são um evento,
  e não um novo patamar.

## Quando uma linha acerta, e quando não

**Use uma linha quando o eixo horizontal for contínuo e ordenado**, o que quase sempre quer dizer
tempo: dias, meses, anos. A linha entre janeiro e fevereiro diz que fevereiro veio depois de janeiro
e que alguma coisa aconteceu no meio.

**Não ligue categorias.** Uma linha que passa por Sudeste, Sul, Nordeste, Centro-Oeste e Norte
desenha uma inclinação entre duas regiões, e uma inclinação entre regiões não significa nada:
ninguém viaja do Sul ao Nordeste a alguma taxa. Categorias pedem barras (aula 3).

**Cuidado com as lacunas.** Se falta um mês, uma linha traçada reta por cima da lacuna inventa os
valores do meio. Deixe a linha quebrada, ou marque o mês que falta, para o leitor ver que ali nada
foi medido.

## Pontos ou sem pontos

Marcadores em cada ponto ajudam quando há **poucos pontos** (uma dúzia de anos, uma dúzia de meses)
ou quando os valores exatos importam. Com centenas de pontos eles viram ruído; a linha sozinha fica
mais limpa.
