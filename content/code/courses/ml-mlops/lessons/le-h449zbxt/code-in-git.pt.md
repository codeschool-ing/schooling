---
title: O código vai para o Git
version: 1
---

O `~/ml` vira um repositório Git. Antes do primeiro commit, o Git precisa saber o que não guardar,
porque alguns arquivos do diretório não são código. Salve isto como `.gitignore`, com o ponto:

```
features.db
mlflow.db
mlruns/
__pycache__/
```

O `features.db` é o armazenamento da lição 6, reconstruído a partir da loja a qualquer hora. O
`mlflow.db` e o `mlruns/` são onde o MLflow vai guardar as suas execuções a partir da seção 08, um
registro próprio que não pertence ao histórico do código. O `shop.db` não está na lista: ele é dado,
e a próxima seção o entrega ao DVC.

```
ana@dev:~/ml$ git init -q && dvc init -q && git status --short | head -n 4
A  .dvc/.gitignore
A  .dvc/config
A  .dvcignore
?? .gitignore
```

`git init` cria o repositório e `dvc init` acrescenta o diretório do próprio DVC, `.dvc`, ao lado do
do Git. **Nada é commitado ainda**, de propósito: o `shop.db` não é rastreado nem ignorado, então um
`git add .` agora poria seis megabytes de SQLite no histórico do código, onde todo clone o carregaria
para sempre. A próxima seção o leva primeiro para o DVC.
