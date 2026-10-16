---
title: Rodando as quatro etapas como uma
version: 1
---

Quatro etapas digitadas à mão são quatro chances de digitar uma errada. **Um pipeline são as etapas
escritas em ordem, rodadas do mesmo jeito toda vez, parando na primeira falha.** Neste tamanho um
script de shell basta. Salve isto como `pipeline.sh`:

```sh
# pipeline.sh: the lapse model, from the shop to a scored model, stopping at the first failure.
set -e
cd "$(dirname "$0")"
python build_dataset.py 2025-08-31 data/train.csv
python build_dataset.py 2025-11-30 data/test.csv
python validate.py data/train.csv
python validate.py data/test.csv
python train.py data/train.csv models/lapse.joblib
python evaluate.py models/lapse.joblib data/test.csv
```

`set -e` é a linha que o torna um pipeline: **o script para no momento em que qualquer comando sai
com falha**, então um conjunto de dados recusado ou um contrato que falhou nunca chega ao `train.py`.
`cd "$(dirname "$0")"` entra primeiro no diretório do próprio script, então ele roda igual de
qualquer lugar. As datas estão aqui, num lugar só, onde quem revisa as vê.

Rode-o da sua pasta pessoal, para provar que o diretório não importa mais:

```
ana@dev:~$ sh ml/pipeline.sh
data/train.csv: 2863 members as of 2025-08-31, 16.6% lapsed
data/test.csv: 3130 members as of 2025-11-30, 16.9% lapsed
data/train.csv: 2863 rows, every check passed
data/test.csv: 3130 rows, every check passed
{
  "model": "models/lapse.joblib",
  "trained_on": "data/train.csv",
  "data_sha256": "d04183235c0e66c2",
  "cutoff": "2025-08-31",
  "rows": 2863,
  "scikit_learn": "1.9.1"
}
{
  "test": "data/test.csv",
  "cutoff": "2025-11-30",
  "members": 3130,
  "lapsed": 530,
  "roc_auc": 0.793,
  "average_precision": 0.522,
  "baseline_average_precision": 0.169,
  "lapsed_in_top_300": 190,
  "said": 0.177
}
```

**Todo número é o mesmo de quando as etapas rodaram uma de cada vez**, até a impressão digital do
arquivo de treino, `d04183235c0e66c2`. É isso que faz um pipeline valer a pena: rode-o de novo
amanhã com os mesmos dados e ele produz o mesmo modelo; rode-o com dados novos e as únicas diferenças
são as que os dados causaram.

## O que um agendador acrescenta

O `pipeline.sh` roda quando alguém o digita. Em produção ele roda numa agenda, depois da carga da
noite, e as etapas viram tarefas num orquestrador: Airflow, Dagster ou Prefect, que `pipelines-etl`
ensinou. O orquestrador acrescenta o que falta a um script de shell: novas tentativas, um registro de
cada execução, um alerta quando uma falha, e a regra de que o treino espera a carga da loja terminar.
**Nada nas etapas muda**: cada uma continua sendo um programa com um arquivo de entrada e um de
saída, que é exatamente a forma que um orquestrador espera. A lição 7 usa o DVC para rodar as mesmas
etapas e pular as que não tiveram as entradas alteradas.
