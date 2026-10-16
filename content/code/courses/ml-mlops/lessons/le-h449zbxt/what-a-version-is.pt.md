---
title: O que a versão de um modelo precisa nomear
version: 1
---

O `train.py` da lição 5 gravava um registro ao lado do modelo: a impressão digital do arquivo de
treino, o corte, o número de linhas, a versão da biblioteca. **Ele nomeia os dados e não o código**,
e é um arquivo num disco, sobrescrito pela próxima execução. Pergunte a ele qual modelo mandou os
vouchers do mês passado e se esse modelo pode ser refeito, e ele não tem resposta.

**Um modelo é produto de quatro coisas**, e uma versão que deixa uma de fora não pode ser refeita:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l07-four-inputs\" aria-label=\"Quatro entradas alimentam uma versão de modelo: código, guardado pelo Git; dados, guardados pelo DVC; ajustes, escritos em arquivos guardados pelo Git; e o ambiente, fixado pelas linhas do pip. A versão produz o arquivo do modelo, guardado pelo DVC, e as suas notas, guardadas no Git e no MLflow.\"><defs><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">código</text><text x=\"105.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Git</text><path d=\"M190.0 44.0 L288.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"20.0\" y=\"82.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">dados</text><text x=\"105.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">DVC</text><path d=\"M190.0 106.0 L288.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"20.0\" y=\"144.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">ajustes</text><text x=\"105.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Git</text><path d=\"M190.0 168.0 L288.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"20.0\" y=\"206.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">ambiente</text><text x=\"105.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">versões fixadas</text><path d=\"M190.0 230.0 L288.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"290.0\" y=\"110.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">uma versão de modelo</text><rect x=\"530.0\" y=\"70.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o arquivo do modelo</text><text x=\"615.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">DVC, MLflow</text><path d=\"M452.0 140.0 L528.0 96.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"530.0\" y=\"160.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">as notas</text><text x=\"615.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Git, MLflow</text><path d=\"M452.0 140.0 L528.0 186.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path></svg>", "caption": "Deixe de fora qualquer uma das quatro e a versão não pode ser refeita. O arquivo do modelo e as notas são saídas, e também são versionados.", "same": ["DVC", "DVC, MLflow", "Git", "Git, MLflow"]}
```

| entrada | o que a muda | o que guarda as versões dela aqui |
| --- | --- | --- |
| **código** | uma edição no `features.py`, no `model.py` ou em qualquer etapa | **Git**, como commits |
| **dados** | uma noite nova de compras, uma carga corrigida | **DVC**, como hashes do conteúdo, com os arquivos num armazenamento próprio |
| **ajustes** | os cortes, os parâmetros de um modelo | Git, porque estão escritos no `dvc.yaml` e no `model.py` |
| **ambiente** | um scikit-learn novo | as linhas `pip install` fixadas, e a versão que cada execução registra |

E mais duas coisas que não são entradas mas também precisam de versão: **o próprio arquivo do
modelo**, a saída das quatro, e **as suas notas**, para que duas versões possam ser comparadas sem
treinar nenhuma de novo.

Três ferramentas, cada uma com um trabalho:

- **Git** você conhece. Ele é bom com texto e ruim com arquivos binários grandes, que é a lacuna que
  as outras duas preenchem;
- **DVC**, Data Version Control, mantém arquivos grandes fora do Git: ele os guarda num cache e num
  remoto próprios, e põe no Git um pequeno arquivo de texto que nomeia cada um pelo hash. Ele também
  roda o pipeline, e roda de novo só as etapas cujas entradas mudaram;
- **MLflow** registra cada treino (os seus parâmetros, notas e arquivos) num banco que você consegue
  consultar, e mantém um **registro de modelos**: modelos com nome e versões numeradas, e apelidos
  (*aliases*) como `champion` que um serviço consegue carregar pelo nome.

**As três se sobrepõem, e isso é normal.** O DVC consegue acompanhar métricas e o MLflow consegue
guardar dados. Esta lição dá a cada uma o trabalho em que ela é melhor, que é também a divisão em que
a maioria dos times acaba chegando.
