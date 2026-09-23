---
title: As duas formas que eram outra coisa
version: 2
---

A maior parte deste curso não é classes. Saber quando não recorrer a uma é a metade desta aula que
poupa mais trabalho.

## A classe com um método só

```python
class ReportGenerator:
    def __init__(self, rows):
        self.rows = rows

    def generate(self):
        return "\n".join(format_row(r) for r in self.rows)

ReportGenerator(rows).generate()
```

Duas linhas de cerimônia em volta de uma chamada de função. `generate_report(rows)` diz a mesma
coisa, recebe o mesmo argumento, e dá para testar sem construir nada.

**A pista é uma classe cujo `__init__` recebe exatamente o que o único método dela precisa**, usada
uma vez e descartada. Isso é uma função com passos a mais.

## A classe sem estado

```python
class MathUtils:
    @staticmethod
    def mean(xs): ...
    @staticmethod
    def median(xs): ...
```

Um espaço de nomes fingindo ser um tipo. Em Python o espaço de nomes já existe e é o módulo: ponha
as funções em `estatistica.py` e chame `stats.mean(xs)`. **Nada aqui é instanciado, que é a
denúncia.**

## A classe que era uma dataclass

Vinte linhas de `__init__` atribuindo seis parâmetros a seis atributos de mesmo nome, e nenhum
método. Isso é `@dataclass` e seis anotações, e as anotações dizem mais que as atribuições diziam.

## A classe que era um dicionário

Uma classe construída uma vez, de um arquivo, guardando chaves arbitrárias que ninguém enumerou. Se
os campos não são conhecidos na hora em que você escreve o código, a forma é um dicionário e a aula
3 já cobre isso.

## Então quando É uma classe?

Quando há **estado** e **operações sobre esse estado**, e os dois andam juntos: uma conexão que você
abre, usa e fecha; um analisador guardando uma posição; uma conta que dá para debitar. O teste é se
algum método ficaria pior como função recebendo o dado por parâmetro.

Se todos eles ficariam exatamente iguais — receber o dado, devolver uma resposta — você tem funções,
e elas estavam bem.
