---
title: O que um formato de tabela acrescenta
version: 1
---

Um **formato de tabela aberto** mantém os dados como arquivos Parquet comuns e acrescenta uma coisa ao lado
deles: um **log de transações**, uma lista de commits em ordem, cada um dizendo quais arquivos acrescentou à
tabela e quais removeu. Um leitor não lista a pasta. Ele lê o log, descobre quais arquivos formam a versão mais
recente, e lê esses.

Esse acréscimo único responde a quase tudo da seção anterior:

- **Commits atômicos.** Quem escreve grava primeiro os arquivos de dados, onde nenhum leitor os procura, e depois
  acrescenta uma entrada ao log. Enquanto a entrada não existe, os arquivos novos não fazem parte da tabela;
  depois que existe, todos fazem. Um job que morre no meio deixa arquivos que ninguém lê, não uma tabela
  parcial.
- **Updates e deletes.** Uma mudança regrava os arquivos afetados e faz commit de "remova estes, acrescente
  aqueles". Os leitores veem a tabela velha ou a nova, nunca uma mistura.
- **Imposição de esquema.** O log registra o esquema da tabela, e quem escreve dados que não batem é recusado
  antes do commit.
- **Histórico.** Commits antigos ficam no log e arquivos antigos ficam no disco até alguém limpá-los, então
  qualquer versão anterior pode ser lida de novo. Isso se chama **time travel**, viagem no tempo.
- **Estatísticas.** Cada entrada de arquivo acrescentado traz a contagem de linhas e o mínimo e o máximo de cada
  coluna, então um leitor pode pular arquivos sem abri-los: os zone maps da lição 8, um nível acima.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"À direita, uma pasta de arquivos de dados Parquet: três deles, um riscado porque um commit posterior o removeu. À esquerda, o log de transações: o commit 0 acrescenta o arquivo de 2024, o commit 1 acrescenta o de 2025, o commit 2 remove o arquivo antigo de 2024 e acrescenta um corrigido. Um leitor lê o log, não a pasta, e a tabela atual são os dois arquivos que o log ainda lista.\"><defs><marker id=\"ah-table-format\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">_delta_log: a tabela</text><text x=\"540\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">arquivos de dados: Parquet comum</text><rect x=\"30\" y=\"45\" width=\"240\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">00000.json</text><text x=\"45\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">add 2024 (a)</text><rect x=\"30\" y=\"107\" width=\"240\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">00001.json</text><text x=\"45\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">add 2025 (b)</text><rect x=\"30\" y=\"169\" width=\"240\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">00002.json</text><text x=\"45\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">remove a, add c</text><rect x=\"430\" y=\"45\" width=\"220\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">a: 2024.parquet</text><line x1=\"445\" y1=\"69\" x2=\"635\" y2=\"69\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"430\" y=\"107\" width=\"220\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">b: 2025.parquet</text><rect x=\"430\" y=\"169\" width=\"220\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c: 2024.parquet</text><line x1=\"270\" y1=\"69\" x2=\"430\" y2=\"69\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-table-format)\"></line><line x1=\"270\" y1=\"131\" x2=\"430\" y2=\"131\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-table-format)\"></line><line x1=\"270\" y1=\"193\" x2=\"430\" y2=\"193\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-table-format)\"></line><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o leitor reproduz o log: a tabela atual é b e c</text><text x=\"360\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a fica no disco até um vacuum, então a versão 1 ainda pode ser lida</text></svg>", "caption": "Um formato de tabela: o log diz quais arquivos formam cada versão."}
```

Três formatos implementam a ideia, e são mais parecidos do que diferentes: **Delta Lake**, da Databricks;
**Apache Iceberg**, da Netflix; e **Apache Hudi**, da Uber. O laboratório de Ana tem a biblioteca Python
`deltalake`, o delta-rs, então as quatro próximas seções são Delta; a seção 11 diz onde os outros dois diferem.

Um lake cujas tabelas importantes estão num desses formatos é o que hoje se chama de **lakehouse**: os arquivos
abertos e o armazenamento barato do lake, com as transações, o esquema e o histórico do warehouse.
