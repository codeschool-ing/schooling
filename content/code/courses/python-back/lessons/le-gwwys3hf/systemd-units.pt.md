---
title: Units do systemd para cada processo
version: 1
---

Um processo iniciado num terminal para quando o terminal fecha, não sobe quando a máquina liga, e
ninguém o reinicia se ele morrer. O **systemd** faz as três coisas: cada processo de longa duração ganha
um **arquivo de unit**, e o systemd o inicia, o reinicia, e guarda a saída dele no journal.

## Configurações de produção

Primeiro o que a produção precisa do Django. Acrescente ao fim do `config/settings.py`:

```python
STATIC_ROOT = os.environ.get("DJANGO_STATIC_ROOT", BASE_DIR / "staticfiles")

SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SECURE_SSL_REDIRECT = not DEBUG
SESSION_COOKIE_SECURE = not DEBUG
CSRF_COOKIE_SECURE = not DEBUG
SECURE_HSTS_SECONDS = int(os.environ.get("DJANGO_HSTS_SECONDS", "0"))
```

O `STATIC_ROOT` é onde o `collectstatic` junta os arquivos estáticos de todo app, para que o nginx
possa servi-los de um diretório só. Os outros cinco pertencem ao HTTPS, que a última seção desta aula
traz, e respondem a quatro dos avisos da aula 15. O **`not DEBUG`** faz com que eles sigam a única
marca: desligados na sua máquina, ligados na produção, onde o `DEBUG` está desligado.

```
ana@vm:~/agenda$ sed -n '/^STATIC_ROOT/,$p' config/settings.py
STATIC_ROOT = os.environ.get("DJANGO_STATIC_ROOT", BASE_DIR / "staticfiles")

SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SECURE_SSL_REDIRECT = not DEBUG
SESSION_COOKIE_SECURE = not DEBUG
CSRF_COOKIE_SECURE = not DEBUG
SECURE_HSTS_SECONDS = int(os.environ.get("DJANGO_HSTS_SECONDS", "0"))
ana@vm:~/agenda$ sudo install -d -o ana -g ana /var/www/agenda/static
ana@vm:~/agenda$ DJANGO_STATIC_ROOT=/var/www/agenda/static uv run --env-file .env python manage.py collectstatic --noinput

158 static files copied to '/var/www/agenda/static'.
ana@vm:~/agenda$ ls /var/www/agenda/static
admin
events
rest_framework
```

O `/var/www/agenda/static` fica fora do diretório pessoal de propósito: no Ubuntu 24.04 os diretórios
pessoais são fechados a outros usuários, e o nginx roda como `www-data`.

## Um arquivo de ambiente que só o root lê

A aula 15 prometeu um arquivo que só o serviço consegue ler. O systemd o lê **como root, antes de
iniciar o processo**, então ele pode ser só do root. Monte-o a partir do `.env`, sem o `DJANGO_DEBUG`
de desenvolvimento, e acrescente o que a produção define:

```
ana@vm:~/agenda$ sudo install -d -m 755 /etc/agenda
ana@vm:~/agenda$ grep -v '^DJANGO_DEBUG=' .env | sudo install -m 600 /dev/stdin /etc/agenda/agenda.env
ana@vm:~/agenda$ printf 'DJANGO_ALLOWED_HOSTS=agenda.example.org\nDJANGO_STATIC_ROOT=/var/www/agenda/static\nDJANGO_HSTS_SECONDS=3600\n' | sudo tee -a /etc/agenda/agenda.env > /dev/null
ana@vm:~/agenda$ sudo install -m 600 ../agenda-api/.env /etc/agenda/agenda-api.env
ana@vm:~/agenda$ sudo ls -l /etc/agenda
total 8
-rw------- 1 root root 204 Oct 23 00:55 agenda-api.env
-rw------- 1 root root 293 Oct 23 00:55 agenda.env
ana@vm:~/agenda$ sudo cut -d= -f1 /etc/agenda/agenda.env
DJANGO_SECRET_KEY
DATABASE_USER
DATABASE_PASSWORD
DATABASE_HOST
DJANGO_ALLOWED_HOSTS
DJANGO_STATIC_ROOT
DJANGO_HSTS_SECONDS
```

