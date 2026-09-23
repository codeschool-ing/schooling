---
title: O `uv`, e os quatro comandos que são quase tudo
version: 2
---

```sh
uv init                      # write pyproject.toml
uv add "requests>=2.31"      # add a dependency, resolve, install, lock
uv run main.py               # run, in the project's environment
uv sync                      # make the environment match the lock
```

**Ele faz ambientes, instalações, resolução, trava e execução.** Escrito em Rust, e rápido o
bastante para a velocidade mudar como se trabalha: o `uv add` abaixo resolveu seis pacotes em 184
milissegundos e instalou cinco em cinco.

## `uv add`

```sh
$ uv add "requests>=2.31"
Using CPython 3.11.15 interpreter at: /usr/local/bin/python3
Creating virtual environment at: .venv
Resolved 6 packages in 184ms
Installed 5 packages in 5ms
 + certifi==2026.7.22
 + charset-normalizer==3.5.1
 + idna==3.20
 + requests==2.34.2
 + urllib3==2.8.0
```

Um comando fez cinco coisas: achou um interpretador, criou o `.venv` **dentro do diretório do
projeto**, resolveu, instalou, e escreveu a linha no `pyproject.toml`. Não havia ambiente para
ativar antes — ele fez um.

```sh
uv add --dev pytest          # into [dependency-groups]
uv remove requests           # out of the file, out of the environment, out of the lock
```

## `uv run`

```sh
$ rm -rf .venv
$ uv run main.py
Creating virtual environment at: .venv
Installed 10 packages in 9ms
requests 2.34.2
```

**O `uv run` confere o ambiente contra a trava antes de rodar qualquer coisa.** Apagar o `.venv`
inteiro e rodar o script reconstruiu e rodou, num comando. Nada foi ativado, e nada poderia estar
rodando contra um ambiente velho.

É esse o argumento para usá-lo em vez de ativar: `uv run pytest`, `uv run ruff check .`,
`uv run python -m qualquercoisa`. Cada um está garantidamente rodando contra o arquivo.

## `uv sync`, que não é `install`

```sh
$ uv sync --no-dev
Resolved 12 packages in 3ms
Uninstalled 5 packages in 4ms
 - iniconfig==2.3.0
 - packaging==26.3
 - pluggy==1.6.0
 - pygments==2.21.0
 - pytest==9.1.1
```

Ele **removeu** cinco pacotes, porque o conjunto pedido não os contém. O `pip install` não tem
verbo desses: ele acrescenta, e um ambiente acumula.

## As flags que pertencem à CI

```sh
uv lock --check     # fail if the lock does not match pyproject.toml
uv sync --frozen    # install from the lock without re-resolving
```

```sh
$ uv lock --check
The lockfile at `uv.lock` needs to be updated, but `--locked` was provided.
```

A primeira pega o pull request que mudou uma dependência e não retravou. A segunda é o que uma
implantação deve rodar: ela instala exatamente o que foi testado e não pode silenciosamente
resolver para outra coisa.

## `uv tree`

```sh
rates v0.1.0
├── requests v2.34.2
│   ├── certifi v2026.7.22
│   ├── charset-normalizer v3.5.1
│   ├── idna v3.20
│   └── urllib3 v2.8.0
└── pytest v9.1.1 (group: dev)
```

A resposta para "o que é isto e por que está aqui", que o `pip list` não consegue dar.
