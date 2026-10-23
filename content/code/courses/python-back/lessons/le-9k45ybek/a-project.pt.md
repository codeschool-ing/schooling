---
title: Um projeto é um módulo de configuração e um manage.py
version: 1
---

Desta aula até o fim do curso você constrói o **agenda**, o site de eventos que a aula 1 descreveu.
Ele começa como o projeto hello começou, num diretório próprio, com o Django vindo do PyPI:

```
ana@vm:~$ mkdir agenda && cd agenda && uv init --bare && uv add django
Initialized project `agenda`
Using CPython 3.12.3 interpreter at: /usr/bin/python3
Creating virtual environment at: .venv
Resolved 5 packages in 147ms
Installed 3 packages in 527ms
 + asgiref==3.12.1
 + django==6.1.2
 + sqlparse==0.6.0
ana@vm:~/agenda$ uv run django-admin startproject config .
```

**O pacote do projeto se chama `config`**, não `agenda`. O `startproject` dá ao pacote o nome do
primeiro argumento, e com o diretório já chamado `agenda`, um segundo `agenda` dentro dele deixaria
todo import ambíguo de ler: `agenda.settings` ou o diretório? `config` diz o que o pacote guarda. O
`.` no fim põe o `manage.py` no diretório atual em vez de num novo.

O que o `startproject` escreveu é o mesmo conjunto que a aula 1 listou, com o nome novo:

| arquivo | o que é |
|---|---|
| `manage.py` | a porta de entrada da linha de comando; põe `DJANGO_SETTINGS_MODULE` em `config.settings` e roda um comando |
| `config/settings.py` | **todas as configurações do projeto**, como variáveis Python comuns |
| `config/urls.py` | a tabela de URLs do projeto, a primeira que o Django lê em toda requisição |
| `config/wsgi.py`, `config/asgi.py` | o objeto de aplicação que um servidor WSGI ou ASGI importa (aula 1, e aula 16) |
| `config/__init__.py` | vazio; faz de `config` um pacote |

## A primeira migração

A aula 1 avisou de 18 migrações pendentes. São as tabelas dos apps que o `startproject` ligou, e
aplicá-las cria o banco, que por enquanto é um único arquivo SQLite:

```
ana@vm:~/agenda$ uv run python manage.py migrate
Operations to perform:
  Apply all migrations: admin, auth, contenttypes, sessions
Running migrations:
  Applying contenttypes.0001_initial... OK
  Applying auth.0001_initial... OK
  Applying admin.0001_initial... OK
  Applying admin.0002_logentry_remove_auto_add... OK
  Applying admin.0003_logentry_add_action_flag_choices... OK
  Applying contenttypes.0002_remove_content_type_name... OK
  Applying auth.0002_alter_permission_name_max_length... OK
  Applying auth.0003_alter_user_email_max_length... OK
  Applying auth.0004_alter_user_username_opts... OK
  Applying auth.0005_alter_user_last_login_null... OK
  Applying auth.0006_require_contenttypes_0002... OK
  Applying auth.0007_alter_validators_add_error_messages... OK
  Applying auth.0008_alter_user_username_max_length... OK
  Applying auth.0009_alter_user_last_name_max_length... OK
  Applying auth.0010_alter_group_name_max_length... OK
  Applying auth.0011_update_proxy_permissions... OK
  Applying auth.0012_alter_user_first_name_max_length... OK
  Applying sessions.0001_initial... OK
ana@vm:~/agenda$ ls
config
db.sqlite3
manage.py
pyproject.toml
uv.lock
```

Cada linha é uma mudança no esquema, na ordem em que o app a declarou, e cada uma roda uma vez só: o
Django registra numa tabela própria quais migrações já foram aplicadas, então rodar o `migrate` de
novo não faz nada. **O `db.sqlite3` é o banco inteiro.** O SQLite não precisa de servidor, e é por
isso que o Django começa com ele; a aula 4 leva o agenda para o PostgreSQL, e nada escrito até lá
precisa mudar.

## O servidor de desenvolvimento, e a página que diz que deu certo

Suba com `uv run python manage.py runserver`, desta vez sem porta, para ele usar a padrão, 8000. Um
projeto sem URLs próprias responde `/` com uma página do Django:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/ | grep -o "<title>.*</title>"
<title>The install worked successfully! Congratulations!</title>
<title>Django</title>
```

Dois títulos, porque a página tem um SVG com título próprio. **Essa página só existe enquanto o
`DEBUG` está ligado e o projeto não tem URLs**, e some no momento em que a primeira URL da próxima
seção é acrescentada.

## O `manage.py` é uma lista de comandos

Todo comando desta aula passa pelo `manage.py`. Os do próprio Django vêm primeiro na ajuda, e os apps
que você instala acrescentam os deles abaixo:

```
ana@vm:~/agenda$ uv run python manage.py help | sed -n "/\[django\]/,/^$/p" | head -12
[django]
    check
    compilemessages
    createcachetable
    dbshell
    diffsettings
    dumpdata
    flush
    inspectdb
    loaddata
    makemessages
    makemigrations
```

O `check` inspeciona o projeto sem rodá-lo, o `diffsettings` imprime o que difere dos padrões, o
`shell` abre o Python com o projeto carregado, e `migrate` e `makemigrations` são da aula 4. **Rode o
`check` depois de qualquer mudança que possa não ter dado certo**: leva um segundo e acha um app com
nome errado ou uma URL quebrada antes de uma requisição achar.
