---
title: Mantendo segredos fora do git
version: 1
---

Um segredo num repositório é um segredo em todo clone, todo fork e todo backup dele, e apagá-lo depois
o deixa no histórico. Então a regra é mecânica: **o arquivo que guarda segredos nunca é adicionado**. O
agenda ainda não é um repositório git. Antes de fazê-lo um, tire os arquivos descartáveis que as aulas
anteriores deixaram:

```
ana@vm:~/agenda$ rm -f before-logout.txt drf-token.txt jar.txt doors.py owners.py passwords.py seed.py
ana@vm:~/agenda$ git init -q
```

Depois um `.gitignore`, que nomeia o que o git não deve oferecer para adicionar:

```sh
# .gitignore
.venv/
__pycache__/
.pytest_cache/
celerybeat-schedule*
.env
```

E um `.env.example`, que **é** commitado: os nomes de que o projeto precisa, sem valores, para que a
próxima pessoa saiba o que preencher:

```ini
# .env.example
# Copy to .env and fill in the blanks. .env itself is never committed.
DJANGO_SECRET_KEY=
DJANGO_DEBUG=1
DJANGO_ALLOWED_HOSTS=
DATABASE_USER=agenda_app
DATABASE_PASSWORD=
DATABASE_HOST=localhost
CELERY_BROKER_URL=redis://127.0.0.1:6379/0
```

```
ana@vm:~/agenda$ git status --short
?? .env.example
?? .gitignore
?? config/
?? events/
?? manage.py
?? pyproject.toml
?? templates/
?? tests/
?? uv.lock
ana@vm:~/agenda$ git check-ignore -v .env
.gitignore:6:.env	.env
```

O `.env` não está na lista, e o `check-ignore` diz que linha o excluiu. Faça o mesmo em `~/agenda-api`,
com os dois nomes dele.

## Quando um vaza mesmo assim

Um segredo que chegou a um repositório, a um chat ou a uma captura de tela é **trocado**, não apagado:
gere um novo, implante-o, e deixe o antigo parar de funcionar, como a chave do JWT acabou de fazer. Para
a `SECRET_KEY` do Django, trocar encerra todas as sessões e invalida os links de redefinição de senha;
a configuração `SECRET_KEY_FALLBACKS` do Django mantém a chave antiga válida para conferir, mas não para
assinar, enquanto as sessões migram. Para uma senha de banco, é `ALTER ROLE ... PASSWORD` e um
reinício.

Um ambiente também não é um cofre. O ambiente de um processo pode ser lido pelo mesmo usuário, aparece
em alguns relatórios de erro, e é herdado por todo processo filho. A aula 16 deixa o arquivo legível só
pelo serviço; uma equipe com muitos servidores usa um gerenciador de segredos, que entrega valores do
mesmo jeito, pelo ambiente ou por um arquivo, e registra quem os leu.
