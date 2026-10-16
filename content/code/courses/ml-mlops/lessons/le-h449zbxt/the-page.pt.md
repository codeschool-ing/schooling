---
title: A página do MLflow, e o que ela guarda
version: 1
---

Tudo o que o MLflow registrou nesta lição está no `mlflow.db` e no `mlruns/`, e **o MLflow vem com uma
página web para navegar por eles**. Inicie-a num segundo terminal, com o ambiente ativo, a partir de
`~/ml`:

```sh
MLFLOW_SERVER_ENABLE_JOB_EXECUTION=false mlflow server --backend-store-uri sqlite:///mlflow.db --host 127.0.0.1 --port 5000 --workers 1
```

Ela fica rodando até você apertar Ctrl+C. Depois abra `http://127.0.0.1:5000` num navegador. Em
**Experiments** estão `lapse`, com as duas execuções do pipeline, e `lapse-experiments`, com os cinco
candidatos; em **Models** está `lapse`, com as duas versões e o apelido `champion` na versão 1.

**Os dois ajustes na frente do comando são sobre memória.** Por padrão o servidor também inicia um
conjunto de workers em segundo plano para recursos que este curso não usa, e na máquina de gravação o
servidor e esse conjunto juntos ocuparam mais de 2 GB de memória.
`MLFLOW_SERVER_ENABLE_JOB_EXECUTION=false` os deixa de fora, e `--workers 1` mantém um processo
respondendo às páginas, o que basta para uma pessoa.

A página também é uma **API**, que é como outros programas fazem perguntas ao registro. No primeiro
terminal:

```
ana@dev:~/ml$ curl -s "http://127.0.0.1:5000/api/2.0/mlflow/registered-models/get?name=lapse" | python -m json.tool | grep -E "\"(name|version|alias|status)\""
        "name": "lapse",
                "name": "lapse",
                "version": "2",
                "status": "READY"
                "alias": "champion",
                "version": "1"
ana@dev:~/ml$ ps -o pid,rss,args -u ana | grep -E "mlflow server|uvicorn" | grep -v grep | cut -c1-72
 3065 239180 /home/ana/mlenv/bin/python3 /home/ana/mlenv/bin/mlflow serv
 3080 243864 /home/ana/mlenv/bin/python3 -m uvicorn --log-config /home/a
```

O registro responde em JSON: o modelo `lapse`, a sua versão mais nova, e o apelido `champion`
apontando para a versão 1. O último comando lista os dois processos do servidor e a memória de cada
um, em kilobytes: juntos uns 480 MB, o número que a lição 1 citou.

Num time, este servidor roda numa máquina compartilhada com o banco no PostgreSQL e os arquivos num
armazenamento de objetos, e todo job de treino e serviço aponta `MLFLOW_TRACKING_URI` para ele. **Os
programas não mudam**: o `log_run.py` e o `champion.py` seriam apontados para uma URL em vez de um
arquivo.
