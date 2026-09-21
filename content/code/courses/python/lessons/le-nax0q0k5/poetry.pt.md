---
title: O Poetry, o mesmo trabalho com outras palavras
version: 1
---

```sh
poetry init
poetry add "requests>=2.31"
poetry add --group dev pytest
poetry install
poetry run python main.py
```

Mais antigo, largamente implantado, e fazendo as mesmas coisas. Se você usou o `uv`, o mapeamento
é quase um para um — e desde a versão 2 o **arquivo** que ele escreve é o mesmo, o que não era
verdade antes.

## O que ele escreve

```toml
[project]
name = "rates"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "requests (>=2.31)"
]

[dependency-groups]
dev = [
    "pytest (>=9.1.1,<10.0.0)"
]

[build-system]
requires = ["poetry-core>=2.0.0,<3.0.0"]
build-backend = "poetry.core.masonry.api"
```

Três diferenças em relação ao que o `uv` produziu para os mesmos dois comandos: os
especificadores vêm entre **parênteses**, o Poetry acrescentou um **limite superior** ao `pytest`
que o `uv` não acrescentou, e ele escreveu uma tabela `[build-system]` porque supõe que o projeto
é um pacote.

Essa terceira é a diferença em que você de fato vai esbarrar.

## O ambiente não fica no projeto

```sh
$ poetry env info -p
/root/.cache/pypoetry/virtualenvs/rates-mFpQSSuL-py3.11
```

O Poetry guarda os ambientes num cache central, nomeados a partir do caminho do projeto e de um
hash dele. O `uv` põe o `.venv` ao lado do seu código.

Nenhum dos dois está errado e as consequências diferem: um editor acha o `.venv` sem ser avisado,
e um cache central sobrevive a um `rm -rf` do diretório do projeto. Se você prefere o primeiro:

```sh
poetry config virtualenvs.in-project true
```

## O erro que todo mundo encontra no primeiro dia

```sh
$ poetry install
Error: The current project could not be installed: No file/folder found for package rates
If you do not want to install the current project use --no-root.
If you want to use Poetry only for dependency management but not for packaging,
you can disable package mode by setting package-mode = false in your pyproject.toml.
```

**O Poetry supõe que o seu projeto é um pacote a ser construído.** Para uma aplicação — um
serviço web, um script, um pipeline de dados — ele não é, e não existe um diretório `rates/` para
ele instalar.

O texto do erro diz as duas respostas, e a segunda é a de anotar:

```toml
[tool.poetry]
package-mode = false
```

Depois disso o `poetry install` lê a trava e instala as dependências, que é o que você queria.

## Os comandos, contra os do `uv`

| | Poetry | `uv` |
| --- | --- | --- |
| acrescentar | `poetry add x` | `uv add x` |
| acrescentar, desenvolvimento | `poetry add --group dev x` | `uv add --dev x` |
| remover | `poetry remove x` | `uv remove x` |
| instalar da trava | `poetry install` | `uv sync` |
| só produção | `poetry install --only main` | `uv sync --no-dev` |
| rodar | `poetry run python x.py` | `uv run x.py` |
| mostrar a árvore | `poetry show --tree` | `uv tree` |

Os verbos diferem; o arquivo não.
