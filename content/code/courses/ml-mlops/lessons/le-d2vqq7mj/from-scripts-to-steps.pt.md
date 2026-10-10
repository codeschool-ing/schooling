---
title: De scripts a etapas
version: 1
---

Todo programa até aqui fez o trabalho inteiro de uma vez: montar os exemplos, ajustar, imprimir.
**Essa é a forma certa para descobrir, e a errada para rodar todo mês**, por quatro motivos que as
lições anteriores encontraram:

- **os arquivos são achados por acaso.** O `features.py` abre o `shop.db` relativo a onde quer que o
  programa tenha sido iniciado, e a última falha de instalação da lição 1 mostrou o que isso faz a
  partir do diretório errado: um banco vazio, criado em silêncio;
- **as datas estão dentro do código**, então o corte com que um modelo foi treinado é uma linha que
  alguém precisa lembrar de mudar, e nada impede que escolha uma com rótulos inacabados;
- **nada é verificado.** Um conjunto de dados com uma recência negativa treina um modelo com o mesmo
  gosto que um correto;
- **nada é guardado.** O modelo existe enquanto o programa roda e some quando ele acaba, e o mesmo
  vale para qualquer registro de quais linhas o fizeram.

Um pipeline corrige os quatro dividindo o trabalho em **etapas que passam arquivos umas às outras**,
cada uma podendo ser rodada, verificada e rodada de novo sozinha:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l05-steps\" aria-label=\"O pipeline como quatro etapas passando arquivos. O shop.db entra no build_dataset.py, que grava train.csv e test.csv. O validate.py os lê e aprova ou recusa. O train.py lê train.csv e grava lapse.joblib com o seu registro, lapse.json. O evaluate.py lê o modelo e test.csv e grava lapse.scores.json.\"><defs><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"14.0\" width=\"150.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop.db</text><path d=\"M105.0 42.0 L105.0 82.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"30.0\" y=\"84.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">build_dataset.py</text><text x=\"105.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">recusa rótulos inacabados</text><path d=\"M180.0 107.0 L198.0 107.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"40.0\" y=\"170.0\" width=\"130.0\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">train.csv</text><rect x=\"40.0\" y=\"198.0\" width=\"130.0\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">test.csv</text><rect x=\"200.0\" y=\"84.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">validate.py</text><text x=\"275.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">recusa linhas quebradas</text><path d=\"M350.0 107.0 L368.0 107.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"210.0\" y=\"170.0\" width=\"130.0\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">exit 0 or 1</text><rect x=\"370.0\" y=\"84.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">train.py</text><text x=\"445.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">registra os seus dados</text><path d=\"M520.0 107.0 L538.0 107.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"380.0\" y=\"170.0\" width=\"130.0\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lapse.joblib</text><rect x=\"380.0\" y=\"198.0\" width=\"130.0\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lapse.json</text><rect x=\"540.0\" y=\"84.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">evaluate.py</text><text x=\"615.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pontua o arquivo salvo</text><rect x=\"550.0\" y=\"170.0\" width=\"130.0\" height=\"22.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lapse.scores.json</text></svg>", "caption": "Cada etapa é um programa com um arquivo de entrada e um de saída. Qualquer uma pode ser rodada, verificada e rodada de novo sozinha, e uma falha para as seguintes."}
```

A primeira coisa de que toda etapa precisa é achar os arquivos do projeto do mesmo jeito, de
qualquer diretório em que seja iniciada. Salve isto como `project.py`:

```python
"""project.py: where the project's files are, named in full, whatever directory runs it."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SHOP = ROOT / "shop.db"
DATA = ROOT / "data"
MODELS = ROOT / "models"
LABEL_DAYS = 90
```

`Path(__file__).resolve().parent` é o diretório onde o próprio arquivo mora, então `SHOP` é sempre
`~/ml/shop.db`, com o nome completo. `LABEL_DAYS` é a janela do rótulo, escrita uma vez, porque duas
etapas precisam dela e uma segunda cópia é um segundo valor um dia.
