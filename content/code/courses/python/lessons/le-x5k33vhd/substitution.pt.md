---
title: O `sub`, e uma substituição que é uma função
version: 2
---

```python
re.sub(r"\s+", " ", text)                    # collapse runs of whitespace
re.sub(r"(\d{4})-(\d{2})-(\d{2})", r"\3/\2/\1", text)     # reorder a date
```

O `sub` devolve uma string NOVA — nada é alterado no lugar, como em toda operação de string do
Python.

## Referências de volta na substituição

`\1`, `\2` e assim por diante são os grupos; `\g<year>` é um com nome. A substituição é uma string
crua também, pela mesma razão que o padrão é.

```python
re.sub(r"(?P<user>\w+)@example\.tld", r"\g<user>@example.com", text)
```

**`\g<1>` é a forma a usar quando um dígito vem em seguida**: `\1 0` e `\g<1>0` diferem, e o
primeiro é um grupo chamado 10.

## Uma função como substituição

```python
def redact(m):
    return m.group(0)[:2] + "…"

re.sub(r"\b\w+@\S+\b", redact, text)
```

Quando a substituição é uma função ela é chamada uma vez por coincidência, com o `Match`, e o que
ela devolver é inserido. É ali que o `sub` deixa de ser buscar-e-trocar e vira um programa: dá
para consultar o valor, convertê-lo, contá-lo, ou decidir deixá-lo em paz devolvendo `m.group(0)`.

## `count`, e `subn`

```python
re.sub(pattern, repl, text, count=1)      # only the first
new, n = re.subn(pattern, repl, text)     # and how many were replaced
```

O `subn` dá a contagem, que é como se descobre que uma substituição que você esperava não
aconteceu.

## O caso para tomar cuidado

```python
re.sub(r".*", "x", "abc")        # 'xx'
```

O `.*` casa `abc` e depois casa a string vazia no fim, então a substituição acontece duas vezes.
Padrões que podem casar nada se comportam de forma estranha no `sub`, e o conserto é um `+` ou uma
forma que exija ao menos um caractere.
