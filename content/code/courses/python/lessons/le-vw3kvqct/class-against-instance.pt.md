---
title: Uma cópia para todo mundo, e a armadilha nisso
version: 1
---

```python
class Aluno:
    escola = "codeschool"        # atributo de classe: um, compartilhado

    def __init__(self, nome):
        self.nome = nome         # atributo de instância: um por aluno
```

`Aluno.escola` existe uma vez. Toda instância o enxerga pela busca, então `ada.escola` funciona sem
`ada` ter um próprio.

## Atribuir pela instância não muda a classe

```python
ada.escola = "outra"       # cria um atributo de INSTÂNCIA que o sombreia
Aluno.escola               # continua 'codeschool'
```

A leitura vai à instância primeiro, e depois à classe. A escrita sempre cai na instância. Essa
assimetria é a fonte de quase toda a confusão aqui, e é a mesma forma das regras de escopo da
aula 5.

## O atributo de classe mutável

```python
class Aluno:
    notas = []              # UMA lista, compartilhada por todo aluno já criado

    def acrescentar_nota(self, nota):
        self.notas.append(nota)     # acrescenta à compartilhada
```

Esta é a armadilha do padrão mutável da aula 5 na outra fantasia dela. O `append` não atribui,
então ele nunca cria um atributo de instância — ele altera o da classe, e agora todo aluno tem
todas as notas. **Um atributo de classe mutável é quase sempre um defeito**; ponha-o no `__init__`.

Uma constante — uma string, um número, uma tupla — é o caso em que o atributo de classe está certo.

## `@classmethod` e `@staticmethod`

```python
class Aluno:
    @classmethod
    def de_linha(cls, linha):
        return cls(linha["nome"])      # cls é a classe

    @staticmethod
    def nota_valida(n):
        return 0 <= n <= 100
```

Um `classmethod` recebe a CLASSE como primeiro argumento, e o uso comum dele é um construtor
alternativo — `Aluno.de_linha(linha)` se lê melhor que uma função de nível de módulo que constrói
um. Usar `cls(...)` em vez de `Aluno(...)` faz uma subclasse receber o próprio tipo de volta.

Um `staticmethod` não recebe nenhum dos dois. É uma função comum que calha de morar na classe por
arrumação — e **se ela não toca a classe em nada, uma função de nível de módulo era a resposta
honesta**.
