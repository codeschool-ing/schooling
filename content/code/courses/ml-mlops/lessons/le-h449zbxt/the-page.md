---
title: MLflow's page, and what it holds
version: 1
---

Everything MLflow recorded in this lesson is in `mlflow.db` and `mlruns/`, and **MLflow comes with a
web page to browse them**. Start it in a second terminal, with the environment active, from `~/ml`:

```sh
MLFLOW_SERVER_ENABLE_JOB_EXECUTION=false mlflow server --backend-store-uri sqlite:///mlflow.db --host 127.0.0.1 --port 5000 --workers 1
```

It keeps running until you press Ctrl+C. Then open `http://127.0.0.1:5000` in a browser. Under
**Experiments** are `lapse`, with the pipeline's two runs, and `lapse-experiments`, with the five
candidates; under **Models** is `lapse`, with its two versions
and the alias `champion` on version 1.

**The two settings in front of the command are about memory.** By default the server also starts a
pool of background workers for features this course does not use, and on the recording machine the
server and that pool together held over 2 GB of memory. `MLFLOW_SERVER_ENABLE_JOB_EXECUTION=false` leaves them out, and
`--workers 1` keeps one process answering pages, which is plenty for one person.

The page is also an **API**, which is how other programs ask the registry questions. From the first
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

The registry answers in JSON: the model `lapse`, its latest version, and the alias `champion`
pointing at version 1. The last command lists the server's two processes and the memory each holds,
in kilobytes: together about 480 MB, the figure lesson 1 quoted.

On a team, this server runs on a shared machine with its database in PostgreSQL and its files in
object storage, and every training job and service points `MLFLOW_TRACKING_URI` at it. **The
programs do not change**: `log_run.py` and `champion.py` would be pointed at a URL instead of a file.
