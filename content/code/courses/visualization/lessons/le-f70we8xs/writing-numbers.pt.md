---
title: Escrevendo números em gráficos
version: 1
---

Todo número num gráfico é lido, então cada um deve ser escrito para um leitor, e não copiado de uma
célula. Quatro hábitos cobrem a maior parte.

## Arredonde para o que o leitor consegue usar

**20.586 pedidos** é o certo para uma tabela e muitas vezes preciso demais para o rótulo de um gráfico,
onde **20,6 mil** ou **uns 21.000** é o que o leitor vai lembrar. Use a precisão de que a decisão
precisa: uma taxa de crescimento de 60,5% diz mais que 60,4713%, e 61% pode bastar. Mantenha a mesma
precisão no gráfico inteiro, para 60,5% não ficar ao lado de 14%.

## Use as convenções do leitor

O mesmo número se escreve de jeitos diferentes em lugares diferentes:

| | inglês | português (Brasil) |
|---|---|---|
| separador de milhar | 20,586 | 20.586 |
| separador decimal | 60.5% | 60,5% |
| moeda | R$ 1,960 thousand | R$ 1.960 mil |
| datas | Oct 2024 | out. 2024 |

Um gráfico para um público brasileiro escrito com separadores do inglês faz todo leitor parar e
converter. **Configure a localidade na sua ferramenta** em vez de digitar os separadores à mão; o
matplotlib, as planilhas e as ferramentas de BI formatam pela localidade. As figuras deste curso trocam
os separadores entre as páginas em inglês e em português, e as saídas dos programas, que são capturas,
mantêm o que o programa imprimiu.

## Dê o nome da unidade uma vez, com clareza

"R$ mil" no título do eixo, e depois 412 na barra, é mais claro que "R$ 412.000" em cada barra. **Por
cento e ponto percentual são coisas diferentes**: o crescimento do Sudeste ficou 11,3 **pontos
percentuais** abaixo dos 25,9% da empresa, e não 11,3% abaixo. O mapa da aula 12 dizia "p.p."
exatamente por isso.

## Alinhe e ordene

Numa tabela ao lado de um gráfico, **alinhe os números à direita**, para os algarismos se alinharem e o
tamanho deles aparecer num relance, e ordene as linhas do mesmo jeito que o gráfico. Um leitor indo de
um para o outro deve achar cada linha no mesmo lugar.
