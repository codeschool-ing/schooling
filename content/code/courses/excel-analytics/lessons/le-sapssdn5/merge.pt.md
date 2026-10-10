---
title: Mesclar, a busca entre duas consultas
version: 1
---

**Uma mesclagem junta duas consultas por uma chave: para cada linha da primeira, encontra as linhas
da segunda cuja chave casa e traz as colunas que você pedir.** Com o tipo de junção certo, é a busca
da aula 4 feita de uma vez para a tabela inteira. Com o tipo errado, ou com uma chave que não é
única, ela perde linhas ou as duplica, e nenhum erro avisa.

## Uma mesclagem como busca

`WebOrders` sabe quanto cada pedido rendeu e não quanto custou. O custo está em `Products`, a consulta
só de conexão que a seção 05 da aula 13 fez, na coluna `Unit cost`, com a chave `Code`.

1. Selecione `WebOrders` no editor e escolha **Página Inicial › Mesclar Consultas › Mesclar Consultas
   como Novas**. Uma caixa mostra duas tabelas, uma acima da outra.
2. Na de cima, `WebOrders`, clique no cabeçalho `Product`. Na de baixo, escolha `Products` e clique no
   cabeçalho `Code`. As duas colunas clicadas são a chave.
3. Deixe **Tipo de Junção** em **Externa esquerda (todas da primeira, correspondentes da segunda)** e
   clique em **OK**.

Abaixo das tabelas a caixa conta as correspondências antes do clique: **22 de 22 linhas** da primeira
tabela encontraram par. Vale ler essa linha toda vez, porque é o único lugar em que uma chave ruim
aparece antes de os dados servirem de base para outra coisa.

A consulta nova tem todas as colunas de `WebOrders` e mais uma, chamada `Products`, com a palavra
`Table` em toda linha: as linhas de `Products` que casaram, dobradas. Clique no ícone de duas setas
nesse cabeçalho, desmarque tudo menos `Unit cost`, desmarque **Usar o nome da coluna original como
prefixo** e clique em **OK**. Cada pedido agora traz o seu custo unitário. Uma coluna personalizada,
`Margin`, com a fórmula `[Revenue] - [Bags] * [Unit cost]`, dá quanto cada pedido rendeu depois de
pago o café.

Renomeie a consulta para `WebMargin`. Nos três meses, os pedidos pagos trouxeram **R$ 3.125,50**, o
café neles custou **R$ 1.698**, e a margem é de **R$ 1.427,50**.

## A comparação é exata

Se você tivesse mesclado antes de a seção 02 pôr os códigos em maiúsculas, a caixa diria **20 de 22
linhas**, e os pedidos `W2010` e `W2019` chegariam com `Unit cost` vazio. **Uma mesclagem compara
texto exatamente, maiúsculas incluídas**: `dec250` não é `DEC250`. É diferente das buscas da aula 4,
em que o `PROCX` (`XLOOKUP` no Excel em inglês) e o `PROCV` ignoram maiúsculas. Uma consulta que limpa
as chaves antes de mesclá-las não está sendo exigente; está fazendo o que a mesclagem não faz.

## Os seis tipos de junção

