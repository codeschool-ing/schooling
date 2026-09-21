---
title: O outro, e onde os dois discordam de propósito
version: 1
---

```sh
mypy:    error: Incompatible types in assignment (expression has type "str",
                variable has type "int")  [assignment]
pyright: error: Type "Literal['no']" is not assignable to declared type "int"
                (reportAssignmentType)
```

As mesmas duas linhas de código, o mesmo veredito, duas frases. O `pyright` é o verificador da
Microsoft, é o que roda dentro do editor como Pylance, e relata `linha:coluna` em vez de uma linha
— por isso um erro cai na metade certa de uma linha longa em vez de na linha toda.

## Os modos dele

```json
{
  "include": ["app"],
  "typeCheckingMode": "strict",
  "pythonVersion": "3.12"
}
```

`pyrightconfig.json`, ou uma tabela `[tool.pyright]` no `pyproject.toml`. O modo é um entre `off`,
`basic`, `standard` e `strict`, e `standard` é o padrão. Cada regra embaixo tem nome próprio —
`reportAssignmentType`, `reportArgumentType` — e pode ser posta em `"error"`, `"warning"` ou
`"none"` individualmente.

## A discordância que importa

```python
def total(itens):
    n: int = "zero"
    return n
```

O `mypy` emite uma nota dizendo que pulou o corpo. O `pyright` relata o erro. **O pyright verifica
funções sem anotação e o mypy não**, e é por isso que a mesma base pode estar limpa sob um e
barulhenta sob o outro — e por que `check_untyped_defs` é a flag que faz os dois concordarem.

O `pyright` também estreita mais nas mensagens: `Literal[42]` onde o `mypy` diz `int`. Os dois
estão certos; um está contando mais.

## Comentários de silenciar não são intercambiáveis

```python
n: int = "a"  # pyright: ignore[reportAssignmentType]
m: int = "b"  # type: ignore
```

O `pyright` aceita os dois. O `mypy` não sabe o que `# pyright: ignore` quer dizer e continua
relatando a linha 1. **Se um projeto roda os dois, o comentário portátil é `# type: ignore[code]`**
— e `# pyright: ignore` fica para a regra que só o `pyright` tem.

## Qual rodar

No editor, o `pyright`, porque ele é rápido o bastante para responder enquanto você digita e você
provavelmente já o está rodando sem ter escolhido. Na CI, aquele que o arquivo de configuração do
projeto nomeia — e um dos dois, não os dois, a menos que alguém se disponha a manter dois conjuntos
de comentários de silenciar honestos.