O `install -m 600` cria cada arquivo legível e gravável só pelo root. Os nomes são visíveis ao `sudo`;
para qualquer outra pessoa, o arquivo está fechado, inclusive para a ana:

```
ana@vm:~/agenda$ cat /etc/agenda/agenda.env
cat: /etc/agenda/agenda.env: Permission denied
```

## As units

Uma unit para a aplicação web, em `/etc/systemd/system/agenda.service`:

```ini
# /etc/systemd/system/agenda.service
[Unit]
Description=agenda: Django under Gunicorn
After=network.target postgresql.service

[Service]
User=ana
WorkingDirectory=/home/ana/agenda
EnvironmentFile=/etc/agenda/agenda.env
ExecStart=/home/ana/agenda/.venv/bin/gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

| linha | faz |
|---|---|
| `After=` | iniciar depois da rede e do PostgreSQL, quando estão na mesma máquina |
| `User=` | rodar como ana; um servidor de verdade teria uma conta só da aplicação |
| `EnvironmentFile=` | as variáveis, lidas pelo systemd como root |
| `ExecStart=` | o caminho completo dentro do `.venv` do projeto: sem `uv run`, nada a resolver na inicialização |
| `Restart=on-failure` | iniciá-lo de novo se sair com erro |
| `WantedBy=` | iniciá-lo quando a máquina liga, depois de habilitado |

O worker e o beat do Celery ganham uma cada, no mesmo formato com outro comando:

```ini
# /etc/systemd/system/agenda-worker.service
[Unit]
Description=agenda: Celery worker
After=network.target postgresql.service redis-server.service

[Service]
User=ana
WorkingDirectory=/home/ana/agenda
EnvironmentFile=/etc/agenda/agenda.env
ExecStart=/home/ana/agenda/.venv/bin/celery -A config worker -l info
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```ini
# /etc/systemd/system/agenda-beat.service
[Unit]
Description=agenda: Celery beat, the one clock
After=network.target redis-server.service

[Service]
User=ana
WorkingDirectory=/home/ana/agenda
EnvironmentFile=/etc/agenda/agenda.env
ExecStart=/home/ana/agenda/.venv/bin/celery -A config beat -l info
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

E o agenda-api, com seu próprio arquivo de ambiente e dois workers do Uvicorn. O `--proxy-headers` e o
`--forwarded-allow-ips` são para o nginx, e a última seção os explica:

```ini
# /etc/systemd/system/agenda-api.service
[Unit]
Description=agenda-api: FastAPI under Uvicorn
After=network.target postgresql.service

[Service]
User=ana
WorkingDirectory=/home/ana/agenda-api
EnvironmentFile=/etc/agenda/agenda-api.env
ExecStart=/home/ana/agenda-api/.venv/bin/uvicorn app.main:app --workers 2 --host 127.0.0.1 --port 8001 --proxy-headers --forwarded-allow-ips 127.0.0.1
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

O `daemon-reload` faz o systemd ler arquivos de unit novos; o `enable --now` inicia cada um e o marca
para iniciar quando a máquina liga:

```
ana@vm:~/agenda$ sudo systemctl daemon-reload
ana@vm:~/agenda$ sudo systemctl enable --now agenda agenda-worker agenda-beat agenda-api
Created symlink /etc/systemd/system/multi-user.target.wants/agenda.service → /etc/systemd/system/agenda.service.
Created symlink /etc/systemd/system/multi-user.target.wants/agenda-worker.service → /etc/systemd/system/agenda-worker.service.
Created symlink /etc/systemd/system/multi-user.target.wants/agenda-beat.service → /etc/systemd/system/agenda-beat.service.
Created symlink /etc/systemd/system/multi-user.target.wants/agenda-api.service → /etc/systemd/system/agenda-api.service.
ana@vm:~/agenda$ systemctl is-active agenda agenda-worker agenda-beat agenda-api
active
active
active
active
ana@vm:~/agenda$ systemctl status agenda --no-pager | head -12
● agenda.service - agenda: Django under Gunicorn
     Loaded: loaded (/etc/systemd/system/agenda.service; enabled; preset: enabled)
     Active: active (running) since Fri 2026-10-23 00:55:48 UTC; 6s ago
   Main PID: 725 (gunicorn)
        CPU: 878ms
     CGroup: /system.slice/agenda.service
             ├─725 /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000
             ├─730 /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000
             ├─736 /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000
             └─739 /home/ana/agenda/.venv/bin/python /home/ana/agenda/.venv/bin/gunicorn config.wsgi --workers 3 --bind 127.0.0.1:8000

Oct 23 00:55:48 vm gunicorn[725]: [2026-10-23 00:55:48 +0000] [725] [INFO] Starting gunicorn 26.2.0
ana@vm:~/agenda$ journalctl -u agenda-api -n 6 --no-pager -o cat
INFO:     Started server process [734]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [732]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

## Conferindo um servidor rodando

Os testes da aula 14 conferiram o código do agenda. Uma implantação é conferida de outro jeito: todo
serviço ativo, um worker respondendo, a aplicação respondendo pelo seu nome de host.

```
ana@vm:~/agenda$ systemctl is-active postgresql redis-server
active
active
ana@vm:~/agenda$ uv run --env-file .env celery -A config inspect ping
->  celery@vm: OK
        pong

