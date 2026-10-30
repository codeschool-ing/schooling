---
title: Um produto, um lago, uma conta
version: 1
---

**O Microsoft Fabric não é um serviço que você implanta numa assinatura, como o Synapse.** É um
produto só, operado pela Microsoft como um software em que você entra com seu login, que põe o lago,
o warehouse, o Spark, os pipelines, o streaming e o Power BI atrás de um portal, um armazenamento e
uma conta. O workspace do Synapse da lição 16 era um recurso do Azure, com pools que você
dimensionava e pausava. No Fabric você dimensiona uma coisa só, a capacidade, e todas as cargas de
trabalho tiram dela.

**Esta seção, e quase toda esta lição, é ensinada a partir da documentação da Microsoft e não foi
executada.** Nenhum emulador responde por parte alguma do Fabric, e um tenant exige uma conta
organizacional. Duas coisas rodam, e cada uma avisa onde acontece: o Terraform confere offline a
declaração de uma capacidade na próxima seção, e a sexta seção grava o formato de arquivo aberto que
o Fabric guarda, com uma biblioteca aberta, no Azurite.

## Quatro níveis

Tudo no Fabric fica em quatro níveis, e a maioria das surpresas com ele vem de confundir dois deles:

- **o tenant** é a organização, o mesmo tenant do Entra ID que a lição 2 de `azure-foundations`
  descreve. Há um Fabric por tenant, e um OneLake.
- **uma capacidade** é a computação que se paga. É a única parte do Fabric que é um recurso do
  Azure, criada numa assinatura e numa região, e tem um tamanho, de F2 a F2048. A próxima seção é
  sobre ela.
- **um workspace** é uma pasta de trabalho com seus próprios membros e papéis, atribuída a uma
  capacidade. Mudar um workspace de capacidade muda onde o trabalho dele é cobrado, e nada mais.
- **um item** é o que se constrói: um lakehouse, um warehouse, um notebook, um pipeline, um modelo
  semântico, um relatório. Cada item que guarda dados os guarda no OneLake, numa pasta com o nome do
  item.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"Um tenant do Fabric desenhado como uma borda tracejada. Dentro dele, duas capacidades: F2, com o workspace quitanda-dev e o item sales.Lakehouse, e F64, com o workspace quitanda-analytics e os itens sales.Lakehouse, finance.Warehouse e orders.SemanticModel. Abaixo das duas capacidades, um único OneLake cobre o tenant inteiro, com um contêiner por workspace e uma pasta por item, como quitanda-analytics/sales.Lakehouse/Tables/orders.\" data-fig=\"l17-nesting\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"330\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o tenant do Fabric: um por organização</text><rect x=\"30\" y=\"44\" width=\"240\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"/><text x=\"42\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">capacidade</text><text x=\"258\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">F2</text><rect x=\"46\" y=\"76\" width=\"208\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"56\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">workspace</text><text x=\"244\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">quitanda-dev</text><rect x=\"62\" y=\"110\" width=\"176\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"150\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">sales.Lakehouse</text><rect x=\"290\" y=\"44\" width=\"400\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"/><text x=\"302\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">capacidade</text><text x=\"678\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">F64</text><rect x=\"306\" y=\"76\" width=\"368\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"316\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">workspace</text><text x=\"664\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">quitanda-analytics</text><rect x=\"322\" y=\"110\" width=\"200\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"422\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">sales.Lakehouse</text><rect x=\"322\" y=\"140\" width=\"200\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"422\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">finance.Warehouse</text><rect x=\"322\" y=\"170\" width=\"200\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"422\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">orders.SemanticModel</text><text x=\"598\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">itens: cada um é</text><text x=\"598\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma pasta no OneLake</text><text x=\"598\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">um relatório lê</text><text x=\"598\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">as tabelas ao lado</text><rect x=\"30\" y=\"250\" width=\"660\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"42\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">OneLake: um por tenant, sejam quais forem as capacidades</text><text x=\"42\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">quitanda-dev/sales.Lakehouse/Tables/…</text><text x=\"320\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">quitanda-analytics/sales.Lakehouse/Tables/orders/</text><text x=\"320\" y=\"306\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">quitanda-analytics/finance.Warehouse/Tables/…</text><text x=\"42\" y=\"306\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um contêiner por workspace</text><line x1=\"150\" y1=\"224\" x2=\"150\" y2=\"248\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"/><line x1=\"422\" y1=\"200\" x2=\"422\" y2=\"248\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"/></svg>", "caption": "A capacidade paga pelo trabalho e o workspace agrupa os itens. Os dados de cada item, em cada workspace, em cada capacidade, estão no único OneLake por baixo.", "same": ["workspace"]}
```

**Uma capacidade não é um recipiente de dados.** Duas capacidades, uma pequena para desenvolvimento
e uma grande para produção, continuam gravando no mesmo OneLake, e uma tabela do workspace de
desenvolvimento pode ser lida da produção por um atalho, o assunto da seção depois da próxima. O que
a capacidade separa é a conta e o barulho: um notebook pesado no desenvolvimento não consegue deixar
lentos os relatórios da produção quando os dois estão em capacidades diferentes, e consegue quando
dividem uma.

## O que ele substitui, e o que não substitui

**O Fabric não elimina os serviços de dados do Azure; é outra forma de comprar as mesmas ideias.** Um
warehouse do Fabric faz o papel do pool dedicado da lição 16, sem distribuições para escolher nem
pool para pausar. Um lakehouse faz o papel de uma conta de armazenamento mais um pool de Spark. Os
pipelines do Data Factory, assunto da lição 19, existem dentro do Fabric e também por conta própria.
Uma empresa pode usar os dois, e muitas usam: uma conta ADLS Gen2 em que outros sistemas já gravam,
lida pelo Fabric sem cópia.

**A troca é controle por uma conta só.** Nos serviços próprios do Azure cada peça é um recurso com
tamanho próprio, regras de rede próprias, medidor de preço próprio e Terraform próprio. No Fabric só
a capacidade é alguma dessas coisas, e todo o resto é gerido dentro do produto, no portal em
`app.fabric.microsoft.com`, pelos administradores do Fabric no tenant. Um time que quer toda decisão
no Terraform descobre que quase todo o Fabric fica fora do `azurerm`, que declara a capacidade e
nada dentro dela.
