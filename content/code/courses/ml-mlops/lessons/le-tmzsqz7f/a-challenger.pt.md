---
title: Um desafiante, pelo mesmo pipeline
version: 1
---

Um desafiante não é um modelo que alguém treina num notebook. **É o pipeline das lições 5 a 7
rodado com datas novas**, então ele chega com um commit, um hash de dados, um teste e uma entrada no
registro, como o campeão chegou. Três coisas mudam antes do `dvc repro`.

**Primeiro, os programas das lições 8 a 10 entram no Git.** O `log_run.py` recusa uma árvore de
trabalho com qualquer coisa não commitada, e o lote, o serviço e as checagens são código como
qualquer outro. O log de pedidos não é, então ele entra nos arquivos ignorados:

```
ana@dev:~/ml$ printf 'requests.log\n' >> .gitignore && git add .gitignore *.py && git commit -qm "serving, monitoring and drift" && git log --oneline -n 1
f25f8cc serving, monitoring and drift
```

**Segundo, a receita é a da versão 1.** A árvore de trabalho ainda tem o `model.py` da versão 2, os
pesos balanceados que a lição 7 rejeitou. O Git consegue trazer de volta um arquivo de qualquer
commit, e a receita do campeão é a que um desafiante deve melhorar, mudando só os dados:

```
ana@dev:~/ml$ git checkout v1 -- model.py && git diff --stat HEAD
 model.py | 8 ++------
 1 file changed, 2 insertions(+), 6 deletions(-)
```

**Terceiro, as datas.** O `dvc.yaml` nomeia as noites de treino e de teste no estágio `dataset`. A
regra da seção anterior dá 28 de dezembro de 2025 e 29 de março de 2026; o `sed` troca as duas datas
no lugar, e o `git diff` mostra exatamente o que mudou:

```
ana@dev:~/ml$ sed -i 's/2025-08-31/2025-12-28/; s/2025-11-30/2026-03-29/' dvc.yaml && git diff dvc.yaml
diff --git a/dvc.yaml b/dvc.yaml
index e34c9ea..2a836fa 100644
--- a/dvc.yaml
+++ b/dvc.yaml
@@ -2,8 +2,8 @@
 stages:
   dataset:
     cmd: >-
-      python build_dataset.py 2025-08-31 data/train.csv &&
-      python build_dataset.py 2025-11-30 data/test.csv &&
+      python build_dataset.py 2025-12-28 data/train.csv &&
+      python build_dataset.py 2026-03-29 data/test.csv &&
       python validate.py data/train.csv &&
       python validate.py data/test.csv
     deps: [build_dataset.py, validate.py, features.py, project.py, shop.db]
```

Depois, o pipeline. O DVC vê que `shop.db`, `model.py` e `dvc.yaml` mudaram, então roda de novo os
três estágios, e o `evaluate.py` imprime o teste do desafiante:

```
ana@dev:~/ml$ dvc repro -q
data/train.csv: 3201 members as of 2025-12-28, 17.0% lapsed
data/test.csv: 3429 members as of 2026-03-29, 21.0% lapsed
data/train.csv: 3201 rows, every check passed
data/test.csv: 3429 rows, every check passed
{
  "model": "models/lapse.joblib",
  "trained_on": "data/train.csv",
  "data_sha256": "6892fba5956be6b8",
  "cutoff": "2025-12-28",
  "rows": 3201,
  "scikit_learn": "1.9.1"
}
{
  "test": "data/test.csv",
  "cutoff": "2026-03-29",
  "members": 3429,
  "lapsed": 720,
  "roc_auc": 0.745,
  "average_precision": 0.5,
  "baseline_average_precision": 0.21,
  "lapsed_in_top_300": 196,
  "said": 0.175
}
```

Commite, marque com uma tag e registre, exatamente como a lição 7 fez com a versão 1:

```
ana@dev:~/ml$ git add . && git commit -qm "lapse model v3: retrained on 28 December 2025" && git tag v3 && python log_run.py
Registered model 'lapse' already exists. Creating a new version of this model...
Created version '3' of model 'lapse'.
run 9e55a691, registered as lapse version 3
```

**A versão 3 está no registro, e o apelido não se moveu.** Registrar é anotar; promover é uma
decisão, e a próxima seção a toma.
