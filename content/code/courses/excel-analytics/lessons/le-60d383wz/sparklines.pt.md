---
title: Minigráficos, um gráfico numa célula
version: 1
---

**Um minigráfico é um gráfico do tamanho de uma célula: sem título, sem eixos, sem rótulos, só a
forma de uma linha de números.** Ele responde uma pergunta que uma tabela de números esconde, *para
onde isto está indo?*, e responde para todas as linhas de uma vez, ao lado dos próprios números.

## Uma grade para desenhar

Um minigráfico desenha uma linha (ou uma coluna) de um intervalo, então precisa dos números dispostos
em grade: produtos descendo pela lateral, meses atravessando o topo. Crie uma planilha chamada
`Trends`:

1. Digite `Product` em A1 e os seis códigos de produto em A2:A7, na ordem da planilha `Products`.
2. Digite a data `2025-01-01` em B1. Em C1 digite a fórmula abaixo e arraste para a direita até S1,
   o primeiro de junho de 2026.

```localised
=DATAM(B1;1)
```

3. Em B2, os sacos de um produto num mês:

```localised
=SOMASES(Sales[Bags]; Sales[Product]; $A2; Sales[Date]; ">="&B$1; Sales[Date]; "<"&DATAM(B$1;1))
```

`$A2` trava a coluna e deixa a linha andar, e `B$1` trava a linha e deixa a coluna andar: as
referências mistas da aula 2, que deixam uma fórmula só preencher a grade inteira. Arraste B2 para a
direita até S2, depois arraste B2:S2 para baixo até a linha 7. Confira a grade contra a tabela:

```localised
=SOMA(B2:S7)
```

Ela responde 591, todos os sacos dos dados da aula 1.

## Inserindo os minigráficos

Selecione T2:T7, escolha **Inserir › Minigráficos › Linha** (*Insert › Sparklines › Line* no Excel
em inglês), digite `B2:S7` em **Intervalo de dados** e clique em **OK**. O **Intervalo de locais** já
é T2:T7, as células que você selecionou. Cada uma das seis células passa a ter uma linha pequena, uma
por produto, com dezoito meses. Alargue a coluna T para as linhas terem espaço.

Na guia **Minigráfico**, **Mostrar › Ponto Alto** marca com um ponto o melhor mês de cada linha. Para
`CER1K` ele cai em outubro de 2025, 39 sacos; para `CER250` em julho de 2025, 6 sacos. A mesma guia
troca o tipo para **Coluna**, que serve a contagens como estas tanto quanto a linha, ou para
**Ganhos/Perdas**, que desenha só se cada valor está acima ou abaixo de zero.

## Cada um na sua escala, ou uma para todos

