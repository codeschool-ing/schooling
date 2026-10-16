---
title: Voltando a qualquer versão
version: 1
---

Dois commits, dois modelos, e o diretório de trabalho tem o da versão 2. **Ter a versão 1 de volta são
dois comandos**: o Git restaura o código e os arquivos ponteiro, e o DVC restaura os dados e o modelo
para os quais eles apontam.

```
ana@dev:~/ml$ git checkout -q v1 && dvc checkout
M       models/lapse.joblib
ana@dev:~/ml$ python -c "import json; print(json.load(open(\"models/lapse.json\"))[\"data_sha256\"])"
d04183235c0e66c2
ana@dev:~/ml$ md5sum models/lapse.joblib && grep -A2 "path: models/lapse.joblib" dvc.lock | grep "md5: "
cf238ebab7e13284d31b1e29bb8f8df7  models/lapse.joblib
      md5: cf238ebab7e13284d31b1e29bb8f8df7
      md5: cf238ebab7e13284d31b1e29bb8f8df7
ana@dev:~/ml$ git checkout -q main && dvc checkout
M       models/lapse.joblib
```

Depois do `git checkout v1`, o `dvc checkout` viu que o modelo no disco não batia com o `dvc.lock` e o
substituiu a partir do cache; o `M` marca o arquivo que ele mudou. A impressão digital do arquivo de
treino é de novo `d04183235c0e66c2`, a que a lição 5 imprimiu, e o MD5 do arquivo do modelo é o que o
`dvc.lock` registra para o v1, duas vezes porque o arquivo é saída do treino e entrada da avaliação.
De volta ao `main`, os mesmos dois comandos põem o modelo da versão 2 de volta.

**É isso que reprodutível quer dizer na prática**: não "provavelmente daríamos para refazer", e sim
os bytes exatos do modelo que mandou os vouchers do mês passado, recuperados pelo nome. Quer dizer
também que a resposta à pergunta de um auditor, *com que dados este modelo aprendeu?*, é um commit e
um hash.

O `dvc checkout` restaura a partir do cache local. Num computador novo, ou depois de o cache ser
limpo, um `git clone` seguido de `dvc pull` busca os mesmos arquivos no remoto, e é por isso que a
seção 05 configurou um e a seção 06 enviou para ele.
