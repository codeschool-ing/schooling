---
title: `dependencies`, grupos, e `requires-python`
version: 2
---

```toml
[project]
requires-python = ">=3.11"
dependencies = [
    "requests>=2.31",
    "pandas~=2.2.0",
]
```

Os mesmos especificadores da aula 18, numa lista. O que era uma linha por pacote no
`requirements.txt` é uma string por pacote aqui, e tudo sobre `==`, `>=` e `~=` se transfere sem
mudança.

## O grupo de desenvolvimento

```toml
[dependency-groups]
dev = [
    "pytest>=9.1.1",
    "ruff>=0.15",
]
```

`[dependency-groups]` é uma tabela padrão, e tanto o `uv` quanto o Poetry a escrevem. Coisas num
grupo **não** são dependências do pacote: são o de que se precisa para trabalhar nele. Instalar o
projeto em produção instala as `dependencies` e nenhum dos grupos.

```sh
uv sync            # dependencies + the dev group
uv sync --no-dev   # dependencies only
```

Pode haver mais de um grupo — `docs`, `lint`, `typing` — e um grupo pode incluir outro.

## Dependências opcionais, que são outra coisa

```toml
[project.optional-dependencies]
postgres = ["psycopg[binary]>=3.1"]
excel = ["openpyxl>=3.1"]
```

```sh
pip install rates[postgres]
```

Essas são para os **seus usuários**, não para você: um recurso do pacote que precisa de uma
biblioteca extra, que alguém instala nomeando-a entre colchetes. Um grupo de desenvolvimento é
invisível para quem instala o seu pacote; uma dependência opcional é parte da interface dele.

Trocar as duas é o engano comum, e ele manda o `pytest` para todo mundo que instalar a sua
biblioteca.

## `requires-python`

```toml
requires-python = ">=3.11"
```

É conferido na instalação: o `pip` recusa no 3.10 com uma mensagem que nomeia o requisito, em vez
de instalar e falhar na primeira sintaxe que ele não consegue analisar.

Ele também diz ao `mypy`, ao `ruff` e ao resolvedor sobre quais versões raciocinar — e o
resolvedor o usa para escolher versões de dependência que funcionem em toda a faixa, que é por
que um `>=3.8` largo às vezes segura uma biblioteca várias versões atrás.
