---
title: Nada mudou, então nada roda
version: 1
---

Rode o pipeline de novo logo em seguida:

```
ana@dev:~/ml$ dvc repro
'shop.db.dvc' didn't change, skipping
Stage 'dataset' didn't change, skipping
Stage 'train' didn't change, skipping
Stage 'evaluate' didn't change, skipping
Data and pipelines are up to date.
ana@dev:~/ml$ git add . && git commit -qm "lapse model v1" && git tag v1 && git log --oneline
ffa462d lapse model v1
4bb4b2d the lapse pipeline, and the shop it reads
```

**Todo estágio é pulado**, porque toda dependência tem o hash que o `dvc.lock` registrou. Na loja da
Ponto Final isso economiza segundos; num conjunto de dados que leva uma hora para ser montado,
economiza a hora, e numa agenda noturna quer dizer que uma noite sem dados novos não custa nada.

Depois, o commit que transforma isto numa versão. O `git add .` pega o `dvc.lock`, os dois
`.gitignore` que o DVC gravou e as notas, e a tag `v1` dá ao commit um nome que uma pessoa consegue
digitar. **O commit `v1` agora nomeia tudo**: o código, a loja pelo seu ponteiro, o arquivo de
treino e o modelo exatos pelo `dvc.lock`, e as notas em texto puro.
