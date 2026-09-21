---
title: O conjunto padrão, e a família que ele deixa de fora
version: 1
---

```sh
padrão: E4, E7, E9, F
```

**O padrão é pequeno de propósito** — é o que quase qualquer base consegue passar na primeira
rodada. É imports, nomes indefinidos e um punhado de regras `E` que não são ambíguas.

O que ele deixa de fora é o assunto desta seção:

```python
def load_rates(path, cache = {}):
    if path in cache:
        return cache[path]
    ...
```

```sh
(regras padrão)  Found 0 errors.
(com B)          B006 Do not use mutable data structures for argument defaults
```

Um argumento padrão é avaliado **uma vez, na definição**, então aquele dicionário é compartilhado
por toda chamada que o processo fizer. Ele funciona, e é um cache que nunca esvazia e atravessa
entre chamadores.

## Ligando famílias

```toml
[tool.ruff.lint]
select = ["E", "F", "B", "SIM", "UP", "I", "A"]
ignore = ["E501"]
```

`select` **substitui** o padrão em vez de somar a ele, então listar `B` sozinho desligaria o `F`.
Escreva o conjunto inteiro que você quer.

Uma lista inicial razoável é a de cima: os padrões, mais o bugbear pelos defeitos, mais ordenação
de imports, simplificações, atualizações e embutidos sombreados. Acrescente uma família, rode
`--statistics`, conserte ou ignore, comite. Uma família por pull request.

## A exceção por arquivo

```toml
[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401"]
"tests/*" = ["S101"]
```

O `__init__.py` de um pacote importa nomes para que outros módulos possam importá-los de lá, e
cada um deles é "sem uso" até onde o `F401` enxerga. Isso é propriedade do arquivo e não engano
dentro dele, que é exatamente para o que esta tabela serve.

`S101` é "não use `assert`", que está certo em código de aplicação e errado num arquivo de teste.

**Uma exceção por arquivo pertence à configuração; um `# noqa` pertence a uma linha.** A
configuração é onde vai uma regra sobre um TIPO de arquivo, e ela é revisada uma vez em vez de
aparecer em quarenta linhas.

## `# noqa`, com precisão

```python
import os      # noqa: F401     silencia o F401 aqui
import sys     # noqa           silencia TUDO aqui
import json    # noqa: E501     não silencia nada: o achado é F401
```

Nomeie o código. Um `# noqa` pelado também silencia a regra que passar a valer para aquela linha
no ano que vem.

```toml
[tool.ruff.lint]
extend-select = ["RUF100"]
```

`RUF100` relata `Unused noqa directive (unused: F401)` — uma supressão cujo motivo se foi. Sem
ele, os comentários se acumulam e ninguém consegue dizer quais ainda importam.
