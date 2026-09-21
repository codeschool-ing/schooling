---
title: Chaves para valores, e a busca que não percorre
version: 1
---

```python
pessoa = {"nome": "Ada", "cidade": "Londres"}
```

Chaves (as do teclado), `chave: valor`, separados por vírgula. As chaves em geral são strings; podem
ser qualquer valor **imutável**, que é por que uma tupla serve e uma lista não.

## Lendo

```python
>>> pessoa["nome"]
'Ada'
>>> pessoa["email"]
KeyError: 'email'
>>> pessoa.get("email")
None
>>> pessoa.get("email", "desconhecido")
'desconhecido'
```

**O `[]` levanta erro e o `get` não.** Use `[]` quando uma chave ausente é um defeito sobre o qual
você quer ser avisado, e `get` quando é um caso que você está tratando — que, para qualquer coisa
vinda de um arquivo JSON, é a maior parte das vezes.

## Escrevendo

```python
pessoa["email"] = "ada@example.com"     # acrescenta ou substitui
pessoa.setdefault("cidade", "Paris")    # só se estiver ausente
del pessoa["email"]
valor = pessoa.pop("cidade", None)      # remove e devolve, com um padrão
```

O `update` funde outro dicionário, e `a | b` faz o mesmo como um dicionário novo.

## Percorrendo

```python
for chave in pessoa:                     # chaves
for chave, valor in pessoa.items():      # os dois — e é este que você quer
for valor in pessoa.values():
```

**A ordem de inserção é garantida** desde o Python 3.7. O que entra primeiro sai primeiro, e é uma
promessa da linguagem em vez de um acaso.

## Perguntando

```python
>>> "nome" in pessoa
True
```

O `in` num dicionário confere as **chaves**. E é um passo em vez de um percurso — o Python calcula um
hash da chave e vai direto, por mais entradas que existam.

É essa a razão inteira de este contêiner estar em toda parte. Transformar uma lista de registros num
dicionário indexado por id, uma vez, converte toda busca seguinte de percurso em passo; a aula 20 é
onde isso transforma um laço O(n²) num O(n).

## Contando, o que você vai fazer o tempo todo

```python
contagens = {}
for palavra in palavras:
    contagens[palavra] = contagens.get(palavra, 0) + 1
```

É esse o padrão. O `collections.Counter` da aula 7 faz isso numa linha, e vale escrever à mão uma vez
para que a linha única não seja mágica.
