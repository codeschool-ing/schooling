---
title: Rótulos diretos e legendas
version: 1
---

Uma **legenda** é uma pequena tabela que liga cores ou formas a nomes, posta ao lado do gráfico. Um
**rótulo direto** escreve o nome sobre a marca ou ao lado dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 210\" role=\"img\" data-fig=\"l15-legend\" aria-label=\"Duas versões do gráfico de Nordeste e Sul. À esquerda as linhas são identificadas por uma caixa de legenda posta à direita do gráfico, então o olho tem de ir de cada linha até a caixa e voltar. À direita cada linha tem o nome na própria ponta, na própria cor.\"><text x=\"20.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma legenda</text><path d=\"M20.0 190.0 L210.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M20.0 163.5 L28.3 167.4 L36.5 158.3 L44.8 163.0 L53.0 158.9 L61.3 155.1 L69.6 170.0 L77.8 154.2 L86.1 148.5 L94.3 152.9 L102.6 150.8 L110.9 120.8 L119.1 150.3 L127.4 142.0 L135.7 144.1 L143.9 134.6 L152.2 145.0 L160.4 130.6 L168.7 138.3 L177.0 132.8 L185.2 127.3 L193.5 133.1 L201.7 130.7 L210.0 85.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\" stroke-linejoin=\"round\"></path><path d=\"M20.0 174.4 L28.3 176.3 L36.5 170.9 L44.8 168.4 L53.0 166.6 L61.3 160.1 L69.6 159.1 L77.8 158.9 L86.1 150.1 L94.3 148.6 L102.6 141.9 L110.9 116.9 L119.1 145.2 L127.4 135.1 L135.7 137.2 L143.9 128.0 L152.2 125.7 L160.4 119.9 L168.7 120.2 L177.0 112.2 L185.2 111.4 L193.5 99.6 L201.7 104.3 L210.0 52.4\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\" stroke-linejoin=\"round\"></path><rect x=\"230.0\" y=\"40.0\" width=\"96.0\" height=\"46.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M238.0 54.0 L256.0 54.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\"></path><text x=\"262.0\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Nordeste</text><path d=\"M238.0 72.0 L256.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"262.0\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Sul</text><text x=\"360.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">rótulos diretos</text><path d=\"M360.0 190.0 L550.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M360.0 163.5 L368.3 167.4 L376.5 158.3 L384.8 163.0 L393.0 158.9 L401.3 155.1 L409.6 170.0 L417.8 154.2 L426.1 148.5 L434.3 152.9 L442.6 150.8 L450.9 120.8 L459.1 150.3 L467.4 142.0 L475.7 144.1 L483.9 134.6 L492.2 145.0 L500.4 130.6 L508.7 138.3 L517.0 132.8 L525.2 127.3 L533.5 133.1 L541.7 130.7 L550.0 85.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\" stroke-linejoin=\"round\"></path><path d=\"M360.0 174.4 L368.3 176.3 L376.5 170.9 L384.8 168.4 L393.0 166.6 L401.3 160.1 L409.6 159.1 L417.8 158.9 L426.1 150.1 L434.3 148.6 L442.6 141.9 L450.9 116.9 L459.1 145.2 L467.4 135.1 L475.7 137.2 L483.9 128.0 L492.2 125.7 L500.4 119.9 L508.7 120.2 L517.0 112.2 L525.2 111.4 L533.5 99.6 L541.7 104.3 L550.0 52.4\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\" stroke-linejoin=\"round\"></path><text x=\"556.0\" y=\"52.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">Nordeste</text><text x=\"556.0\" y=\"89.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Sul</text></svg>", "caption": "Uma legenda é uma tabela de consulta. Um rótulo direto é a resposta, no lugar onde o olho já está, e funciona para um leitor que não distingue as cores."}
```

À esquerda o leitor olha uma linha, depois a legenda, casa a cor, lê o nome, e volta a procurar a
linha. Com duas linhas o custo é pequeno; com cinco é grande, e é pago de novo toda vez que o leitor
volta ao gráfico. À direita o nome está onde a linha termina, na cor da própria linha. **A consulta
sumiu.**

A aula 14 deu o outro motivo: um rótulo direto funciona para um leitor que não distingue as cores, e
uma legenda não.

## Onde pôr

| gráfico | o rótulo direto vai |
|---|---|
| linhas | na ponta direita de cada linha, onde o olho chega |
| barras | como o nome da categoria no eixo, e o valor na ponta da barra |
| barras empilhadas | dentro do segmento se couber, ao lado da última barra se não couber |
| dispersão | ao lado dos poucos pontos que importam; o resto fica sem rótulo |
| pizza (se for preciso) | ao lado de cada fatia |

## Quando uma legenda ainda é a certa

- **Muitas marcas pequenas**, como centenas de pontos em dois grupos: rotular cada um é impossível, e
  uma legenda para "chuva" e "seco" é mais clara que nada.
- **Pequenos múltiplos**, onde as mesmas cores se repetem em todo painel: uma legenda para todos, ou
  uma chave de cores no título, ganha de rotular cada painel.
- **Quando os rótulos colidiriam**: linhas que terminam quase no mesmo valor. Afaste os rótulos
  primeiro; recorra a uma legenda só quando isso falhar.

Quando uma legenda for necessária, **ponha-a perto do dado**, na mesma ordem em que as séries aparecem
no gráfico, e nunca faça o leitor rolar a página para achá-la.
