---
title: Funções que recebem a instância
version: 2
---

```python
class Student:
    def __init__(self, name):
        self.name = name
        self.grades = []

    def add_grade(self, score):
        self.grades.append(score)

    def average(self):
        if not self.grades:
            return 0
        return sum(self.grades) / len(self.grades)
```

Um método é uma função definida no corpo da classe cujo primeiro parâmetro é a instância. Fora
isso é uma função comum: padrões, `*args`, retorno antecipado, tudo da aula 5.

## Chamar um de dentro de outro

```python
    def report(self):
        return f"{self.name}: {self.average():.1f}"
```

`self.average()` — pela instância, nunca pelo nome puro. Escrever `average()` dentro de `report`
procura uma função de nível de módulo e levanta um `NameError`, que são as regras de escopo da
aula 5 respondendo exatamente como devem.

## Devolver um objeto novo em vez de alterar este

```python
    def with_city(self, city):
        return Student(self.name, city)      # a new student
```

Duas formas, e a escolha vale ser deliberada: um método que ALTERA a instância devolve `None` por
convenção, e um método que devolve um objeto NOVO deixa o original em paz. O `list.sort` e o
`sorted` são esse par na biblioteca padrão, e a aula 3 os encontrou.

**Misturar os dois numa classe só é o que confunde as pessoas** — uma classe em que alguns métodos
alteram e outros devolvem cópias precisa que os nomes digam qual é qual.

## Um método é uma função na classe

```python
Student.average            # a plain function
ada.average                # a bound method: the function, with ada attached
```

`ada.average` é a função com o `self` já preenchido. É por isso que ele dá para passar adiante como
qualquer outro valor — `sorted(students, key=Student.average)` funciona, e `map(ada.acrescentar_nota,
notas)` também.
