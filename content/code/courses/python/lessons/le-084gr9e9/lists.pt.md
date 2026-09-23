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

```python
langs[1] = "rust"          # replace in place
langs.append("c")          # one item on the end
langs.extend(["zig", "r"]) # several on the end
langs.insert(0, "bash")    # at a position; everything after shifts
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

```python
langs.sort()             # in place, returns None
best = sorted(langs)     # a new list, leaves the original alone
langs.sort(reverse=True)
langs.sort(key=len)      # by a computed value
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
