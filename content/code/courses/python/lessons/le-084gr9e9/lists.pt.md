---
title: Ordenada, e pode mudar
version: 1
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
langs[1] = "rust"          # troca no lugar
langs.append("c")          # um item no fim
langs.extend(["zig", "r"]) # vários no fim
langs.insert(0, "bash")    # numa posição; tudo depois desloca
```

**O `append` recebe um item, o `extend` recebe um iterável.** `langs.append(["a", "b"])` põe uma
*lista* dentro da lista, o que é legal e quase nunca é o que se queria.

## Tirando coisas

```python
>>> langs.pop()        # o último, e devolve
'r'
>>> langs.pop(0)       # por posição
'bash'
>>> langs.remove("go") # por valor, primeira ocorrência, levanta erro se não houver
```

`del langs[2]` também funciona e não devolve nada.

## Ordenando

```python
langs.sort()             # no lugar, devolve None
melhores = sorted(langs) # uma lista nova, deixa a original em paz
langs.sort(reverse=True)
langs.sort(key=len)      # por um valor calculado
```

**O `sort` devolve `None`**, que é a armadilha `nomes = nomes.sort()` da aula 2. Quando você quer um
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
