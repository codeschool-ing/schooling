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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"Quatro arquivos dividiam o trabalho entre si: um construía o pacote, um o instalava, um guardava as configurações das ferramentas que não sabiam ler o primeiro, e um listava os arquivos que nenhum dos outros mencionava. Uma tabela num arquivo só substitui os quatro, e quatro ferramentas diferentes leem as mesmas chaves dela.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">o que ele substitui</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">setup.py — construía o pacote</text> <rect x=\"20\" y=\"78\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">requirements.txt — instalava</text> <rect x=\"20\" y=\"120\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">setup.cfg — configurações de quem não sabia ler setup.py</text> <rect x=\"20\" y=\"162\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">MANIFEST.in — os arquivos que nenhum outro mencionava</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">[project], no pyproject.toml</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"76\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">pyproject.toml</text> <rect x=\"380\" y=\"142\" width=\"74\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"417\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">uv</text> <path d=\"M417 136 L417 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"462\" y=\"142\" width=\"74\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"499\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">poetry</text> <path d=\"M499 136 L499 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"544\" y=\"142\" width=\"74\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"581\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pip</text> <path d=\"M581 136 L581 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"626\" y=\"142\" width=\"74\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"663\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hatch</text> <path d=\"M663 136 L663 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"540\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">os quatro leem as mesmas chaves</text> </svg>", "caption": "A tabela é definida por uma especificação e não pelo programa que você por acaso roda, e é por isso que um projeto muda de ferramenta sem uma edição."}
```

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
