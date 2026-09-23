---
title: `python -m venv`, e o diretório que você nunca comita
version: 2
---

```sh
python3 -m venv .venv
```

```sh
.venv/
  bin/          activate  python  python3  pip  pip3
  lib/python3.11/site-packages/
  pyvenv.cfg
```

Três segundos, sem rede, sem configuração. `.venv` é o nome convencional — um ponto para ficar
escondido, e o mesmo em todo projeto para as ferramentas o acharem.

## `pyvenv.cfg`

```ini
home = /usr/local/bin
include-system-site-packages = false
version = 3.11.15
executable = /usr/bin/python3.11
```

Tudo o que um ambiente *é*. `home` e `executable` dizem qual interpretador ele toma emprestado —
**um ambiente não contém Python nenhum próprio**, só uma ligação para um — e
`include-system-site-packages = false` é a linha que faz o isolamento.

Essa última explica uma surpresa comum: um ambiente criado com `--system-site-packages` enxerga as
bibliotecas da máquina também, o que ocasionalmente é o que se quer e nunca é o padrão.

## Ativar

```sh
. .venv/bin/activate        # bash, zsh
.venv\Scripts\activate      # Windows
deactivate
```

```sh
$ which python
/tmp/project/.venv/bin/python
$ python -c "import sys; print(sys.prefix)"
/tmp/project/.venv
```

`activate` é um script de shell que edita o `PATH` e define `VIRTUAL_ENV`. Não é obrigatório:
`.venv/bin/python script.py` funciona sem nada ativado, e é isso que um cron ou uma unidade do
systemd deve usar, porque nenhum dos dois tem um shell que rodou o seu `activate`.

## O diretório nunca é comitado

```sh
# .gitignore
.venv/
```

Ele guarda extensões compiladas para um sistema operacional e um processador, caminhos absolutos
nos scripts, e uma cópia de cada biblioteca. É um **artefato de build**, reproduzido em segundos a
partir de um arquivo de texto, e comitá-lo põe centenas de megabytes num histórico que nunca mais
consegue perdê-los.

## Apagar e reconstruir

```sh
rm -rf .venv && python3 -m venv .venv && python -m pip install -r requirements.txt
```

A resposta para quase todo "na minha máquina funciona" sobre dependências. Um ambiente é
descartável de propósito; tratá-lo como precioso é como ele acumula aquilo que o deixa diferente
do de todo mundo.
