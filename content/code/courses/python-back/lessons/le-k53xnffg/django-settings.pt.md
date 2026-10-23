---
title: As configurações do Django a partir do ambiente
version: 1
---

Troque o topo do `config/settings.py`, do `from pathlib import Path` até o `ALLOWED_HOSTS`, por:

```python
import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
DEBUG = os.environ.get("DJANGO_DEBUG") == "1"
ALLOWED_HOSTS = [host for host in os.environ.get("DJANGO_ALLOWED_HOSTS", "").split(",") if host]
```

Cada linha escolhe o que acontece quando o valor falta, e a escolha é deliberada:

| configuração | quando falta | por quê |
|---|---|---|
| `SECRET_KEY` | **a aplicação se recusa a subir** | nenhum padrão é seguro: uma chave no código é uma chave que todo mundo com o código tem |
| `DEBUG` | **desligado** | uma variável faltando num servidor não pode ligar a página que mostra configurações e tracebacks |
| `ALLOWED_HOSTS` | vazio | com o `DEBUG` ligado, o Django então permite `localhost`; desligado, nada, o que falha do lado seguro |

O `DATABASES` lê suas partes do mesmo jeito, voltando ao socket local da aula 4 quando nada está
definido:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DATABASE_NAME', 'agenda'),
        'USER': os.environ.get('DATABASE_USER', ''),
        'PASSWORD': os.environ.get('DATABASE_PASSWORD', ''),
        'HOST': os.environ.get('DATABASE_HOST', ''),
    }
}
```

E o `CELERY_BROKER_URL` vira `os.environ.get("CELERY_BROKER_URL", "redis://127.0.0.1:6379/0")`, para
que um Redis hospedado, da tabela da aula 13, seja um valor e não uma edição:

```
ana@vm:~/agenda$ grep -n 'os.environ' config/settings.py
19:SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
20:DEBUG = os.environ.get("DJANGO_DEBUG") == "1"
21:ALLOWED_HOSTS = [host for host in os.environ.get("DJANGO_ALLOWED_HOSTS", "").split(",") if host]
75:        'NAME': os.environ.get('DATABASE_NAME', 'agenda'),
76:        'USER': os.environ.get('DATABASE_USER', ''),
77:        'PASSWORD': os.environ.get('DATABASE_PASSWORD', ''),
78:        'HOST': os.environ.get('DATABASE_HOST', ''),
143:CELERY_BROKER_URL = os.environ.get("CELERY_BROKER_URL", "redis://127.0.0.1:6379/0")
ana@vm:~/agenda$ uv run python manage.py check 2>&1 | tail -1
KeyError: 'DJANGO_SECRET_KEY'
```

**A aplicação se recusa a subir**, que é o objetivo: um servidor sem chave falha na hora, num log, em
vez de rodar com uma chave que qualquer um poderia saber.

## Um arquivo .env para esta máquina

Digitar as variáveis antes de todo comando não dura. Um **arquivo `.env`** as guarda, um `NOME=valor`
por linha, e o `uv run --env-file .env` as põe no ambiente do comando que roda. Gere a chave em vez de
inventar uma, e escreva-a direto no arquivo, para que ela nunca apareça na tela:

```
ana@vm:~/agenda$ printf 'DJANGO_SECRET_KEY=%s\nDJANGO_DEBUG=1\n' "$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')" > .env
ana@vm:~/agenda$ uv run --env-file .env python manage.py check
System check identified no issues (0 silenced).
```

De agora em diante todo comando do Django neste curso roda como `uv run --env-file .env ...`. Uma
variável definida no shell vence o arquivo, o que a última seção usa.
