---
title: O settings.py é Python, e DEBUG é a configuração a respeitar
version: 1
---

O `config/settings.py` é um módulo Python comum. O Django o importa uma vez, na partida, e cada
configuração é uma variável em maiúsculas. As que este curso mexe estão nestas linhas:

```
ana@vm:~/agenda$ grep -nE '^(DEBUG|ALLOWED_HOSTS|ROOT_URLCONF|WSGI_APPLICATION|LANGUAGE_CODE|TIME_ZONE|USE_TZ|STATIC_URL) ' config/settings.py
26:DEBUG = True
28:ALLOWED_HOSTS = []
52:ROOT_URLCONF = 'config.urls'
69:WSGI_APPLICATION = 'config.wsgi.application'
105:LANGUAGE_CODE = 'en-us'
107:TIME_ZONE = 'UTC'
111:USE_TZ = True
117:STATIC_URL = 'static/'
```

| configuração | o que decide |
|---|---|
| `DEBUG` | páginas de erro detalhadas, e algumas verificações de segurança desligadas. **Nunca ligado em produção** |
| `ALLOWED_HOSTS` | os nomes de host aos quais o site responde; vazio só é permitido com o `DEBUG` ligado |
| `ROOT_URLCONF` | qual módulo tem a primeira tabela de URLs |
| `WSGI_APPLICATION` | o objeto que o `runserver` e um servidor WSGI carregam |
| `LANGUAGE_CODE` | o idioma das mensagens do próprio Django |
| `TIME_ZONE`, `USE_TZ` | o fuso em que as datas aparecem; com `USE_TZ`, elas são gravadas em UTC |
| `STATIC_URL` | de onde saem CSS e imagens (aula 3) |

## Uma mudança, e como ver que pegou

Os eventos do agenda acontecem em São Paulo, então as datas devem aparecer nesse fuso. Mude uma linha
num editor:

```python
TIME_ZONE = 'America/Sao_Paulo'
```

O `diffsettings` imprime toda configuração diferente dos padrões do Django, então é o jeito mais
rápido de perguntar com o que o projeto está rodando de fato:

```
ana@vm:~/agenda$ uv run python manage.py diffsettings | grep -E "^(TIME_ZONE|DEBUG|ROOT_URLCONF)"
DEBUG = True
ROOT_URLCONF = 'config.urls'  ###
TIME_ZONE = 'America/Sao_Paulo'
```

O `###` marca uma configuração que não tem padrão nenhum no Django. Com `USE_TZ = True`, ainda
ligado, **as datas são gravadas em UTC e convertidas para o `TIME_ZONE` só quando aparecem**. Esse é
o arranjo certo, e é por isso que a mudança é segura a qualquer momento: nada gravado se mexe.

## Do que o `DEBUG` protege você, e o que ele expõe

Com `DEBUG = True`, um erro numa view produz uma página com o traceback, as variáveis locais de cada
quadro e a maior parte das configurações. É o que você quer na sua máquina e exatamente o que ninguém
mais deveria ver. Desligue, e o Django imediatamente exige algo que deixava passar:

```
ana@vm:~/agenda$ uv run python manage.py runserver --settings config.settings_nodebug
CommandError: You must set settings.ALLOWED_HOSTS if DEBUG is False.
```

Essa execução usou uma cópia do `settings.py` com `DEBUG = False` e nada mais mudado. **Com a
depuração desligada, o Django se recusa a servir até o `ALLOWED_HOSTS` dizer os nomes de host a que
deve responder**, e assim uma requisição com um cabeçalho `Host` forjado é recusada em vez de ser
usada para montar links. A aula 15 tira `DEBUG`, `ALLOWED_HOSTS` e `SECRET_KEY` deste arquivo e os
leva para o ambiente, que é onde moram valores que diferem entre a sua máquina e a produção. Até lá,
deixe `DEBUG = True` e `ALLOWED_HOSTS = []`.

A `SECRET_KEY` no topo do arquivo começa com `django-insecure-`, que é o jeito do Django de dizer a
mesma coisa sobre uma chave escrita num arquivo e lida por todo mundo que ler o arquivo.
