---
title: Quatro funções, e os tipos de cada lado
version: 2
---

```python
import json

data = json.loads(text)          # string  → Python
data = json.load(f)              # file    → Python
text = json.dumps(data)          # Python  → string
json.dump(data, f)               # Python  → file
```

**O `s` quer dizer string.** Essa é a nomenclatura inteira, e é a coisa que as pessoas consultam
toda vez até notarem isso.

## Os tipos

| JSON | Python |
| --- | --- |
| object | `dict` |
| array | `list` |
| string | `str` |
| number | `int` ou `float` |
| `true` / `false` | `True` / `False` |
| `null` | `None` |

Não existe tupla, nem conjunto, nem data. Uma tupla gravada volta como lista, um `datetime` levanta
`TypeError: Object of type datetime is not JSON serializable` — e a resposta de sempre é
`.isoformat()` na saída e `fromisoformat` na volta, que a aula 7 tem.

## Gravar para uma pessoa ler

```python
json.dump(data, f, indent=2, ensure_ascii=False, sort_keys=True)
```

`indent=2` deixa legível e deixa um diff útil. `ensure_ascii=False` mantém `ção` como `ção` em vez
de `ção`. `sort_keys=True` faz duas gravações do mesmo dado serem idênticas, que é o que
impede um arquivo de parecer alterado quando não está.

## Ler

```python
with open(path, encoding="utf-8") as f:
    data = json.load(f)
```

O `json.load` recebe o ARQUIVO, e não o texto — passar `f.read()` para ele funciona e lê o arquivo
com o dobro do trabalho necessário.

## O que ele não vai fazer

**Vírgula sobrando, comentário e aspas simples não são JSON.** Cada um deles levanta
`json.JSONDecodeError`, que nomeia a linha e a coluna — e esse erro é subclasse de `ValueError`,
então um `except ValueError` o captura.

Um arquivo com comentários provavelmente é JSON5, YAML ou TOML. O `tomllib` está na biblioteca
padrão desde a 3.11 e é a resposta certa para configuração.
