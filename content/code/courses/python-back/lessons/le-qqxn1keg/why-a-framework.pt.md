---
title: Por que uma API precisa de mais que o JsonResponse
version: 1
---

A aula 2 respondia com `JsonResponse`, e para ler três eventos isso bastava. Uma API que outros
programas usam tem mais a fazer, e cada um destes trabalhos seria escrito à mão em cada view:

| trabalho | à mão | com o Django REST Framework |
|---|---|---|
| ler um corpo JSON | `json.loads(request.body)`, e um 500 quando não é JSON | `request.data`, e um 400 que diz onde o JSON quebrou |
| validá-lo | um `if` por campo | um **serializer**, que é um formulário para JSON |
| transformar linhas em JSON | um dicionário montado à mão por modelo | o mesmo serializer, no outro sentido |
| códigos de status | lembrados view por view | constantes com nome, e o certo para cada falha |
| quem pode fazer o quê | uma conferência em cada view | **classes de permissão**, declaradas uma vez |
| listas longas | fatiar à mão | **paginação**, declarada uma vez |
| as rotas de um recurso | cinco padrões por modelo | um **roteador** |

O **Django REST Framework**, DRF, é a biblioteca que faz isso. Ele não faz parte do Django, mas é com
ele que a maioria das APIs Django é escrita; o curso `apis`, mais adiante nesta trilha, aprofunda como
uma API deve ser desenhada. Acrescente-o ao projeto:

```
ana@vm:~/agenda$ uv add djangorestframework
Resolved 8 packages in 183ms
Prepared 1 package in 54ms
Installed 1 package in 6ms
 + djangorestframework==3.18.3
```

## Duas configurações

Ele é um app Django, então entra no `INSTALLED_APPS`, antes do `events`:

```
ana@vm:~/agenda$ sed -n '/^INSTALLED_APPS/,/^]/p' config/settings.py
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'events',
]
```

E o DRF lê as configurações dele de um dicionário, no fim do `config/settings.py`:

```
ana@vm:~/agenda$ sed -n '/^REST_FRAMEWORK/,/^}/p' config/settings.py
REST_FRAMEWORK = {
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticatedOrReadOnly",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 2,
}
```

**`IsAuthenticatedOrReadOnly`** é a regra padrão de toda view da API: qualquer um pode ler, e só um
usuário autenticado pode escrever. **`PageNumberPagination`** com `PAGE_SIZE` de 2 divide toda lista em
páginas de dois, um número escolhido para que três eventos mostrem o que a paginação faz; uma API de
verdade usa 20 ou 50. Os dois são padrões, e uma view pode dizer outra coisa, o que o endpoint de
inscrição faz.
