---
title: Cinco funções, e o que cada uma devolve
version: 2
---

| função | acha | devolve |
| --- | --- | --- |
| `search` | a primeira coincidência, em qualquer lugar | um `Match`, ou `None` |
| `match` | uma coincidência no COMEÇO | um `Match`, ou `None` |
| `fullmatch` | uma coincidência cobrindo a string INTEIRA | um `Match`, ou `None` |
| `findall` | todas as coincidências | uma lista de strings ou tuplas |
| `finditer` | todas as coincidências | um iterador de objetos `Match` |

## O `None` que não é conferido

```python
m = re.search(pattern, line)
value = m.group(1)          # AttributeError when it did not match
```

Três das cinco devolvem `None`, e `None.group` é o `'NoneType' object has no attribute` da aula 8
na fantasia mais comum dele. **Confira toda vez**, e já que está ali, conte as linhas que não
casaram — um analisador que descarta um décimo da entrada em silêncio é pior que um que para.

## O `findall` muda de forma

```python
re.findall(r"\d+", text)                 # ['2026', '09']
re.findall(r"(\d+)-(\d+)", text)         # [('2026', '09')]
```

**Sem grupo: uma lista das coincidências inteiras. Um grupo: uma lista daquele grupo. Dois ou
mais: uma lista de tuplas.** São três tipos de retorno de uma função só, decididos pelo padrão —
e é por isso que o `finditer` é o que se usa quando o padrão não é trivial.

## `finditer`, que guarda o `Match`

```python
for m in re.finditer(r"(?P<key>\w+)=(?P<value>\S+)", text):
    print(m["key"], m["value"], m.start())
```

Grupos com nome, posições, e nada construído em memória. É também a única das cinco que escala
para um arquivo grande.

## `split` e o grupo que captura

```python
re.split(r"\s*,\s*", "a , b,c")          # ['a', 'b', 'c']
re.split(r"(\d)", "a1b")                 # ['a', '1', 'b'] — the group is KEPT
```

Um grupo que captura no padrão põe os separadores no resultado, que de vez em quando é exatamente
o que você quer e no resto das vezes é uma surpresa.

## As funções de módulo têm cache

`re.search(pattern, s)` compila o padrão e o guarda, então chamá-lo num laço não é o desastre que
parece. O `re.compile` continua mais claro para um padrão usado mais de uma vez, e é a próxima
seção.
