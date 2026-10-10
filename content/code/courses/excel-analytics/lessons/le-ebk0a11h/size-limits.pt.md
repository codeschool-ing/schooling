---
title: O tamanho de uma planilha, e o que acontece depois da borda
version: 1
---

**Uma planilha tem tamanho fixo, e os dados depois da última linha não esperam por você: ficam para
trás.** Toda planilha de uma pasta de trabalho atual do Excel tem 1.048.576 linhas e 16.384
colunas, seja lá o que guarde. A última célula é **XFD1048576**. O Excel não aumenta a planilha
para caber os dados, nem passa o resto para uma segunda planilha.

Dá para perguntar à própria planilha. Em qualquer célula vazia:

```localised
=LINS(A:A)
=COLS(1:1)
```

Elas respondem **1.048.576** e **16.384** (`LINS` e `COLS` são `ROWS` e `COLUMNS` no Excel em
inglês). A planilha `Sales` da Café Serra usa 109 dessas linhas, cerca de 0,01% delas, e nada neste
curso chega perto da borda. Uma empresa que registra mil linhas de pedido por dia é outra história:
nesse ritmo, as linhas abaixo de um cabeçalho se enchem em cerca de 1.049 dias, um pouco menos de
três anos.

## O que acontece na borda

A borda aparece quando um arquivo é aberto, não quando se digita. Alguém recebe um CSV exportado de
outro sistema e dá dois cliques nele. Se o arquivo tem mais linhas do que a planilha, o Excel
carrega as que cabem, mostra um aviso de que o arquivo não foi carregado por completo e abre o que
coube como uma planilha comum. Um CSV de 1.200.000 linhas perde 151.424 delas, e a planilha que
sobra parece completa: nenhum buraco, nenhum erro em célula nenhuma, uma última linha que
simplesmente não é a última linha do arquivo.

**O aviso aparece uma vez, e a planilha nunca o repete.** Quem clica para fechá-lo, ou abre a cópia
que outra pessoa salvou, vê uma planilha cheia. Pior: salvar o CSV pelo Excel grava só as linhas
que chegaram, e o resto some também do arquivo.

