---
title: O `pyproject.toml`, e os dois ajustes que têm de combinar
version: 1
---

```toml
[tool.black]
line-length = 88
target-version = ["py312"]

[tool.ruff]
line-length = 88
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "B", "SIM", "UP", "I", "A"]
ignore = ["E501"]
```

Um arquivo, na raiz do projeto, lido pelos dois. É o que faz o seu editor, o seu terminal e a CI
fazerem a mesma coisa — uma ferramenta configurada na linha de comando de uma máquina é um verde
num lugar e um vermelho no outro.

## `line-length` em dois lugares

As duas ferramentas fazem coisas diferentes com o mesmo número: o `black` quebra nele, o `ruff`
relata linhas mais longas que ele. **Ponha o mesmo valor nos dois**, ou o formatador produz linhas
de que o linter reclama, toda vez, em arquivos que ninguém tocou.

E aí desligue o `E501` assim mesmo. Uma vez que o formatador é dono da largura da linha, um
relatório sobre ela é um relatório sobre a decisão do formatador.

## `target-version`

```toml
target-version = "py312"
```

Para o `black` ele decide qual sintaxe pode ser usada na saída. Para o `ruff` decide o que o `UP`
sugere — com `py312`, `Optional[int]` vira `int | None` e `typing.List` vira `list`. Ponha a
versão mais antiga em que você implanta, e as ferramentas não vão escrever sintaxe que falha lá.

A grafia difere: o `black` recebe uma lista, o `ruff` recebe uma string. É o tipo de detalhe que
custa dez minutos uma vez.

## O `ruff` tem duas tabelas

`[tool.ruff]` guarda o que vale para a ferramenta inteira — `line-length`, `target-version`,
`exclude`. `[tool.ruff.lint]` guarda `select`, `ignore` e a tabela por arquivo;
`[tool.ruff.format]` guarda os ajustes do formatador. Pôr `select` na tabela de fora é um aviso de
descontinuação e não um erro, que é como isso passa despercebido.

## O que excluir

```toml
[tool.ruff]
exclude = ["migrations", "generated"]
```

Arquivos escritos por máquina. Todo o resto é seu, e um diretório excluído porque dá trabalho é um
diretório que deixa de ser verificado e nunca volta.