1 node online.
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" -H "Host: agenda.example.org" http://127.0.0.1:8000/events/
301 https://agenda.example.org/events/
ana@vm:~/agenda$ curl -s -H "Host: api.agenda.example.org" http://127.0.0.1:8001/events/django-night; echo
{"slug":"django-night","title":"Django Night","starts_at":"2026-11-12T19:00:00-03:00","venue":"Community Centre, room 3","capacity":40,"description":"","taken":1}
```

**`pong` do `celery@vm`** é o worker respondendo pelo Redis, o que prova o broker e o worker de uma vez.
O 301 é o Django mandando uma requisição HTTP simples para HTTPS, porque o `DEBUG` está desligado: nada
responde em HTTPS ainda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 266\" role=\"img\" aria-label=\"Um navegador fala só com o nginx, que redireciona a porta 80, encerra o TLS na 443, serve /static/ do disco e acrescenta cabeçalhos. O nginx passa requisições ao agenda.service, Gunicorn na porta 8000 com três workers, e ao agenda-api.service, Uvicorn na porta 8001 com dois workers. O agenda-worker e o agenda-beat rodam o Celery. As aplicações usam o PostgreSQL; o agenda e os serviços do Celery usam o Redis.\"> <defs><marker id=\"lo-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"110\" width=\"100\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"70\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um navegador</text> <rect x=\"160\" y=\"90\" width=\"150\" height=\"86\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"235\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">nginx</text> <text x=\"235\" y=\"130\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">:80 redireciona, :443 TLS</text> <text x=\"235\" y=\"146\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/static/ do disco</text> <text x=\"235\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">acrescenta cabeçalhos</text> <path d=\"M120 133 L156 133\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lo-a)\"></path> <rect x=\"360\" y=\"40\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"450\" y=\"60\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">agenda.service</text> <text x=\"450\" y=\"76\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gunicorn :8000, 3 workers</text> <path d=\"M310 133 L356 63\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lo-a)\"></path> <rect x=\"360\" y=\"186\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"450\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">agenda-api.service</text> <text x=\"450\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uvicorn :8001, 2 workers</text> <path d=\"M310 133 L356 209\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lo-a)\"></path> <rect x=\"360\" y=\"112\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"450\" y=\"132\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">agenda-worker, agenda-beat</text> <text x=\"450\" y=\"148\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Celery</text> <rect x=\"590\" y=\"60\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"645\" y=\"85\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">PostgreSQL</text> <rect x=\"590\" y=\"150\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"645\" y=\"175\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Redis</text> <path d=\"M540 63 L586 80\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lo-a)\"></path> <path d=\"M540 209 L586 90\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lo-a)\"></path> <path d=\"M540 135 L586 170\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lo-a)\"></path> <path d=\"M540 70 L586 165\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#lo-a)\"></path> <text x=\"360\" y=\"252\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Só o nginx escuta além da máquina; tudo atrás dele responde em 127.0.0.1.</text> </svg>", "caption": "O agenda em produção, como esta aula o deixa: sete serviços sob o systemd, um deles virado para o mundo.", "same": ["PostgreSQL", "Redis", "Celery", "gunicorn :8000, 3 workers", "uvicorn :8001, 2 workers"]}
```
