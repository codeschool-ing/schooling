---
title: Gunicorn e Uvicorn no lugar do runserver
version: 1
---

O `runserver` diz isso a cada início desde a aula 2: *este é um servidor de desenvolvimento, não o use
em produção*. Ele recarrega a cada mudança, serve arquivos estáticos do jeito lento, e foi feito para
ser conveniente, não para aguentar. Um servidor roda a aplicação sob um **servidor de aplicação**: o
**Gunicorn** para o lado WSGI do Django, e o Uvicorn, que o agenda-api já usa, para ASGI.

```
ana@vm:~/agenda$ uv add gunicorn
Resolved 42 packages in 756ms
Prepared 1 package in 50ms
Installed 1 package in 3ms
 + gunicorn==26.2.0
```

O Gunicorn recebe a aplicação WSGI pelo caminho de importação, `config.wsgi`, o módulo que o
`startproject` escreveu na aula 2 e que nada usou até agora:

```
ana@vm:~/agenda$ uv run --env-file .env gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000
[2026-10-23 00:55:29 +0000] [319] [INFO] Starting gunicorn 26.2.0
[2026-10-23 00:55:29 +0000] [319] [INFO] Listening at: http://127.0.0.1:8000 (319)
[2026-10-23 00:55:29 +0000] [319] [INFO] Using worker: sync
[2026-10-23 00:55:29 +0000] [320] [INFO] Booting worker with pid: 320
[2026-10-23 00:55:29 +0000] [321] [INFO] Booting worker with pid: 321
[2026-10-23 00:55:29 +0000] [322] [INFO] Booting worker with pid: 322
[2026-10-23 00:55:29 +0000] [319] [INFO] Control socket listening at /run/user/1000/gunicorn.ctl
ana@vm:~/agenda$ ps -o pid,ppid,cmd --forest -C gunicorn | cut -c1-90
    PID    PPID CMD
    319     316 /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn conf
    320     319  \_ /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn 
    321     319  \_ /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn 
    322     319  \_ /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn 
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/
200
```

**Um mestre e três workers.** O mestre abre o socket e não faz mais nada; cada worker é um processo
separado com sua própria cópia do Django, respondendo uma requisição por vez. Um ponto de partida comum
é dois ou três workers por processador, ajustado depois de observar a máquina sob carga real. Mate um
worker, como uma queda ou o killer de falta de memória do kernel faria:

```
ana@vm:~/agenda$ kill -9 $(pgrep -n gunicorn)
```

O mestre percebeu na hora e iniciou outro:

```
[2026-10-23 00:55:34 +0000] [319] [ERROR] Worker (pid:322) was sent SIGKILL! Perhaps out of memory?
[2026-10-23 00:55:34 +0000] [351] [INFO] Booting worker with pid: 351
[2026-10-23 00:55:34 +0000] [319] [INFO] Control socket listening at /run/user/1000/gunicorn.ctl
```

## Os workers do Uvicorn

O agenda-api rodou com `--workers 4` na aula 10. O gerenciador de processos do próprio Uvicorn faz o que
o mestre do Gunicorn faz, então ele não precisa de Gunicorn na frente:

```
ana@vm:~/agenda-api$ uv run uvicorn app.main:app --workers 2 --host 127.0.0.1 --port 8001
INFO:     Uvicorn running on http://127.0.0.1:8001 (Press CTRL+C to quit)
INFO:     Started parent process [376]
INFO:     Started server process [378]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [379]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

Os workers são processos Python iniciados pelo `multiprocessing`, que é o nome pelo qual o `pgrep` os
acha. Mate um:

```
ana@vm:~/agenda-api$ kill -9 $(pgrep -f 'multiprocessing.spawn' | head -1)
```

```
INFO:     Waiting for child process [378]
INFO:     Child process [378] died
INFO:     Started server process [496]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

**Gunicorn com workers do Uvicorn** é o jeito mais antigo de ter a mesma supervisão para uma aplicação
ASGI, e ainda é comum; desde o Uvicorn 0.30 o gerenciador dele reinicia workers mortos, que é tudo de
que o agenda-api precisa. O Django também pode rodar sob o Uvicorn, pelo `config.asgi`, como a aula 9
fez: essa é a escolha para um projeto Django com views assíncronas, e o Gunicorn para um sem.
