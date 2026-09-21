---
title: Layout, `build-system`, e instalar com `-e`
version: 1
---

```sh
rates/
  pyproject.toml
  src/
    rates/
      __init__.py
      cli.py
  tests/
    test_cli.py
```

**O layout `src/`.** O pacote importável fica um diretório abaixo, o que faz a raiz do projeto não
estar no `sys.path` e um teste que importa `rates` receber a cópia *instalada* em vez do diretório
ao lado. É esse o argumento inteiro a favor dele: os testes exercitam o que um usuário recebe.

## `build-system`

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

O backend que transforma o seu fonte numa wheel. `hatchling`, `setuptools`, `poetry-core` e
`flit` todos fazem isso, e para um pacote direto a escolha mal importa — o `hatchling` é a
recomendação padrão atual e não precisa de configuração para o layout acima.

Esta tabela é o que torna o diretório *construível*. Sem ela, o `pip install .` não sabe o que
fazer.

## Construir

```sh
$ uv build
Successfully built dist/rates-0.1.0.tar.gz
Successfully built dist/rates-0.1.0-py3-none-any.whl
```

Dois artefatos. O **sdist** (`.tar.gz`) é o fonte, e a **wheel** (`.whl`) é a instalável — um
arquivo zip com um layout fixo:

```sh
rates/__init__.py
rates/cli.py
rates-0.1.0.dist-info/METADATA
rates-0.1.0.dist-info/WHEEL
rates-0.1.0.dist-info/entry_points.txt
rates-0.1.0.dist-info/RECORD
```

`py3-none-any` no nome do arquivo quer dizer: qualquer Python 3, nenhuma ABI, qualquer plataforma.
Um pacote com partes compiladas tem um nome como `cp311-cp311-manylinux_2_17_x86_64`, e há um por
plataforma.

## A instalação editável

```sh
pip install -e .
```

```sh
$ python -c "import rates; print(rates.__file__)"
/tmp/rates/src/rates/__init__.py

$ rates
rates 0.1.0
```

O `import rates` resolve para a sua árvore de fontes e não para uma cópia em `site-packages`,
então uma edição vale na próxima execução sem reinstalar — medido: mudar uma linha em `cli.py` e
rodar `rates` de novo imprimiu o texto novo.

O `uv` faz isso por padrão: um projeto gerenciado com `uv` que tenha um `[build-system]` é
instalado como editável no próprio ambiente pelo `uv sync`.

## `[project.scripts]`

```toml
[project.scripts]
rates = "rates.cli:main"
```

O comando `rates` acima veio daquela linha e da instalação editável. O valor é `módulo:função`, e
o arquivo que isso gera é o que põe o nome no seu `PATH`.
