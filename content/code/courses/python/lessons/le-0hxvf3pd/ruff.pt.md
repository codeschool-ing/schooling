---
title: O `ruff`, as famílias de regras, e o que o `--fix` pode mudar
version: 1
---

```sh
ruff check app/
```

```text
F401 [*] `os` imported but unused
B006 Do not use mutable data structures for argument defaults
E722 Do not use bare `except`
A002 Function argument `filter` is shadowing a Python builtin
Found 4 errors.
[*] 3 fixable with the `--fix` option (1 hidden fix can be enabled with the `--unsafe-fixes` option).
```

**Uma ferramenta onde havia seis.** `flake8`, `isort`, `pyupgrade`, `pydocstyle`, `autoflake` e a
maior parte do `pylint` estão todos dentro dele, reimplementados em vez de embrulhados, que é por
que ele passa por um repositório grande em menos de um segundo.

## As famílias

Cada regra tem um prefixo de letra nomeando de onde ela veio:

- **`F`** — pyflakes: imports sem uso, nomes indefinidos, variáveis sem uso. Quase todos reais.
- **`E`** e **`W`** — pycodestyle: espaço em branco e disposição. Hoje em geral trabalho do
  formatador.
- **`B`** — flake8-bugbear: **a família com os defeitos dentro.** Padrões mutáveis, uma variável de
  laço capturada por um fechamento, um `assert` sobre uma tupla.
- **`I`** — isort: ordenação de imports, que o `--fix` resolve.
- **`UP`** — pyupgrade: sintaxe mais velha que o seu `target-version`.
- **`SIM`** — simplificações: `if a == b: return True else: return False`.
- **`A`** — embutidos sombreados.

`ruff linter` lista todas elas, e há dezenas mais — `S` de segurança, `ANN` de anotações que
faltam, `PT` de estilo de pytest.

## `[*]` e o que o `--fix` pode fazer

```sh
ruff check --fix app/
```

```text
Found 7 errors (4 fixed, 3 remaining).
```

`[*]` marca uma regra com um conserto que o `ruff` considera **seguro**: um que não muda o que o
programa faz. Remover um import sem uso é seguro. Ordenar imports é seguro.

```text
1 hidden fix can be enabled with the `--unsafe-fixes` option
```

Um conserto inseguro é um que poderia mudar comportamento. `result.ok == True` virar `result.ok` é
o exemplo aqui, e é inseguro porque os dois diferem para qualquer coisa cujo `__eq__` seja
incomum — `1 == True` é verdade e `1` não é `True`. Leia o diff de um conserto inseguro antes de
aceitá-lo.

## Mais duas flags que vale conhecer

```sh
ruff check --statistics app/    # uma contagem por regra, em vez de toda ocorrência
ruff check --diff app/          # o que o --fix mudaria, sem mudar
```

`--statistics` é o que rodar primeiro numa base que nunca passou por um linter, porque a saída
completa tem milhares de linhas e o resumo tem vinte.
