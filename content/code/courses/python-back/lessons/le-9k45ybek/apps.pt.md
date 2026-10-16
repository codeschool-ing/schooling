---
title: Um app é uma pasta que o Django conhece
version: 1
---

Um **projeto** Django é a configuração. O código mora em **apps**: pacotes com seus próprios modelos,
views, URLs e templates, que o projeto liga no `INSTALLED_APPS`. O admin, os usuários e as sessões
que você migrou também são apps, escritos pelo Django e ligados pelo `startproject`. O agenda ganha um
seu, `events`:

```
ana@vm:~/agenda$ uv run python manage.py startapp events
ana@vm:~/agenda$ find events -type f | sort
events/__init__.py
events/admin.py
events/apps.py
events/migrations/__init__.py
events/models.py
events/tests.py
events/views.py
```

| arquivo | para que serve |
|---|---|
| `models.py` | as tabelas, como classes (aula 4) |
| `views.py` | as funções que respondem às requisições (esta aula) |
| `admin.py` | como os modelos aparecem no admin (aula 5) |
| `apps.py` | a configuração do app: nome e rótulo |
| `migrations/` | o histórico das tabelas dele (aula 4) |
| `tests.py` | os testes; a aula 14 o troca por um diretório `tests/` |

Não há `urls.py`, porque nem todo app responde a URLs; a próxima seção acrescenta um.

## Ligando o app

Um app que o Django não conhece é uma pasta como outra qualquer: os modelos não ganham tabelas e os
templates não são achados. Acrescente-o ao fim do `INSTALLED_APPS` em `config/settings.py`:

```
ana@vm:~/agenda$ sed -n '/^INSTALLED_APPS/,/^]/p' config/settings.py
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'events',
]
ana@vm:~/agenda$ uv run python manage.py check
System check identified no issues (0 silenced).
```

O `check` passar é a confirmação de que o nome aponta para um pacote que o Django conseguiu importar.

## De onde vêm os eventos, por enquanto

Os eventos vão morar no PostgreSQL a partir da aula 4. Até lá, uma lista de dicionários faz o papel
da tabela, para que as URLs e as views possam ser construídas antes. Salve como `events/data.py`:

```python
# events/data.py
EVENTS = [
    {
        "slug": "django-night",
        "title": "Django Night",
        "starts_at": "2026-11-12T19:00",
        "venue": "Community Centre, room 3",
        "capacity": 40,
    },
    {
        "slug": "async-workshop",
        "title": "Async Python workshop",
        "starts_at": "2026-11-19T14:00",
        "venue": "Public Library, lab 2",
        "capacity": 12,
    },
    {
        "slug": "testing-dojo",
        "title": "Testing dojo",
        "starts_at": "2026-11-26T19:00",
        "venue": "Community Centre, room 3",
        "capacity": 20,
    },
]
```

**As datas estão escritas como texto e sem fuso.** É um atalho que este arquivo pode se dar porque
nada as compara ainda; a aula 4 as transforma em valores reais de data e hora, gravados em UTC.

## Um app ou vários

A pergunta aparece na primeira semana de todo projeto Django. Uma parte merece virar app quando tem
**um trabalho que se diz numa frase** e tabelas próprias: eventos, e mais tarde talvez pagamentos. O
agenda continua um app só o curso inteiro, porque tudo nele é sobre eventos e sobre as pessoas que se
inscrevem neles. Separar cedo demais custa imports entre apps que sabem demais um do outro; separar
tarde custa uma migração que move tabelas, que é assunto da aula 4 e não é pequeno.
