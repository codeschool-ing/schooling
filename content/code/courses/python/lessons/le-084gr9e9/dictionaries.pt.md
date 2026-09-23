---
title: Chaves para valores, e a busca que não percorre
version: 2
---

```python
person = {"name": "Ada", "city": "London"}
```

Chaves (as do teclado), `key: value`, separados por vírgula. As chaves em geral são strings; podem
ser qualquer valor **imutável**, que é por que uma tupla serve e uma lista não.

## Lendo

```python
>>> person["name"]
'Ada'
>>> person["email"]
KeyError: 'email'
>>> person.get("email")
None
>>> person.get("email", "unknown")
'unknown'
```

**O `[]` levanta erro e o `get` não.** Use `[]` quando uma chave ausente é um defeito sobre o qual
você quer ser avisado, e `get` quando é um caso que você está tratando — que, para qualquer coisa
vinda de um arquivo JSON, é a maior parte das vezes.

## Escrevendo

```python
person["email"] = "ada@example.com"   # add or replace
person.setdefault("city", "Paris")    # only if absent
del person["email"]
value = person.pop("city", None)      # remove and return, with a fallback
```

O `update` funde outro dicionário, e `a | b` faz o mesmo como um dicionário novo.

## Percorrendo

```python
for key in person:                    # keys
for key, value in person.items():     # both — and this is the one you want
for value in person.values():
```

**A ordem de inserção é garantida** desde o Python 3.7. O que entra primeiro sai primeiro, e é uma
promessa da linguagem em vez de um acaso.

## Perguntando

```python
>>> "name" in person
True
```

O `in` num dicionário confere as **chaves**. E é um passo em vez de um percurso — o Python calcula um
hash da chave e vai direto, por mais entradas que existam.

É essa a razão inteira de este contêiner estar em toda parte. Transformar uma lista de registros num
dicionário indexado por id, uma vez, converte toda busca seguinte de percurso em passo; a aula 20 é
onde isso transforma um laço O(n²) num O(n).

## Contando, o que você vai fazer o tempo todo

```python
counts = {}
for word in words:
    counts[word] = counts.get(word, 0) + 1
```

É esse o padrão. O `collections.Counter` da aula 7 faz isso numa linha, e vale escrever à mão uma vez
para que a linha única não seja mágica.
