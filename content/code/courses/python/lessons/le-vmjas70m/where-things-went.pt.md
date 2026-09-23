---
title: `site-packages`, `sys.path`, e o import que achou a cópia errada
version: 2
---

```sh
$ python -c "import sys; [print(repr(p)) for p in sys.path]"
''
'/usr/lib/python311.zip'
'/usr/lib/python3.11'
'/usr/lib/python3.11/lib-dynload'
'/tmp/project/.venv/lib/python3.11/site-packages'
```

**O `import` percorre essa lista em ordem e para na primeira que casa.** Tudo o que confunde em
imports é consequência desses dois fatos.

Dentro de um ambiente a lista é curta: o diretório atual, a biblioteca padrão, e um
`site-packages`. As bibliotecas da própria máquina não estão nela de jeito nenhum, que é o
isolamento.

## A string vazia, que é a primeira

```python
# json.py, sitting in your project directory
print("this is not the standard library")
```

```sh
$ python -c "import json; print(json.__file__)"
this is not the standard library
/tmp/project/json.py
```

A string vazia quer dizer **o diretório em que o script está** (ou o diretório de trabalho para
`-c` e para o REPL), e ela vem antes da biblioteca padrão. Um arquivo com o nome de um módulo o
sombreia para o seu programa inteiro — e o erro em geral aparece três imports adiante, dentro de
uma biblioteca que importou `json` e recebeu o seu.

`random.py`, `email.py`, `types.py`, `test.py`, `token.py` e `queue.py` são os que as pessoas
escrevem sem querer. Se um import começar a se comportar de modo impossível, procure um arquivo
com aquele nome ao seu lado antes de qualquer outra coisa.

## `pip show -f`

```sh
$ python -m pip show -f requests
Location: /tmp/project/.venv/lib/python3.11/site-packages
Files:
  requests/__init__.py
  requests/api.py
  ...
```

`Location` é a resposta para "qual cópia está sendo importada", e compará-la com
`requests.__file__` encerra uma discussão numa linha:

```python
import requests
print(requests.__version__, requests.__file__)
```

**Essas duas linhas são a primeira coisa a rodar** quando uma biblioteca se comporta como uma
versão diferente da que você instalou. Na maior parte das vezes o arquivo está num lugar que você
não esperava — uma instalação de usuário sob `~/.local`, ou a cópia do próprio sistema, porque o
ambiente não estava ativo quando o comando rodou.

## `__pycache__`

Bytecode compilado, escrito ao lado de cada módulo na primeira vez que ele é importado e
reaproveitado enquanto o fonte não mudar. É invisível no dia a dia, pertence ao `.gitignore`, e
vale apagar à mão exatamente uma vez: quando um `.py` que você apagou continua importável, porque
o `.pyc` dele ainda está lá.
