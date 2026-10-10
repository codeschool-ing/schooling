---
title: Crescimento ao longo dos anos, nominal e real
version: 1
---

Um conselho pergunta quanto a empresa cresceu, e duas respostas fáceis estão erradas. Somar as taxas de
crescimento anuais exagera, porque cada ano cresce sobre uma base maior. Citar o crescimento em reais
exagera de novo, porque um real de 2025 compra menos que um real de 2021. **O número do conselho é a
taxa de crescimento anual composta, em termos reais**, e esta seção a calcula para a Varanda na sua
planilha.

## Cinco anos na sua planilha

As vendas da Varanda de 2021 a 2025 em milhões de reais, e um índice de preços que começa em 100 em
2021. **O índice é ilustrativo**: foi escrito para esta aula, sobe entre 4% e 6% ao ano, e não é o IPCA
nem qualquer série oficial. Num pacote de verdade, esta coluna é o índice oficial dos mesmos anos, e o
pacote diz qual. Digite numa aba nova a partir de A1:

| | A | B | C |
|---|---|---|---|
| 1 | Ano | Vendas | Índice |
| 2 | 2021 | 72,4 | 100 |
| 3 | 2022 | 80,1 | 106 |
| 4 | 2023 | 86,3 | 110,8 |
| 5 | 2024 | 92,7 | 115,6 |
| 6 | 2025 | 98,0 | 120,4 |

## Vendas reais

Vendas em reais de 2021: divida cada ano pelo seu índice e multiplique por 100. Em D1 digite `Real` e
em D2:

```localised
=ARRED(B2/C2*100;1)      72,4
```

Copie até D6. **Sua coluna D deve terminar em 81,4.** Em reais de 2021, a Varanda vendeu R$ 81,4
milhões em 2025, não R$ 98,0 milhões. Os R$ 25,6 milhões que ela somou em reais de cada ano são R$ 9,0
milhões em reais de 2021: cerca de um terço do crescimento foi vender mais, e o resto foi preço mais
alto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Duas linhas de 2021 a 2025. As vendas em reais de cada ano sobem de 72,4 para 98,0 milhões. As mesmas vendas em reais de 2021 sobem de 72,4 para 81,4 milhões. A distância entre as linhas, a parte do crescimento que foi preço, aumenta a cada ano.\" data-fig=\"l16-real\"><path d=\"M84.0 260.0 L90.0 260.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"80.0\" y=\"264.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">70</text><path d=\"M84.0 186.7 L90.0 186.7\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"80.0\" y=\"190.7\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">80</text><path d=\"M84.0 113.3 L90.0 113.3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"80.0\" y=\"117.3\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">90</text><path d=\"M84.0 40.0 L90.0 40.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"80.0\" y=\"44.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">100</text><path d=\"M90.0 32.0 L90.0 260.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><path d=\"M90.0 260.0 L570.0 260.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"90.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2021</text><text x=\"207.5\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2022</text><text x=\"325.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2023</text><text x=\"442.5\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2024</text><text x=\"560.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2025</text><text x=\"24.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">R$ milhões</text><path d=\"M90.0 242.4 L207.5 185.9 L325.0 140.5 L442.5 93.5 L560.0 54.7\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><path d=\"M90.0 242.4 L207.5 218.9 L325.0 202.1 L442.5 185.2 L560.0 176.4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><text x=\"574.0\" y=\"58.7\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">98,0 em reais de cada ano</text><text x=\"574.0\" y=\"180.4\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">81,4 em reais de 2021</text><text x=\"94.0\" y=\"306.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Preços: um índice ilustrativo, 2021 = 100, chegando a 120,4 em 2025.</text></svg>", "caption": "Vendas nominais e reais. Dos R$ 25,6 milhões que a Varanda somou entre 2021 e 2025, a maior parte foi preço; a linha real cresceu R$ 9,0 milhões em reais de 2021."}
```

## Crescimento ano a ano

Em E1 digite `Crescimento %`, e em E3 o crescimento de 2022 sobre 2021:

```localised
=ARRED((B3/B2-1)*100;1)      10,6
```

Copie até E6, e faça o mesmo para a coluna real em F, começando com `=ARRED((D3/D2-1)*100;1)` em F3. As
duas colunas contam duas histórias:

| ano | crescimento em reais | crescimento em termos reais |
|---|---|---|
| 2022 | 10,6% | 4,4% |
| 2023 | 7,7% | 3,0% |
| 2024 | 7,4% | 3,0% |
| 2025 | 5,7% | 1,5% |

Os 5,7% de 2025 são o número que a aula 1 citou. Estava certo lá e está certo aqui; **em termos reais
são 1,5%**, e esse é o que interessa a um conselho que vai decidir sobre mais cinco anos.

## Uma taxa para o período inteiro

O crescimento total de 2021 a 2025 em reais é 35,4%. Dividido pelos quatro anos, parece 8,8% ao ano, o
que está errado, porque cada ano cresceu em cima do anterior. A taxa que, composta, leva 72,4 a 98,0 é a
**taxa de crescimento anual composta, a CAGR**:

```localised
=ARRED(((B6/B2)^(1/4)-1)*100;1)      7,9
```

O `^(1/4)` é a raiz quarta, e o 4 é o número que mais se erra. **De 2021 a 2025 são cinco anos de
números e quatro anos de crescimento**: do primeiro ao último há quatro passos. Com um 5 no lugar, a
fórmula responde 6,2, uma taxa que, composta, não chega a 98,0. Confira os 7,9 fazendo 72,4 crescer
quatro vezes:

```localised
=ARRED(72,4*1,079^4;1)      98,1
```

98,1 contra 98,0 é o arredondamento da taxa a uma casa decimal. A mesma fórmula na coluna real:

```localised
=ARRED(((D6/D2)^(1/4)-1)*100;1)      3
```

**7,9% ao ano em reais, 3,0% ao ano em termos reais.** Nos mesmos quatro anos, o índice ilustrativo
subiu 20,4% no total.

## Mesmas lojas: crescimento que foi comprado

Mais uma coisa infla um total. Ipatinga, a nona loja, abriu em julho de 2024 e vendeu R$ 7,04 milhões em
2025. Tire as vendas dela de 2025 e a CAGR nominal desde 2021 cai de 7,9% para 5,9%. **Parte do
crescimento da Varanda foi uma loja nova, não mais vendas das lojas que ela já tinha.** Isso não é bom
nem ruim: abrir lojas é uma estratégia. Mas um conselho que lê o crescimento total como a saúde do
negócio existente é enganado justamente pela loja que decidiu abrir. A aula 18 separa as duas coisas
direito, com o crescimento em mesmas lojas, que compara só as lojas abertas nos dois períodos.

A mesma correção vale para as vendas por metro quadrado. Em reais, subiram 0,2% de 2023 a 2025.
Deflacionadas pelo mesmo índice, caíram **7,8%**: cada metro quadrado de salão da Varanda vendeu menos,
em termos reais, em 2025 do que em 2023. Esse é o número por trás da pergunta sobre fechar uma loja.
