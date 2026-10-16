---
title: O pipeline, como estágios que o DVC sabe rodar
version: 1
---

O `pipeline.sh` da lição 5 rodava todas as etapas, toda vez. **O DVC roda as mesmas etapas, mas sabe
o que cada uma lê e grava**, então consegue pular uma etapa cujas entradas não mudaram e registrar o
hash de tudo o que ela produziu. As etapas são declaradas no `dvc.yaml`. Salve-o em `~/ml`:

```yaml
# dvc.yaml: the pipeline of lesson 5, as stages DVC can run, skip and compare.
stages:
  dataset:
    cmd: >-
      python build_dataset.py 2025-08-31 data/train.csv &&
      python build_dataset.py 2025-11-30 data/test.csv &&
      python validate.py data/train.csv &&
      python validate.py data/test.csv
    deps: [build_dataset.py, validate.py, features.py, project.py, shop.db]
    outs: [data/train.csv, data/test.csv]
  train:
    cmd: python train.py data/train.csv models/lapse.joblib
    deps: [train.py, model.py, data/train.csv]
    outs: [models/lapse.joblib, models/lapse.json]
  evaluate:
    cmd: python evaluate.py models/lapse.joblib data/test.csv
    deps: [evaluate.py, models/lapse.joblib, data/test.csv]
    metrics:
      - models/lapse.scores.json:
          cache: false
```

Cada estágio tem um comando, os arquivos de que depende (`deps`) e os que produz (`outs`). O
estágio do conjunto de dados depende do `shop.db` e do código que o lê, então uma noite nova de
compras ou uma edição no `features.py` chegam a ele. As notas são uma **métrica** e não uma saída: o
DVC as deixa no Git, onde são pequenas o bastante para um diff, e `cache: false` diz isso.

```
ana@dev:~/ml$ dvc repro
'shop.db.dvc' didn't change, skipping
Running stage 'dataset':
> python build_dataset.py 2025-08-31 data/train.csv && python build_dataset.py 2025-11-30 data/test.csv && python validate.py data/train.csv && python validate.py data/test.csv
data/train.csv: 2863 members as of 2025-08-31, 16.6% lapsed
data/test.csv: 3130 members as of 2025-11-30, 16.9% lapsed
data/train.csv: 2863 rows, every check passed
data/test.csv: 3130 rows, every check passed
Generating lock file 'dvc.lock'
Updating lock file 'dvc.lock'

Running stage 'train':
> python train.py data/train.csv models/lapse.joblib
{
  "model": "models/lapse.joblib",
  "trained_on": "data/train.csv",
  "data_sha256": "d04183235c0e66c2",
  "cutoff": "2025-08-31",
  "rows": 2863,
  "scikit_learn": "1.9.1"
}
Updating lock file 'dvc.lock'

Running stage 'evaluate':
> python evaluate.py models/lapse.joblib data/test.csv
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
Updating lock file 'dvc.lock'

To track the changes with git, run:

	git add data/.gitignore models/.gitignore dvc.lock

To enable auto staging, run:

	dvc config core.autostage true
Use `dvc push` to send your updates to remote storage.
ana@dev:~/ml$ dvc dag
       +-------------+    
       | shop.db.dvc |    
       +-------------+    
              *           
              *           
              *           
         +---------+      
         | dataset |      
         +---------+      
         **        **     
       **            *    
      *               **  
+-------+               * 
| train |             **  
+-------+            *    
         **        **     
           **    **       
             *  *         
        +----------+      
        | evaluate |      
        +----------+      
ana@dev:~/ml$ dvc push
5 files pushed
```

O `dvc repro` deduziu a ordem pelos arquivos, rodou os três estágios e gravou o **`dvc.lock`**: o
hash de cada dependência e de cada saída, como estavam nesta execução. O `dvc dag` desenha a ordem
que ele achou. O `dvc push` copia as saídas para o remoto, então o modelo deste commit fica tão
guardado quanto os dados de onde veio.

As notas são as da lição 5, até o último dígito: 0,793, 0,522, 190 nos 300 primeiros. **As etapas
são os mesmos programas, então o modelo é o mesmo modelo.**