A lista **Tipo de Junção** decide o que acontece com as linhas que não casam. Para ver os seis,
mescle `WebOrders` com `Freight`, a fatura da transportadora, por `Order` nas duas. Dos 22 pedidos
pagos, 19 foram enviados; três foram retirados na torrefação e não têm linha de frete. A fatura tem
20 linhas, porque um pedido aparece duas vezes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" data-fig=\"l14-joins\" aria-label=\"Quatro pedidos de WebOrders à esquerda, de W2012 a W2015, e as linhas deles em Freight à direita. W2012 e W2015 casam com uma linha cada. W2013 não casa com nada. W2014 casa com duas linhas, porque foi enviado duas vezes. Uma mesclagem Externa Esquerda desses quatro pedidos devolve cinco linhas: W2013 uma vez com frete vazio, e W2014 duas vezes.\"><text x=\"40.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">WebOrders (primeira)</text><text x=\"250.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Freight (segunda)</text><text x=\"500.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">resultado Externa Esquerda</text><rect x=\"40.0\" y=\"46.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"60.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2012</text><rect x=\"40.0\" y=\"108.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"122.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2013</text><rect x=\"40.0\" y=\"170.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2014</text><rect x=\"40.0\" y=\"232.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"90.0\" y=\"246.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2015</text><rect x=\"250.0\" y=\"46.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"60.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2012</text><rect x=\"250.0\" y=\"108.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"122.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2014</text><rect x=\"250.0\" y=\"170.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2014</text><rect x=\"250.0\" y=\"232.0\" width=\"100.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"246.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">W2015</text><path d=\"M140.0 60.0 L250.0 60.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M140.0 184.0 L250.0 122.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M140.0 184.0 L250.0 184.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M140.0 246.0 L250.0 246.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"40.0\" y=\"298.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">W2013: sem linha de frete</text><text x=\"40.0\" y=\"316.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">W2014: duas linhas de frete, então duas linhas no resultado</text><rect x=\"500.0\" y=\"40.0\" width=\"100.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"506.0\" y=\"53.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Order</text><rect x=\"600.0\" y=\"40.0\" width=\"90.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"684.0\" y=\"53.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Freight</text><rect x=\"500.0\" y=\"66.0\" width=\"100.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"506.0\" y=\"79.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">W2012</text><rect x=\"600.0\" y=\"66.0\" width=\"90.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"684.0\" y=\"79.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">16.70</text><rect x=\"500.0\" y=\"92.0\" width=\"100.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"506.0\" y=\"105.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">W2013</text><rect x=\"600.0\" y=\"92.0\" width=\"90.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"500.0\" y=\"118.0\" width=\"100.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"506.0\" y=\"131.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">W2014</text><rect x=\"600.0\" y=\"118.0\" width=\"90.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"684.0\" y=\"131.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">31.20</text><rect x=\"500.0\" y=\"144.0\" width=\"100.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"506.0\" y=\"157.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">W2014</text><rect x=\"600.0\" y=\"144.0\" width=\"90.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"684.0\" y=\"157.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">31.20</text><rect x=\"500.0\" y=\"170.0\" width=\"100.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"506.0\" y=\"183.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">W2015</text><rect x=\"600.0\" y=\"170.0\" width=\"90.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"684.0\" y=\"183.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">14.60</text><text x=\"684.0\" y=\"105.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">null</text><text x=\"500.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">4 pedidos entram, 5 linhas saem</text></svg>", "caption": "Uma mesclagem traz toda linha que casa. Um pedido sem par mantém a linha com valor vazio na Externa Esquerda, e um pedido cuja chave se repete do outro lado se repete junto."}
```

| tipo de junção | mantém | linhas aqui |
|---|---|---|
| **Externa esquerda** (Left Outer) | toda linha da primeira, com as correspondências onde houver | **23** |
| **Externa direita** (Right Outer) | toda linha da segunda, com as correspondências onde houver | 20 |
| **Externa completa** (Full Outer) | toda linha das duas | 23 |
| **Interna** (Inner) | só as linhas que casam dos dois lados | 20 |
| **Anti esquerda** (Left Anti) | linhas da primeira **sem** par | **3**: `W2003`, `W2013`, `W2021` |
| **Anti direita** (Right Anti) | linhas da segunda sem par | 0 |

As duas anti são as que as pessoas esquecem, e respondem a uma pergunta que nenhuma fórmula de busca
responde num passo: *quais pedidos não têm frete?* Aqui, as três retiradas. Virada ao contrário,
*quais linhas da fatura são de pedidos de que não temos registro?* Nenhuma neste trimestre, e uma
junção anti direita é como você descobriria no próximo.

## A chave que não é única

Olhe de novo a linha da Externa esquerda: **23** linhas a partir de 22 pedidos. O pedido `W2014` foi
enviado duas vezes, porque o primeiro pacote se perdeu, então a fatura tem duas linhas para ele, e
uma mesclagem traz **toda** linha que casa. `W2014` agora aparece duas vezes, e a receita dele junto.
Some `Revenue` nessa consulta mesclada e você obtém **R$ 3.389,50** em vez de R$ 3.125,50: os R$ 264
desse pedido contados duas vezes.

Nada avisa. **Uma mesclagem funciona como busca só quando a chave é única do lado que você está
trazendo**, e quando não é, a primeira tabela cresce. Confira a contagem de linhas depois de toda
mesclagem: se subiu, uma chave do lado direito se repete. O conserto é torná-la única antes, somando
as duas linhas de frete de `W2014` numa só, que é o que a seção 06 faz com **Agrupar Por**.

Esta mesclagem serviu para ver os tipos de junção; apague-a. Fique com `WebMargin` e carregue-a com
**Fechar e Carregar** como tabela numa planilha própria.
