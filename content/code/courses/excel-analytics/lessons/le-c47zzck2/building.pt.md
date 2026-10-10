---
title: Ligando tabelas dinâmicas, gráficos e segmentações numa tela
version: 1
---

**Nada no painel é novo; o novo é que cada peça obedece aos mesmos dois controles.** As tabelas
dinâmicas são da aula 10, a segmentação e a linha do tempo da aula 11, os gráficos da aula 12 e as
medidas da aula 16. Montadas uma a uma, funcionam. Ligadas sem cuidado, discordam umas das outras
na mesma tela, e o leitor não tem como saber qual está certa.

Nada nesta aula foi executado no Excel. Os números que o painel mostra são as medidas da aula 16,
calculadas aplicando-as às mesmas vendas, e as fórmulas de conferência do fim desta seção foram
calculadas por uma planilha eletrônica com os seus dados, como descreve a seção 02 da aula 1.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 390\" role=\"img\" data-fig=\"l17-wiring\" aria-label=\"Como o painel é ligado. À esquerda, o modelo de dados com as tabelas Sales, Products, Customers e Calendar e as medidas da aula 16. No meio, uma planilha chamada Calc com quatro tabelas dinâmicas montadas a partir do modelo: KPI, Month, Channel e Product. À direita, a planilha Dashboard: células de KPI que leem a tabela KPI com INFODADOSTABELADINÂMICA, e três gráficos dinâmicos desenhados a partir das outras três. Embaixo, uma segmentação Channel e uma linha do tempo Calendar[Date] cujas conexões de relatório vão às quatro tabelas.\"><rect x=\"20.0\" y=\"30.0\" width=\"180.0\" height=\"270.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">modelo de dados</text><rect x=\"30.0\" y=\"58.0\" width=\"160.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"38.0\" y=\"69.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Sales</text><rect x=\"30.0\" y=\"84.0\" width=\"160.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"38.0\" y=\"95.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Products</text><rect x=\"30.0\" y=\"110.0\" width=\"160.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"38.0\" y=\"121.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Customers</text><rect x=\"30.0\" y=\"136.0\" width=\"160.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"38.0\" y=\"147.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Calendar</text><text x=\"30.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">medidas, aula 16</text><text x=\"38.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Total Revenue</text><text x=\"38.0\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Revenue LY</text><text x=\"38.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Revenue YoY %</text><text x=\"38.0\" y=\"245.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Bags Sold</text><text x=\"38.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Sales Count</text><text x=\"38.0\" y=\"279.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Average Sale</text><rect x=\"250.0\" y=\"30.0\" width=\"196.0\" height=\"270.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"260.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Calc</text><text x=\"438.0\" y=\"46.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">planilha oculta</text><path d=\"M200.0 46.0 L248.0 46.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M248.0 46.0 L240.0 42.0 L240.0 50.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"560.0\" y=\"30.0\" width=\"180.0\" height=\"270.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"570.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Dashboard</text><rect x=\"290.0\" y=\"64.0\" width=\"140.0\" height=\"40.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">KPI</text><text x=\"300.0\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tabela dinâmica</text><rect x=\"575.0\" y=\"64.0\" width=\"150.0\" height=\"40.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585.0\" y=\"84.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">células de KPI</text><path d=\"M430.0 84.0 L573.0 84.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M573.0 84.0 L565.0 80.0 L565.0 88.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"502.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">INFODADOSTABELADINÂMICA</text><rect x=\"290.0\" y=\"122.0\" width=\"140.0\" height=\"40.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Month</text><text x=\"300.0\" y=\"151.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tabela dinâmica</text><rect x=\"575.0\" y=\"122.0\" width=\"150.0\" height=\"40.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585.0\" y=\"142.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">gráfico dos meses</text><path d=\"M430.0 142.0 L573.0 142.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M573.0 142.0 L565.0 138.0 L565.0 146.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"502.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Gráfico Dinâmico</text><rect x=\"290.0\" y=\"180.0\" width=\"140.0\" height=\"40.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Channel</text><text x=\"300.0\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tabela dinâmica</text><rect x=\"575.0\" y=\"180.0\" width=\"150.0\" height=\"40.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585.0\" y=\"200.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">gráfico dos canais</text><path d=\"M430.0 200.0 L573.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M573.0 200.0 L565.0 196.0 L565.0 204.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"502.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Gráfico Dinâmico</text><rect x=\"290.0\" y=\"238.0\" width=\"140.0\" height=\"40.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Product</text><text x=\"300.0\" y=\"267.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tabela dinâmica</text><rect x=\"575.0\" y=\"238.0\" width=\"150.0\" height=\"40.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585.0\" y=\"258.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">gráfico dos produtos</text><path d=\"M430.0 258.0 L573.0 258.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M573.0 258.0 L565.0 254.0 L565.0 262.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"502.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Gráfico Dinâmico</text><rect x=\"575.0\" y=\"318.0\" width=\"70.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"610.0\" y=\"333.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Channel</text><rect x=\"652.0\" y=\"318.0\" width=\"88.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"696.0\" y=\"333.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Calendar[Date]</text><path d=\"M575.0 333.0 L270.0 333.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M270.0 333.0 L270.0 84.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M270.0 84.0 L288.0 84.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M288.0 84.0 L280.0 80.0 L280.0 88.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><path d=\"M270.0 142.0 L288.0 142.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M288.0 142.0 L280.0 138.0 L280.0 146.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><path d=\"M270.0 200.0 L288.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M288.0 200.0 L280.0 196.0 L280.0 204.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><path d=\"M270.0 258.0 L288.0 258.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M288.0 258.0 L280.0 254.0 L280.0 262.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"280.0\" y=\"350.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Conexões de Relatório: as quatro tabelas marcadas</text><text x=\"740.0\" y=\"366.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segmentação e linha do tempo, no Dashboard</text></svg>", "caption": "Três camadas: o modelo guarda os dados e as medidas, a planilha oculta Calc guarda as tabelas dinâmicas, e o Dashboard mostra o que elas respondem. A segmentação e a linha do tempo alcançam todas as tabelas pelas conexões de relatório, e a tela inteira se move junto."}
```

## Duas planilhas novas

Acrescente duas planilhas à `cafe-serra.xlsx`: `Dashboard`, que é tudo o que o leitor vê, e
`Calc`, que guarda as tabelas dinâmicas que o painel lê. **Manter as tabelas dinâmicas fora do
painel é o ponto.** Uma tabela dinâmica muda de tamanho quando a segmentação muda: filtrada para um
canal, perde linhas; com mais um ano, ganha uma coluna. Numa planilha só dela, cresce e encolhe à
vontade. No painel, empurraria os gráficos ou invadiria o cartão de baixo.

As planilhas de dados continuam como estão, e o modelo também.

## Quatro tabelas dinâmicas na `Calc`

Na `Calc`, insira quatro tabelas dinâmicas a partir do modelo de dados (**Inserir › Tabela
Dinâmica › Do Modelo de Dados**), com umas dez linhas vazias entre elas. O Excel se recusa a
atualizar uma tabela dinâmica que cresceria por cima de outra, então deixe espaço.

| tabela | linhas | colunas | valores |
|---|---|---|---|
| `KPI` | nenhuma | nenhuma | `Total Revenue`, `Revenue LY`, `Revenue YoY %`, `Bags Sold`, `Sales Count`, `Average Sale` |
| `Month` | o mês do calendário | o ano do calendário | `Total Revenue` |
| `Channel` | `Channel` de `Sales` | nenhuma | `Total Revenue`, `Revenue LY` |
| `Product` | `Product` de `Sales`, ordenado por `Total Revenue`, do maior para o menor | nenhuma | `Total Revenue` |

A tabela `KPI` não tem linha nenhuma, então cada valor tem uma célula só: o total do que a
segmentação e a linha do tempo deixam passar. Ponha-a no canto superior esquerdo da `Calc`, com a
primeira célula em **A3**, porque as fórmulas abaixo apontam para essa célula.

Dê a cada tabela o seu nome na caixa **Nome da Tabela Dinâmica**, à esquerda da guia **Análise de
Tabela Dinâmica**. Senão, `PivotTable1` a `PivotTable4` (ou `Tabela dinâmica1` a `4`) é o que o
próximo passo lista, e escolher entre quatro nomes iguais é como uma tabela fica de fora.

## Três gráficos, levados para o painel

Clique dentro de `Month` e escolha **Análise de Tabela Dinâmica › Gráfico Dinâmico**, e então um
gráfico de colunas agrupadas: uma coluna por mês para cada ano, lado a lado. Clique com o botão
direito no gráfico, escolha **Mover Gráfico** e ponha-o como objeto em `Dashboard`. Um gráfico
dinâmico pode morar numa planilha diferente da sua tabela e continuar a acompanhá-la. Faça o mesmo
com `Channel` e `Product`, como gráficos de barras.

Em cada gráfico, esconda os botões de campo em **Análise de Gráfico Dinâmico › Botões de Campo**.
São controles para quem edita o gráfico, e num painel parecem um segundo conjunto de filtros que
discorda da segmentação.

## Uma segmentação e uma linha do tempo, ligadas a tudo

Clique dentro de qualquer uma das quatro tabelas. Em **Análise de Tabela Dinâmica › Inserir
Segmentação de Dados**, marque `Channel` de `Sales`; em **Análise de Tabela Dinâmica › Inserir
Linha do Tempo**, marque a coluna de data de `Calendar`. Recorte as duas e cole na `Dashboard`, na
faixa acima dos cartões.

Agora o passo que quebra painéis. Uma segmentação nova fica ligada só à tabela em que você clicou.
Clique nela com o botão direito, escolha **Conexões de Relatório** e marque as quatro tabelas.
Depois faça o mesmo na linha do tempo.

**Deixe uma desmarcada e a tela se contradiz.** Escolha `Wholesale` na segmentação com a `KPI` de
fora: o gráfico de canais mostra R$ 11.128 no semestre, e o cartão de receita ao lado continua
mostrando R$ 15.943, o total de todos os canais. Cada número está certo para o que a sua tabela
recebeu. A tela está errada, e nada nela avisa.

## As células de KPI

Na `Dashboard`, clique na célula onde vai o número do cartão de receita, digite `=` e clique no
valor `Total Revenue` da tabela `KPI` na `Calc`. O Excel escreve a fórmula por você:

```localised
=INFODADOSTABELADINÂMICA("[Measures].[Total Revenue]"; Calc!$A$3)
=INFODADOSTABELADINÂMICA("[Measures].[Revenue YoY %]"; Calc!$A$3)
```

O nome entre colchetes é como uma tabela dinâmica feita a partir do modelo de dados chama uma
medida, e a aula 11 apresentou `INFODADOSTABELADINÂMICA` (`GETPIVOTDATA` no Excel em inglês) numa
tabela dinâmica comum. Se o Excel escrever um simples `=Calc!B4`, a opção está desligada: é a
**Gerar InfoDadosTabelaDinâmica** (*Generate GetPivotData*), na lista **Opções** à esquerda de
**Análise de Tabela Dinâmica**.

**Use a forma com `INFODADOSTABELADINÂMICA`, não a referência simples.** `=Calc!B4` aponta para uma
posição. No dia em que alguém acrescenta um campo à tabela, os valores mudam de lugar e o cartão
mostra outro número, sem erro nenhum. `INFODADOSTABELADINÂMICA` pede um valor pelo nome e o encontra
onde ele estiver.

Há um segundo caminho para as mesmas células. **Análise de Tabela Dinâmica › Ferramentas OLAP ›
Converter em Fórmulas** transforma uma tabela dinâmica do modelo de dados numa fórmula `VALORCUBO`
(`CUBEVALUE` no Excel em inglês) por célula, que depois pode ir para qualquer lugar. Uma fórmula de
cubo acompanha uma segmentação quando recebe o nome dela, que aparece nas **Configurações da
Segmentação de Dados** como o nome a usar em fórmulas:

```localised
=VALORCUBO("ThisWorkbookDataModel"; "[Measures].[Total Revenue]"; Slicer_Channel)
```

Esta aula usa `INFODADOSTABELADINÂMICA`, porque uma tabela ligada aos dois controles já carrega os
dois filtros, e há menos coisa para dar errado.

Formate as células de variação com o formato de número `+0,0%;-0,0%;0,0%`, que escreve o sinal na
frente de toda variação, e acrescente a formatação condicional da aula 9 para a cor. O sinal é o
que um leitor daltônico e uma impressão em preto e branco ainda enxergam.

A data do título é mais uma fórmula, sobre a tabela `Sales`, formatada como data:

```localised
=MÁXIMO(Sales[Date])
```

Ela responde 23 de junho de 2026, a última venda dos dados, e anda sozinha quando chegam vendas
novas.

## Conferindo os cartões

Com a linha do tempo em janeiro a junho de 2026 e a segmentação em todos os canais, os cartões
mostram R$ 15.943 e 168 sacos em 36 vendas, contra R$ 17.789, 218 e 36 um ano antes. A receita caiu
10,4% e os sacos, 22,9%. As medidas já bateram com estas fórmulas na aula 16, mas o painel
acrescenta uma segmentação, uma linha do tempo e uma tabela dinâmica no meio, e cada um é um lugar
onde a concordância pode quebrar. Digite em qualquer planilha vazia:

```localised
=SOMASES(Sales[Revenue]; Sales[Date]; ">="&DATA(2026;1;1); Sales[Date]; "<"&DATA(2026;7;1))
=SOMASES(Sales[Revenue]; Sales[Date]; ">="&DATA(2025;1;1); Sales[Date]; "<"&DATA(2025;7;1))
=CONT.SES(Sales[Date]; ">="&DATA(2026;1;1); Sales[Date]; "<"&DATA(2026;7;1))
```

Elas respondem **15.943**, **17.789** e **36**. Agora escolha `Wholesale` na segmentação. Todas as
partes da tela devem se mover juntas: o cartão de receita para R$ 11.128 contra R$ 13.392, 16,9%
abaixo, com 9 vendas contra 15. A mesma conferência com o canal:

```localised
=SOMASES(Sales[Revenue]; Sales[Channel]; "Wholesale"; Sales[Date]; ">="&DATA(2026;1;1); Sales[Date]; "<"&DATA(2026;7;1))
```

responde **11.128**. Escolha `Online`, e a receita mostra R$ 4.295 contra R$ 3.853, 11,5% acima, o
único canal que cresceu.

Por fim, limpe a segmentação e arraste a linha do tempo para abril a junho de 2026. A receita cai
para R$ 3.804 contra R$ 8.486 um ano antes; janeiro a março mostra R$ 12.139 contra R$ 9.303. Se
algum cartão não se mexeu junto com o gráfico dos meses, a tabela dele está faltando nas conexões
de relatório da linha do tempo.
