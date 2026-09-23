---
title: A classe que era um nome e três campos
version: 2
---

```python
from dataclasses import dataclass

@dataclass
class Student:
    name: str
    city: str
    year: int = 1
```

Isso escreve `__init__`, `__repr__` e `__eq__`. Os três, corretamente, a partir das anotações — e
as anotações são a documentação de que a classe precisava de qualquer jeito.

```python
ada = Student("Ada", "Porto")
ada                      # Student(name='Ada', city='Porto', year=1)
ada == Student("Ada", "Porto")     # True
```

Compare com as vinte linhas que isso substitui, três das quais são as que as pessoas erram.

## O padrão mutável, de novo

```python
from dataclasses import field

@dataclass
class Student:
    name: str
    grades: list = field(default_factory=list)
```

`grades: list = []` é recusado de saída — a maquinaria da dataclass levanta erro em vez de deixar o
defeito do padrão compartilhado da aula 5 passar. O `default_factory` é chamado uma vez por
instância, que é o que você queria.

**Este é o único lugar do Python em que essa armadilha é pega por você**, e vale notar por quê: o
corpo da classe é lido uma vez, então o engano é visível para o decorador.

## `frozen=True`

```python
@dataclass(frozen=True)
class Point:
    x: int
    y: int
```

Atribuir a um campo passa a levantar erro, e a classe ganha um `__hash__` — então ela dá para ser
chave de dicionário e membro de conjunto. Para um valor que não deveria mudar depois de criado,
essa é a declaração inteira.

## As anotações não são conferidas

`name: str` é documentação em tempo de execução — nada impede `Student(3, 4)`. Um verificador de
tipos a lê e reclama, que é a aula 17. A dataclass só usa a anotação para saber que o campo
EXISTE.

## Quando não

Uma classe com comportamento de verdade, em que os campos são detalhe de implementação, não é uma
dataclass — é uma classe, e um `__init__` escrito à mão diz isso. A dataclass é para o caso em que
o dado É o ponto, que é a maior parte das vezes.
