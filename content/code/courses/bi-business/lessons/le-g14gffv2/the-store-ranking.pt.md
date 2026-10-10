---
title: O ranking das lojas, calculado
version: 1
---

A proposta de Helena se apoia num ranking: Contagem é a que mais vende, logo é a melhor loja, logo
merece mais área. **O ranking está certo e a conclusão não decorre dele**, porque a loja que mais vende
pode ser só a loja com mais espaço. O jeito de descobrir é dividir, e isso ocupa uma coluna na
planilha que você começou na aula 1.

## A tabela

Acrescente uma aba nova ao seu arquivo. Digite as nove lojas com as vendas de 2025, em milhares de
reais, e a área de vendas em metros quadrados. A loja online fica de fora desta vez: ela não tem área
para ampliar.

| | A | B | C |
|---|---|---|---|
| 1 | Loja | Vendas | Área |
| 2 | Savassi | 11880 | 1800 |
| 3 | Pampulha | 10560 | 2400 |
| 4 | Contagem | 12480 | 3200 |
| 5 | Betim | 8840 | 2600 |
| 6 | Nova Lima | 9450 | 1500 |
| 7 | Sete Lagoas | 6720 | 2100 |
| 8 | Divinópolis | 6460 | 1900 |
| 9 | Ipatinga | 7040 | 2200 |
| 10 | Juiz de Fora | 8960 | 2800 |

## Vendas por metro quadrado

Em D1 digite `Por m2`. As vendas estão em milhares, então multiplique por 1.000 para chegar a reais,
divida pela área e arredonde para reais inteiros. Em D2:

```localised
=ARRED(B2*1000/C2;0)      6600
```

Copie D2 até D10. A Savassi vende **R$ 6.600 por ano para cada metro quadrado** da sua área. Sua
coluna deve mostrar 6600, 4400, 3900, 3400, 6300, 3200, 3400, 3200, 3200.

Depois uma linha de total, para que cada loja tenha com o que ser comparada. Em A11 digite `Total`, e:

```localised
B11   =SOMA(B2:B10)      82390
C11   =SOMA(C2:C10)      20500
D11   =ARRED(B11*1000/C11;0)      4019
```

As nove lojas venderam R$ 82,39 milhões em 20.500 metros quadrados, uma média de **R$ 4.019 por metro
quadrado**. Repare que D11 divide os dois totais; ela não tira a média dos nove valores acima. Tirar a
média deles daria a cada loja o mesmo peso, qualquer que fosse o tamanho, o que é outro número, e
o número errado aqui.

## Dois rankings das mesmas lojas

