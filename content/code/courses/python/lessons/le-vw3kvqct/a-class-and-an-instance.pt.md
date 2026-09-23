---
title: O `self` é a instância, e nada mais é incomum
version: 2
---

```python
class Student:
    def __init__(self, name, city):
        self.name = name
        self.city = city

ada = Student("Ada", "Porto")
ada.name          # 'Ada'
```

O `class` cria um tipo. Chamá-lo cria uma INSTÂNCIA — `Student(...)` constrói uma e a devolve. O
`__init__` roda no objeto novo e define os atributos dele.

## O `self`

`self` é a instância, passada como primeiro argumento. É um nome de parâmetro, e não uma
palavra-chave: o Python o preenche quando você chama um método num objeto.

```python
ada.greet()          # Python calls Student.greet(ada)
Student.greet(ada)   # the same call, written out
```

**Essa frase é a orientação a objetos inteira em Python.** O `self` se chama `self` por convenção e
nada quebraria se você o chamasse de outra coisa — exceto a expectativa de quem lê, o que já é
motivo suficiente.

## Defina todo atributo no `__init__`

```python
class Student:
    def __init__(self, name):
        self.name = name
        self.grades = []        # even though it starts empty
```

Um atributo criado depois, dentro de outro método, é um atributo que quem lê não encontra olhando
o topo. **O `__init__` é onde a forma do objeto fica escrita**, e uma lista vazia atribuída ali é
mais barata que um teste `hasattr` em outro lugar.

## Não existe `new`, e não existem atributos privados

`Student("Ada", "Porto")` é a construção; sem palavra nenhuma na frente. E nada é privado: um
sublinhado na frente — `self._cache` — é uma convenção que quer dizer "isto é meu, não mexa", e o
Python não vai te impedir. **É um recado para uma pessoa, cobrado por ninguém.**

## Duas instâncias são dois objetos

```python
a = Student("Ada", "Porto")
b = Student("Ada", "Porto")
a == b            # False, until __eq__ says otherwise
```

Mesmos valores, objetos diferentes — o `==` contra o `is` da aula 4, uma camada acima. A seção
sobre métodos especiais é onde o `==` aprende o que é igualdade aqui.
