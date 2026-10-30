---
title: Lakes, zonas e assets, e um produto que mudou de nome
version: 1
---

**O Dataplex não guarda dado, e não move nenhum.** Os pedidos continuam no Cloud Storage e as
tabelas continuam no BigQuery, onde as aulas 1 a 18 os puseram. O que o Dataplex acrescenta é uma
camada de descrição sobre tudo isso: o que existe, o que cada coisa significa, quem pode ver que
parte, se os números ali fazem sentido, e que job fez aquilo a partir de quê. A imagem errada é a de
um banco novo, ou de uma cópia do acervo. Nada nesta aula muda um byte dos dados da Quitanda.

**E nada disso roda aqui.** Não existe emulador para o Dataplex, para o catálogo dele, para a
linhagem de dados nem para as policy tags do BigQuery, e a linha de comando da aula 1 não tem para
onde mandá-los. Esta aula ensina os quatro a partir da documentação do Google e marca cada comando que
mostra como não executado. Duas seções praticam algo real no seu laptop: a aritmética que uma regra
de qualidade de dados faz, e o grafo que um serviço de linhagem monta a partir de eventos. As duas
dizem com todas as letras que são modelos da ideia, não o serviço.

## Três nomes em três anos

**Antes de tudo, os nomes, porque a documentação que você vai ler usa todos eles.** Até onde esta
aula sabe, a história é esta:

| | como se chamava | o que fazia |
|---|---|---|
| até mais ou menos 2024 | **Data Catalog** | um serviço à parte: busca sobre os metadados do BigQuery e do Pub/Sub, tags com modelos, e as policy tags da última seção |
| 2024 | **Dataplex Catalog** | o catálogo passou para dentro do Dataplex, com um modelo novo de entradas e aspectos, e o Data Catalog foi descontinuado em favor dele |
| 2025 | **Dataplex Universal Catalog** | o nome do Dataplex como um todo, com o catálogo à frente |
| lido em 2026-10-30 | **Knowledge Catalog** | o título da página de preços diz "Knowledge Catalog (formerly Dataplex)", e que o Dataplex Universal Catalog "has evolved into the Knowledge Catalog" |

A última linha é a única que esta aula leu com os próprios olhos, em cloud.google.com/dataplex/pricing,
e essa página também diz que os SKUs de cobrança mantêm o nome Dataplex. As linhas de cima são o que
o autor sabia antes de escrever esta aula, e as datas são aproximadas. **O curso o chama de
Dataplex**, que é o nome na fatura e na linha de comando, `gcloud dataplex`. O Google anunciou uma
data a partir da qual a própria API do Data Catalog para de responder; o aviso de descontinuação na
documentação do Data Catalog a traz, e esta aula não a cita. Produtos são renomeados no calendário
do dono, e os conceitos abaixo duram mais que os nomes.

## Lakes, zonas e assets

**Um lake é um jeito de desenhar caixas em volta de buckets e datasets para governá-los em grupo.**
É a parte mais antiga do Dataplex, e aquela em que os recursos mais novos do catálogo menos se
apoiam, então esta seção é curta nela.

- **Um lake** é a caixa de cima, em geral uma por domínio: a Quitanda teria `sales`, com os pedidos.
- **Uma zona** é uma caixa dentro dele com um tipo: uma zona **raw** para dados como chegaram, em
  qualquer formato, e uma zona **curated** para dados que foram limpos e seguem um esquema, Parquet
  ou Avro ou uma tabela do BigQuery.
- **Um asset** é uma coisa real ligada a uma zona: um bucket do Cloud Storage ou um dataset do
  BigQuery.

O acervo da Quitanda cabe nisso sem esforço. `quitanda-raw-prod` é asset da zona raw,
`quitanda-curated-prod` e o dataset `curated` do BigQuery são assets da zona curated, e o lake é
`sales`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 284\" role=\"img\" aria-label=\"O lake sales tem duas zonas. A zona raw tem um asset, o bucket do Cloud Storage quitanda-raw-prod, para dados como chegaram, em qualquer formato. A zona curated tem dois assets, o bucket quitanda-curated-prod e o dataset do BigQuery planner-dev.curated.\" data-fig=\"g26-estate\"><rect x=\"16\" y=\"16\" width=\"688\" height=\"236\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"32\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lake</text><text x=\"62\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sales</text><rect x=\"32\" y=\"50\" width=\"300\" height=\"186\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"46\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">zona raw</text><rect x=\"48\" y=\"86\" width=\"268\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"60\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bucket do Cloud Storage</text><text x=\"60\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">quitanda-raw-prod</text><text x=\"48\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dados como chegaram,</text><text x=\"48\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">em qualquer formato</text><rect x=\"352\" y=\"50\" width=\"336\" height=\"186\" rx=\"5\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"366\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">zona curated</text><rect x=\"368\" y=\"86\" width=\"304\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"380\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bucket do Cloud Storage</text><text x=\"380\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">quitanda-curated-prod</text><rect x=\"368\" y=\"154\" width=\"304\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"380\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dataset do BigQuery</text><text x=\"380\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">planner-dev.curated</text><text x=\"32\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Lakes e zonas são caixas para governar; os assets são os buckets e datasets de verdade, sem mudança.</text></svg>", "caption": "O acervo da Quitanda como um lake com duas zonas, do jeito que esta seção o montaria. Desenhado a partir da documentação; nada aqui criou um.", "same": ["lake"]}
```

Criá-los são três comandos, não executados, já que nada aqui chega ao Google:

```sh
gcloud dataplex lakes create sales --location=southamerica-east1
gcloud dataplex zones create raw --lake=sales --location=southamerica-east1 \
  --type=RAW --resource-location-type=SINGLE_REGION
gcloud dataplex assets create orders-raw --lake=sales --zone=raw --location=southamerica-east1 \
  --resource-type=STORAGE_BUCKET --resource-name=projects/planner-dev/buckets/quitanda-raw-prod
```

**O que um lake compra são duas coisas.** Permissões dadas no lake ou na zona alcançam todo asset
dentro dela, então o grupo de analistas recebe a zona curated uma vez em vez de cada bucket e
dataset à mão. E a **descoberta** roda sobre os assets: o Dataplex lê os arquivos de um bucket,
deduz o esquema e as partições, e publica o que achou como tabelas que o BigQuery consegue consultar
onde estão, as tabelas externas da aula 17. A página de preços diz que organizar dados em lakes,
zonas e assets é grátis, e que a descoberta roda como jobs cobrados pelos serviços que os executam,
não pelo Dataplex.

**O que um lake não compra é uma fronteira.** Um bucket numa zona é o mesmo bucket, e quem tem
`storage.objects.get` nele pelo IAM o lê, diga a zona o que disser. O Dataplex administra vínculos
do IAM nos assets por você; ele não troca o IAM por um sistema de permissão próprio. Essa é a maior
diferença para o Lake Formation da AWS, que se põe entre os motores e os arquivos, e é por isso que a
regra por coluna do fim desta aula é do BigQuery e não do Dataplex.