Por padrão cada minigráfico tem a escala dos próprios valores mais alto e mais baixo. Assim `CER250`,
cujo melhor mês teve 6 sacos, sobe até o topo da célula exatamente como `CER1K` faz com 39. Olhando a
coluna T de cima a baixo, os seis produtos parecem igualmente movimentados.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" data-fig=\"l12-sparklines\" aria-label=\"Sacos vendidos por mês, de janeiro de 2025 a junho de 2026, numa linha pequena por produto, desenhada duas vezes. Na primeira coluna cada linha tem a escala do próprio mês mais alto, então CER250, cujo melhor mês teve 6 sacos, oscila tanto quanto CER1K, cujo melhor teve 39. Na segunda coluna todas as linhas dividem uma escala, de 0 a 39 sacos, e os produtos pequenos ficam quase retos.\"><text x=\"130.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">cada minigráfico, a própria escala</text><text x=\"400.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">uma escala para todos, de 0 a 39</text><text x=\"668.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">melhor mês</text><rect x=\"30.0\" y=\"40.0\" width=\"700.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"44.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CER1K</text><path d=\"M130.0 57.3 L143.5 66.7 L157.1 70.0 L170.6 68.0 L184.1 60.7 L197.6 70.0 L211.2 67.3 L224.7 60.0 L238.2 67.3 L251.8 44.0 L265.3 61.3 L278.8 62.0 L292.4 53.3 L305.9 54.0 L319.4 70.0 L332.9 66.7 L346.5 65.3 L360.0 62.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"251.8\" cy=\"44.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><path d=\"M400.0 57.3 L413.5 66.7 L427.1 70.0 L440.6 68.0 L454.1 60.7 L467.6 70.0 L481.2 67.3 L494.7 60.0 L508.2 67.3 L521.8 44.0 L535.3 61.3 L548.8 62.0 L562.4 53.3 L575.9 54.0 L589.4 70.0 L602.9 66.7 L616.5 65.3 L630.0 62.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"521.8\" cy=\"44.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><text x=\"712.0\" y=\"57.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">39</text><rect x=\"30.0\" y=\"80.0\" width=\"700.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"44.0\" y=\"97.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CER250</text><path d=\"M130.0 110.0 L143.5 110.0 L157.1 110.0 L170.6 101.3 L184.1 88.3 L197.6 110.0 L211.2 84.0 L224.7 110.0 L238.2 110.0 L251.8 110.0 L265.3 97.0 L278.8 105.7 L292.4 97.0 L305.9 105.7 L319.4 110.0 L332.9 110.0 L346.5 101.3 L360.0 105.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"211.2\" cy=\"84.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><path d=\"M400.0 110.0 L413.5 110.0 L427.1 110.0 L440.6 108.7 L454.1 106.7 L467.6 110.0 L481.2 106.0 L494.7 110.0 L508.2 110.0 L521.8 110.0 L535.3 108.0 L548.8 109.3 L562.4 108.0 L575.9 109.3 L589.4 110.0 L602.9 110.0 L616.5 108.7 L630.0 109.3\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"481.2\" cy=\"106.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><text x=\"712.0\" y=\"97.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><rect x=\"30.0\" y=\"120.0\" width=\"700.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"44.0\" y=\"137.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">DEC250</text><path d=\"M130.0 148.6 L143.5 130.8 L157.1 124.0 L170.6 143.2 L184.1 137.7 L197.6 143.2 L211.2 148.6 L224.7 148.6 L238.2 150.0 L251.8 144.5 L265.3 150.0 L278.8 140.4 L292.4 145.9 L305.9 148.6 L319.4 150.0 L332.9 145.9 L346.5 144.5 L360.0 134.9\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"157.1\" cy=\"124.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><path d=\"M400.0 149.3 L413.5 140.7 L427.1 137.3 L440.6 146.7 L454.1 144.0 L467.6 146.7 L481.2 149.3 L494.7 149.3 L508.2 150.0 L521.8 147.3 L535.3 150.0 L548.8 145.3 L562.4 148.0 L575.9 149.3 L589.4 150.0 L602.9 148.0 L616.5 147.3 L630.0 142.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"427.1\" cy=\"137.3\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><text x=\"712.0\" y=\"137.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">19</text><rect x=\"30.0\" y=\"160.0\" width=\"700.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"44.0\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">MOG250</text><path d=\"M130.0 190.0 L143.5 178.6 L157.1 180.2 L170.6 190.0 L184.1 190.0 L197.6 170.5 L211.2 177.0 L224.7 172.1 L238.2 186.8 L251.8 190.0 L265.3 190.0 L278.8 164.0 L292.4 183.5 L305.9 186.8 L319.4 190.0 L332.9 190.0 L346.5 188.4 L360.0 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"278.8\" cy=\"164.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><path d=\"M400.0 190.0 L413.5 185.3 L427.1 186.0 L440.6 190.0 L454.1 190.0 L467.6 182.0 L481.2 184.7 L494.7 182.7 L508.2 188.7 L521.8 190.0 L535.3 190.0 L548.8 179.3 L562.4 187.3 L575.9 188.7 L589.4 190.0 L602.9 190.0 L616.5 189.3 L630.0 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"548.8\" cy=\"179.3\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><text x=\"712.0\" y=\"177.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">16</text><rect x=\"30.0\" y=\"200.0\" width=\"700.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"44.0\" y=\"217.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SUL1K</text><path d=\"M130.0 217.4 L143.5 227.0 L157.1 217.4 L170.6 216.6 L184.1 230.0 L197.6 212.2 L211.2 226.3 L224.7 224.1 L238.2 213.7 L251.8 230.0 L265.3 221.1 L278.8 230.0 L292.4 218.1 L305.9 230.0 L319.4 204.0 L332.9 230.0 L346.5 230.0 L360.0 230.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"319.4\" cy=\"204.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><path d=\"M400.0 218.7 L413.5 227.3 L427.1 218.7 L440.6 218.0 L454.1 230.0 L467.6 214.0 L481.2 226.7 L494.7 224.7 L508.2 215.3 L521.8 230.0 L535.3 222.0 L548.8 230.0 L562.4 219.3 L575.9 230.0 L589.4 206.7 L602.9 230.0 L616.5 230.0 L630.0 230.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"589.4\" cy=\"206.7\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><text x=\"712.0\" y=\"217.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">35</text><rect x=\"30.0\" y=\"240.0\" width=\"700.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"44.0\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SUL250</text><path d=\"M130.0 261.3 L143.5 248.3 L157.1 270.0 L170.6 261.3 L184.1 265.7 L197.6 261.3 L211.2 270.0 L224.7 252.7 L238.2 261.3 L251.8 265.7 L265.3 252.7 L278.8 270.0 L292.4 270.0 L305.9 261.3 L319.4 265.7 L332.9 244.0 L346.5 270.0 L360.0 270.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"332.9\" cy=\"244.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><path d=\"M400.0 268.7 L413.5 266.7 L427.1 270.0 L440.6 268.7 L454.1 269.3 L467.6 268.7 L481.2 270.0 L494.7 267.3 L508.2 268.7 L521.8 269.3 L535.3 267.3 L548.8 270.0 L562.4 270.0 L575.9 268.7 L589.4 269.3 L602.9 266.0 L616.5 270.0 L630.0 270.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"602.9\" cy=\"266.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><text x=\"712.0\" y=\"257.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"130.0\" y=\"290.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o ponto marca o ponto alto, como Minigráfico › Ponto Alto faz</text></svg>", "caption": "Minigráficos com escala própria mostram a forma dos meses de cada produto e escondem o tamanho; uma escala comum mostra o tamanho e achata os pequenos. Qual está certo depende de as linhas estarem sendo comparadas entre si."}
```

**Minigráfico › Eixo** muda isso. Em **Opções de Valor Máximo do Eixo Vertical** escolha **Igual para
Todos os Minigráficos** (*Same for All Sparklines*), e faça o mesmo em **Opções de Valor Mínimo do
Eixo Vertical**. Agora todas as linhas correm numa escala só, de 0 a 39 sacos, e os produtos pequenos
ficam quase retos, como produtos pequenos devem ficar.

Nenhum dos dois ajustes está errado. **Cada um na sua escala mostra a forma** dos dezoito meses de
cada produto, o que serve a quem pergunta se um produto está crescendo. **Uma escala para todos
mostra o tamanho**, o que serve a quem compara produtos. Diga qual dos dois a coluna usa, no
cabeçalho ou numa nota ao lado, porque um minigráfico não tem eixo para dizer por você.

## Um minigráfico é parte de uma célula

Um minigráfico não é um objeto flutuando sobre a planilha como um gráfico. Ele pertence à célula:
fica atrás do que a célula guarda, é impresso com ela e sai com **Minigráfico › Limpar**, não com a
tecla Delete, que o deixa onde está. Uma coluna deles ao lado de uma tabela de números é onde
funcionam melhor.