A figura desenha esse arquivo chegando.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" data-fig=\"l18-edge\" aria-label=\"Um arquivo CSV de 1.200.000 linhas aberto no Excel. As linhas de 1 a 1.048.576 chegam às linhas de uma planilha, que termina na linha 1.048.576. As 151.424 linhas restantes não têm para onde ir e não são carregadas. A planilha que abre não mostra buraco nem erro.\"><text x=\"40.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o arquivo</text><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">orders.csv</text><text x=\"470.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">a planilha</text><text x=\"470.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">orders</text><rect x=\"40.0\" y=\"56.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"69.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"122.0\" y=\"69.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Order,Date,…</text><rect x=\"40.0\" y=\"82.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"95.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"122.0\" y=\"95.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…</text><rect x=\"40.0\" y=\"108.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"121.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"122.0\" y=\"121.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…</text><rect x=\"40.0\" y=\"134.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"147.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">…</text><text x=\"122.0\" y=\"147.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\"></text><rect x=\"40.0\" y=\"160.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"173.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.048.576</text><text x=\"122.0\" y=\"173.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…</text><rect x=\"40.0\" y=\"186.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"110.0\" y=\"199.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1.048.577</text><text x=\"122.0\" y=\"199.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">…</text><rect x=\"40.0\" y=\"212.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"110.0\" y=\"225.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">…</text><text x=\"122.0\" y=\"225.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\"></text><rect x=\"40.0\" y=\"238.0\" width=\"230.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"110.0\" y=\"251.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1.200.000</text><text x=\"122.0\" y=\"251.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">…</text><rect x=\"470.0\" y=\"56.0\" width=\"250.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"462.0\" y=\"69.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"478.0\" y=\"69.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Order,Date,…</text><path d=\"M272.0 69.0 L400.0 69.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M400.0 69.0 L392.0 65.0 L392.0 73.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><rect x=\"470.0\" y=\"82.0\" width=\"250.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"462.0\" y=\"95.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"478.0\" y=\"95.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…</text><path d=\"M272.0 95.0 L400.0 95.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M400.0 95.0 L392.0 91.0 L392.0 99.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><rect x=\"470.0\" y=\"108.0\" width=\"250.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"462.0\" y=\"121.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"478.0\" y=\"121.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…</text><path d=\"M272.0 121.0 L400.0 121.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M400.0 121.0 L392.0 117.0 L392.0 125.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><rect x=\"470.0\" y=\"134.0\" width=\"250.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"462.0\" y=\"147.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">…</text><rect x=\"470.0\" y=\"160.0\" width=\"250.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"462.0\" y=\"173.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.048.576</text><text x=\"478.0\" y=\"173.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">…</text><path d=\"M272.0 173.0 L400.0 173.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M400.0 173.0 L392.0 169.0 L392.0 177.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><path d=\"M470.0 186.0 L720.0 186.0\" stroke=\"var(--paper)\" stroke-width=\"2.5\" fill=\"none\"></path><text x=\"470.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a última linha que uma planilha tem</text><path d=\"M280 188 L292 188 L292 262 L280 262\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"302.0\" y=\"212.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">151.424 linhas</text><text x=\"302.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">não carregadas</text><text x=\"470.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que abre: sem buraco, sem erro,</text><text x=\"470.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma última linha que não é a do arquivo</text><text x=\"40.0\" y=\"296.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um aviso aparece uma vez, quando o arquivo é aberto</text></svg>", "caption": "Abrindo um arquivo mais longo que uma planilha. As linhas que cabem chegam; o resto fica para trás, e depois do único aviso a planilha parece exatamente uma planilha completa."}
```

**O formato antigo tinha uma borda bem mais perto.** Uma pasta salva no formato `.xls` do Excel 97
a 2003 guarda 65.536 linhas e 256 colunas por planilha: um dezesseis avos das linhas e um sessenta
e quatro avos das colunas. O Excel ainda abre e grava esse formato, e um modelo criado há muito
tempo nele mantém o limite antigo, qualquer que seja a versão que o abra. A seção 04 desta aula
mostra o que isso custou a um órgão público em 2020.

## O modelo de dados não é uma planilha

O Power Query, da aula 13, pode carregar linhas no modelo de dados em vez de numa planilha, e o
modelo da aula 15 não tem grade de linhas. Ele guarda cada coluna comprimida, e quanto aguenta
depende da memória do computador, não de uma contagem de linhas. Um Excel de 32 bits fica sem
memória muito antes de um de 64 bits, e esse é um dos motivos pelos quais a Microsoft recomenda o
Excel de 64 bits para modelos grandes. Os limites atuais da sua versão estão na página da Microsoft
sobre especificações e limites do modelo de dados (*Data Model specification and limits*).

Então o modelo afasta muito a borda, e é assim que milhões de linhas cabem resumidas numa tabela
dinâmica que nenhuma planilha comportaria. Ele não elimina os outros custos do tamanho.

## Lenta muito antes de cheia

**Uma pasta de trabalho costuma ficar penosa bem antes de ficar cheia.** Cada fórmula que lê uma
coluna inteira, cada busca e cada formatação condicional são recalculadas em todas as linhas que
cobrem. Uma planilha de algumas centenas de milhares de linhas com uma dúzia de colunas assim faz
toda edição esperar. O arquivo também cresce, e uma pasta que leva um minuto para abrir e é grande
demais para ir anexada num e-mail é uma pasta que as pessoas param de abrir e começam a copiar aos
pedaços.

Nada disso é motivo para temer o Excel no tamanho da Café Serra. É motivo para saber onde ficam as
bordas antes que cheguem dados que as atravessem.
