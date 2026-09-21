---
title: Três arranjos, e como saber em qual você está
version: 1
---

**Olhe os arquivos antes de digitar qualquer coisa.** Um repositório diz o que espera num `ls`, e
rodar a ferramenta errada escreve um segundo arquivo de trava que alguém tem de apagar.

| o que está lá | o que rodar |
| --- | --- |
| `uv.lock` | `uv sync`, e então `uv run …` |
| `poetry.lock` | `poetry install`, e então `poetry run …` |
| `requirements.txt` e mais nada | `python -m venv .venv`, e então `pip install -r` |

Um `pyproject.toml` sozinho não resolve nada: os três arranjos têm um hoje, e um projeto que só o
usa para configurar o `ruff` também tem.

## Lendo com mais precisão

```toml
[tool.poetry]              # Poetry, e possivelmente um arquivo do formato antigo
[tool.uv]                  # ajustes específicos do uv
[build-system]
requires = ["poetry-core"] # construído pelo Poetry
requires = ["hatchling"]   # construído pelo hatch, gerenciado por qualquer coisa
```

`[build-system]` nomeia o **backend que constrói a wheel**, e é independente da ferramenta que
você usa no dia a dia: um projeto pode ser gerenciado com `uv` e construído com `hatchling`, ou
gerenciado com Poetry e construído com `poetry-core`.

## O arquivo Poetry do formato antigo, que você ainda vai encontrar

```toml
[tool.poetry]
name = "rates"
version = "0.1.0"

[tool.poetry.dependencies]
python = "^3.11"
requests = "^2.31"
```

O Poetry antes da versão 2 escrevia tabelas próprias em vez de `[project]`, com sintaxe própria de
especificador: `^2.31` quer dizer `>=2.31,<3` e `~2.31` quer dizer `>=2.31,<2.32`. Ainda funciona,
o `uv` não consegue ler, e converter é mecânico.

**O `^` é do Poetry, não do Python.** Ele não aparece numa tabela `[project]` e o `pip` não o
entende.

## No repositório de outra pessoa

1. `ls` procurando um arquivo de trava, e use a ferramenta que o escreveu.
2. Não acrescente um segundo. Dois arquivos de trava num repositório são duas respostas para uma
   pergunta, e ninguém descobre qual está valendo até uma implantação diferir de um laptop.
3. Se não houver trava nenhuma e só um `requirements.txt`, isso é a aula 18 e está tudo bem.
   Propor uma migração é uma conversa, não um commit.

## E se a escolha for sua

`uv`, hoje. Ele é mais rápido por uma ordem de grandeza, gerencia interpretadores além de pacotes,
e o arquivo de trava dele tem um formato de padrão. O Poetry não é um erro e um projeto que já
está nele não tem razão para se mudar.

Essa recomendação tem prazo de validade, que é o assunto da última leitura desta aula.
