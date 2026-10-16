---
title: Orçado contra realizado
version: 1
---

Toda área tem um orçamento, e todo mês alguém o compara com o que aconteceu. A comparação tem nome,
**a variação: realizado menos orçado**, e uma porcentagem, a variação dividida pelo orçado. A conta
cabe numa linha. Ler a conta ocupa o resto desta seção, porque um sinal de mais é boa notícia em algumas
linhas e má notícia em outras, e uma variação favorável às vezes não é boa notícia nenhuma.

## O novembro da Renata, na sua planilha

O orçamento de novembro da área de marketing e o que foi gasto, em milhares de reais. A primeira linha é
receita, o dinheiro que a área deveria trazer; as outras são custos. Digite numa aba nova a partir de
A1:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Linha | Tipo | Orçado | Realizado |
| 2 | Vendas online | receita | 1900 | 2060 |
| 3 | Busca paga | custo | 90 | 96 |
| 4 | Anúncios em redes | custo | 70 | 84 |
| 5 | Plataforma de e-mail | custo | 10 | 9 |
| 6 | Produção de conteúdo | custo | 30 | 22 |
| 7 | Ofertas de frete grátis | custo | 40 | 52 |

Em E1 digite `Variação` e em E2:

```localised
=D2-C2      160
```

Em F1 digite `Variação %` e em F2 a variação como parte do orçado, com uma casa decimal:

```localised
=ARRED(E2/C2*100;1)      8,4
```

Copie E2 e F2 até a linha 7. As vendas vieram R$ 160 mil, 8,4%, acima do orçado. Os anúncios em redes
mostram **14** e **20**: R$ 14 mil acima de um orçamento de R$ 70 mil.

## O sinal não diz se é bom

Uma variação positiva na linha de vendas é boa notícia; numa linha de custo, quer dizer que se gastou
mais que o planejado. Então o veredito depende do tipo da linha, e a planilha consegue escrevê-lo. Em G1
digite `Veredito`, e em G2:

```localised
=SE(B2="receita";SE(E2>=0;"F";"D");SE(E2<=0;"F";"D"))      F
```

F é favorável e D, desfavorável. Leia de fora para dentro: se a linha é receita, é favorável quando a
variação é zero ou mais; senão é custo, e é favorável quando a variação é zero ou menos. Copie G2 até
G7. **Sua coluna G deve mostrar F, D, D, F, F, D.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Barras horizontais da variação de novembro contra o orçamento, em milhares de reais, para seis linhas. Vendas online +160, favorável. Busca paga +6, anúncios em redes +14 e ofertas de frete grátis +12, todos custos acima do orçamento e portanto desfavoráveis. Plataforma de e-mail −1 e produção de conteúdo −8, custos abaixo do orçamento e portanto favoráveis. Barras para a direita estão acima do orçamento; a cor diz se isso é bom.\" data-fig=\"l15-variance\"><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">variação, R$ mil: abaixo do orçamento ← → acima do orçamento</text><path d=\"M360.0 36.0 L360.0 244.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"150.0\" y=\"60.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Vendas online</text><text x=\"156.0\" y=\"60.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">(receita)</text><path d=\"M360.0 48.0 H616.0 V66.0 H360.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"622.0\" y=\"61.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+160  F</text><text x=\"150.0\" y=\"94.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Busca paga</text><text x=\"156.0\" y=\"94.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">(custo)</text><path d=\"M360.0 82.0 H369.6 V100.0 H360.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"375.6\" y=\"95.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+6  D</text><text x=\"150.0\" y=\"128.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Anúncios em redes</text><text x=\"156.0\" y=\"128.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">(custo)</text><path d=\"M360.0 116.0 H382.4 V134.0 H360.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"388.4\" y=\"129.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+14  D</text><text x=\"150.0\" y=\"162.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Plataforma de e-mail</text><text x=\"156.0\" y=\"162.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">(custo)</text><path d=\"M358.0 150.0 H360.0 V168.0 H358.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"352.0\" y=\"163.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">−1  F</text><text x=\"150.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Produção de conteúdo</text><text x=\"156.0\" y=\"196.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">(custo)</text><path d=\"M347.2 184.0 H360.0 V202.0 H347.2 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"341.2\" y=\"197.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">−8  F</text><text x=\"150.0\" y=\"230.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Ofertas de frete grátis</text><text x=\"156.0\" y=\"230.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">(custo)</text><path d=\"M360.0 218.0 H379.2 V236.0 H360.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"385.2\" y=\"231.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">+12  D</text><path d=\"M170.0 263.0 H184.0 V277.0 H170.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"190.0\" y=\"274.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">F: favorável</text><path d=\"M330.0 263.0 H344.0 V277.0 H330.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"350.0\" y=\"274.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">D: desfavorável</text></svg>", "caption": "O mesmo sinal quer dizer coisas opostas nos dois tipos de linha. Vendas acima do orçamento são boa notícia; um custo acima do orçamento não é, e um custo abaixo só é boa notícia se for economia."}
```

Por último, os custos da área juntos. Em A8 digite `Custo total`, e em C8 e D8:

```localised
=SOMA(C3:C7)      240
=SOMA(D3:D7)      263
```

Copie E7 e F7 para a linha 8: os custos ficaram **R$ 23 mil, 9,6%, acima do orçado**, enquanto as vendas
ficaram 8,4% acima. O custo do marketing como parte das vendas online foi de 12,6% no orçamento para
12,8% no mês:

```localised
=ARRED(C8/C2*100;1)      12,6
=ARRED(D8/D2*100;1)      12,8
```

Gastar mais que o planejado para vender mais que o planejado não é fracasso. Gastar um pouco mais de
cada real vendido em marketing do que se planejou é um fato que merece uma frase na reunião, não uma
crise.

## Três coisas que a variação não diz

**Uma variação favorável nem sempre é economia.** A produção de conteúdo veio R$ 8 mil abaixo do
orçado, 26,7%, e a coluna diz F. O motivo é que a sessão de fotos do catálogo de verão escorregou do
fim de novembro para a primeira semana de dezembro. Nada foi economizado: dezembro vai ficar R$ 8 mil
acima, e a reunião dele vai mostrar um D por um dinheiro que ia ser gasto de qualquer jeito. **Uma
variação de prazo se move entre meses; uma real não volta.** A reunião pergunta de que tipo é cada uma
antes de elogiar alguém.

**Uma variação desfavorável pode ser o custo de um sucesso.** As ofertas de frete grátis ficaram R$ 12
mil, 30%, acima do orçado. Parte disso é volume: o orçamento supunha 4.800 pedidos e vieram 5.150, então
mais clientes usaram a oferta. Parte não é. Dividida pelos pedidos, a oferta custou R$ 10,10 por pedido
contra os R$ 8,33 que o orçamento implicava, então uma parcela maior dos clientes a escolheu. A primeira
parte acompanhou o sucesso; a segunda é uma pergunta para a Renata, e a variação sozinha não separa as
duas.

**Uma porcentagem precisa do tamanho ao lado.** Os −10% da plataforma de e-mail parecem tão grandes
quanto qualquer coisa na planilha, e são R$ 1 mil. Os +20% dos anúncios em redes são R$ 14 mil. A
reunião da Renata discute uma variação só quando ela passa de R$ 5 mil e de 10% da linha: na planilha de
novembro, isso dá anúncios em redes, produção de conteúdo e frete grátis. É um limiar, escolhido como a
aula 14 escolheu o dela: contando o que cada linha teria apontado, e ficando com o que deixa a reunião
com algo para decidir.
