---
title: Ordenada, e pode mudar
version: 2
---

```python
langs = ["python", "go", "sql"]
```

Colchetes, separados por vírgula, e qualquer coisa pode ir dentro — inclusive outras listas.

## Alcançando

```python
>>> langs[0]
'python'
>>> langs[-1]
'sql'
>>> len(langs)
3
```

A partir do zero. **`langs[3]` levanta `IndexError`**, e é essa a mensagem a esperar de um erro de
um a mais.

## Mudando

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "langs[1] = \"rust\"\n",
      "note": "Atribuir a uma posição substitui o item que está ali, no lugar."
    },
    {
      "code": "langs.append(\"c\")\n",
      "note": "O `append` põe um item no fim."
    },
    {
      "code": "langs.extend([\"zig\", \"r\"])\n",
      "note": "O `extend` põe vários no fim."
    },
    {
      "code": "langs.insert(0, \"bash\")",
      "note": "O `insert` põe um numa posição, e tudo o que vem depois dela se desloca."
    }
  ]
}
```

**O `append` recebe um item, o `extend` recebe um iterável.** `langs.append(["a", "b"])` põe uma
*lista* dentro da lista, o que é legal e quase nunca é o que se queria.

## Tirando coisas

```python
>>> langs.pop()        # last, and returns it
'r'
>>> langs.pop(0)       # by position
'bash'
>>> langs.remove("go") # by value, first match, raises if absent
```

`del langs[2]` também funciona e não devolve nada.

## Ordenando

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "langs.sort()\n",
      "note": "O `sort` trabalha no lugar e devolve `None`."
    },
    {
      "code": "best = sorted(langs)\n",
      "note": "O `sorted` faz uma lista nova e deixa a original em paz."
    },
    {
      "code": "langs.sort(reverse=True)\n"
    },
    {
      "code": "langs.sort(key=len)",
      "note": "O `key` ordena por um valor calculado."
    }
  ]
}
```

**O `sort` devolve `None`**, que é a armadilha `names = names.sort()` da aula 2. Quando você quer um
valor de volta, `sorted`.

## Perguntando

```python
>>> "go" in langs
True
>>> langs.index("sql")
2
>>> langs.count("go")
1
```

**O `in` numa lista a percorre**, comparando um por um. Tudo bem para vinte itens, e é a coisa em que
pensar quando isso está dentro de um laço sobre cem mil — a seção `choosing` tem a tabela e a aula 20
tem a medida.
