---
title: O arquivo que substituiu quatro
version: 1
---

```toml
[project]
name = "rates"
version = "0.1.0"
description = "Currency rates"
requires-python = ">=3.11"
dependencies = ["requests>=2.31"]
```

**Um arquivo, um formato, lido por toda ferramenta.** O `setup.py` montava o pacote, o
`requirements.txt` o instalava, o `setup.cfg` guardava os ajustes das ferramentas que não sabiam
ler o `setup.py`, e o `MANIFEST.in` listava os arquivos que nenhum dos outros mencionava.

## `[project]` é um padrão, não o formato de uma ferramenta

A tabela acima é definida por uma especificação e não pelo programa que você por acaso roda. O
`uv`, o Poetry, o `pip` e o `hatch` leem as mesmas chaves, e é por isso que um projeto passa de um
para outro sem edição.

As chaves que vale conhecer:

- **`name`** e **`version`** — como ele se chama e qual lançamento é este.
- **`requires-python`** — os interpretadores em que ele afirma funcionar. O `pip` recusa instalar
  em qualquer outro, que é uma falha melhor que um erro de import no meio do caminho.
- **`dependencies`** — uma lista dos mesmos especificadores do `requirements.txt`.
- **`readme`**, **`license`**, **`authors`**, **`classifiers`** — metadados que importam quando
  ele é publicado e não antes.

## `[project.scripts]`

```toml
[project.scripts]
rates = "rates.cli:main"
```

Instalar o pacote põe um comando `rates` no `PATH` que chama `main()` em `rates.cli`. É assim que
toda ferramenta de linha de comando que você instalou com `pip` ganhou o nome dela.

## As tabelas das ferramentas

```toml
[tool.ruff.lint]
select = ["E", "F", "B"]

[tool.pytest.ini_options]
testpaths = ["tests"]

[tool.mypy]
strict = true
```

Tudo sob `[tool.<nome>]` pertence àquela ferramenta e é ignorado pelas demais. É por isso que as
aulas 15, 16 e 17 põem a configuração delas aqui: é um arquivo a ler quando você entra num
projeto, em vez de cinco arquivos ocultos na raiz.

## E o TOML, rapidamente

```toml
chave = "string"
numero = 88
flag = true
lista = ["a", "b"]

[tabela]
aninhado = "valor"

[[array-de-tabelas]]
um = 1

[[array-de-tabelas]]
dois = 2
```

É quase tudo. Os colchetes duplos são como se escreve uma lista de tabelas — que você já viu como
`[[tool.mypy.overrides]]`.