Ordene a tabela pela coluna B, do maior para o menor, e depois pela coluna D: selecione A1:D10 e use a
ordenação do menu **Dados**, que fica no mesmo lugar no LibreOffice, no Excel e no Google Planilhas.
As duas ordens:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 430\" role=\"img\" aria-label=\"Duas listas ordenadas das nove lojas ligadas por linhas. À esquerda, por vendas de 2025: Contagem primeiro, depois Savassi, Pampulha, Nova Lima, Juiz de Fora, Betim, Ipatinga, Sete Lagoas, Divinópolis. À direita, por vendas por metro quadrado: Savassi 6.600, Nova Lima 6.300, Pampulha 4.400, Contagem 3.900, Betim e Divinópolis 3.400, Juiz de Fora, Ipatinga e Sete Lagoas 3.200. A linha de Contagem cai de primeiro para quarto; a de Nova Lima sobe de quarto para segundo.\" data-fig=\"l02-ranking\"><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">por vendas, R$ mil</text><text x=\"440.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">por vendas por m², R$</text><path d=\"M282.0 92.0 L438.0 200.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><path d=\"M282.0 128.0 L438.0 92.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M282.0 164.0 L438.0 164.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M282.0 200.0 L438.0 128.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><path d=\"M282.0 236.0 L438.0 308.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M282.0 272.0 L438.0 236.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M282.0 308.0 L438.0 344.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M282.0 344.0 L438.0 380.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M282.0 380.0 L438.0 272.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><rect x=\"40.0\" y=\"78.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"97.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">1</text><text x=\"74.0\" y=\"97.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Contagem</text><text x=\"270.0\" y=\"97.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">12.480</text><rect x=\"40.0\" y=\"114.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"133.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">2</text><text x=\"74.0\" y=\"133.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Savassi</text><text x=\"270.0\" y=\"133.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">11.880</text><rect x=\"40.0\" y=\"150.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"169.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3</text><text x=\"74.0\" y=\"169.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Pampulha</text><text x=\"270.0\" y=\"169.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">10.560</text><rect x=\"40.0\" y=\"186.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"205.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">4</text><text x=\"74.0\" y=\"205.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Nova Lima</text><text x=\"270.0\" y=\"205.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">9.450</text><rect x=\"40.0\" y=\"222.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"241.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">5</text><text x=\"74.0\" y=\"241.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Juiz de Fora</text><text x=\"270.0\" y=\"241.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">8.960</text><rect x=\"40.0\" y=\"258.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"277.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">6</text><text x=\"74.0\" y=\"277.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Betim</text><text x=\"270.0\" y=\"277.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">8.840</text><rect x=\"40.0\" y=\"294.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"313.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">7</text><text x=\"74.0\" y=\"313.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Ipatinga</text><text x=\"270.0\" y=\"313.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">7.040</text><rect x=\"40.0\" y=\"330.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"349.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">8</text><text x=\"74.0\" y=\"349.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Sete Lagoas</text><text x=\"270.0\" y=\"349.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">6.720</text><rect x=\"40.0\" y=\"366.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50.0\" y=\"385.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">9</text><text x=\"74.0\" y=\"385.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Divinópolis</text><text x=\"270.0\" y=\"385.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">6.460</text><rect x=\"440.0\" y=\"78.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"97.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">1</text><text x=\"474.0\" y=\"97.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Savassi</text><text x=\"670.0\" y=\"97.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">6.600</text><rect x=\"440.0\" y=\"114.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"133.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">2</text><text x=\"474.0\" y=\"133.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Nova Lima</text><text x=\"670.0\" y=\"133.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">6.300</text><rect x=\"440.0\" y=\"150.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"169.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3</text><text x=\"474.0\" y=\"169.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Pampulha</text><text x=\"670.0\" y=\"169.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">4.400</text><rect x=\"440.0\" y=\"186.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"205.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">4</text><text x=\"474.0\" y=\"205.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Contagem</text><text x=\"670.0\" y=\"205.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3.900</text><rect x=\"440.0\" y=\"222.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"241.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">5</text><text x=\"474.0\" y=\"241.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Betim</text><text x=\"670.0\" y=\"241.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3.400</text><rect x=\"440.0\" y=\"258.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"277.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">6</text><text x=\"474.0\" y=\"277.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Divinópolis</text><text x=\"670.0\" y=\"277.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3.400</text><rect x=\"440.0\" y=\"294.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"313.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">7</text><text x=\"474.0\" y=\"313.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Juiz de Fora</text><text x=\"670.0\" y=\"313.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3.200</text><rect x=\"440.0\" y=\"330.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"349.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">8</text><text x=\"474.0\" y=\"349.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Ipatinga</text><text x=\"670.0\" y=\"349.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3.200</text><rect x=\"440.0\" y=\"366.0\" width=\"240.0\" height=\"28.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"385.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">9</text><text x=\"474.0\" y=\"385.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Sete Lagoas</text><text x=\"670.0\" y=\"385.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3.200</text><text x=\"360.0\" y=\"418.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">mesmas lojas, mesmo ano: a pergunta decide a ordem</text></svg>", "caption": "As nove lojas ordenadas duas vezes. Contagem vende mais porque é a maior; por metro quadrado ela é a quarta, vendendo 59% do que a Savassi vende em cada metro.", "same": ["Betim", "Contagem", "Divinópolis", "Ipatinga", "Juiz de Fora", "Nova Lima", "Pampulha", "Savassi", "Sete Lagoas"]}
```

**Contagem cai de primeiro para quarto.** Ela tem 1,8 vez a área da Savassi e vende 1,05 vez o que
a Savassi vende, então cada metro quadrado dela vende 59% do que vende um metro da Savassi:

```localised
=ARRED(D4/D2*100;0)      59
```

Nova Lima, a menor loja, sobe de quarto para segundo. Três lojas empatam embaixo com R$ 3.200, e duas
acima delas com R$ 3.400; a classificação as deixa na ordem em que as encontrou, e um relatório deve
dizer que estão empatadas em vez de pôr uma acima da outra.

Diante dos R$ 4.019 da rede, os R$ 3.900 de Contagem ficam logo abaixo da média. Ela é a maior loja,
com 15,6% da área da rede e 15,1% das vendas das lojas, quase exatamente o que o tamanho sozinho
preveria.

## O que o ranking diz a Helena

Ele não diz que Contagem é uma loja ruim. Diz que **"Contagem é a que mais vende" é, sobretudo, uma
frase sobre o tamanho dela**, e que, se a Varanda quer que cada metro quadrado novo venda o máximo
possível, as lojas que já vendem mais por metro são candidatas mais fortes. Foi isso que Lívia
mandou: a tabela, as duas ordens e três frases, com a ressalva que a próxima seção explica — vendas
por metro quadrado é uma média, e o próximo metro construído não é um metro médio.

Helena pediu que Savassi e Nova Lima fossem orçadas ao lado de Contagem. É o ciclo da aula 1
funcionando: a resposta não tomou a decisão, ela mudou as opções que estavam na mesa.
