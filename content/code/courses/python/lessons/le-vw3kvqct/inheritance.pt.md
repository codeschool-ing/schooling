---
title: Reaproveitar uma classe, e o que o `super()` faz de fato
version: 1
---

```python
class Pessoa:
    def __init__(self, nome):
        self.nome = nome

    def saudar(self):
        return f"olá, {self.nome}"

class Aluno(Pessoa):
    def __init__(self, nome, curso):
        super().__init__(nome)      # roda o __init__ de Pessoa também
        self.curso = curso

    def saudar(self):
        return super().saudar() + f", estudando {self.curso}"
```

`class Aluno(Pessoa)` diz que um `Aluno` é uma `Pessoa`. Ele ganha todo método que `Pessoa` tem, e
sobrescrever um é simplesmente defini-lo de novo.

## O `super()`

`super().saudar()` chama a versão acima desta na cadeia. Sem ele, uma sobrescrita SUBSTITUI o
método do pai inteiro — o que às vezes é o que você quer e quase nunca é o que você quer no
`__init__`, porque aí os atributos do pai nunca são definidos.

**Chame `super().__init__(...)` primeiro, antes dos seus próprios atributos.** Aí o objeto está
completo quando qualquer outra coisa o toca.

## A ordem de resolução de métodos

```python
Aluno.__mro__     # (Aluno, Pessoa, object)
```

Uma busca percorre essa lista e pega a primeira classe que tem o nome. Tudo herda de `object`, que
é de onde vêm `__str__` e `__eq__` antes de você escrever os seus.

Com um pai isso é uma linha. Com vários é onde mora a complexidade da herança, e este curso não vai
até lá: **se a resposta precisa de um diagrama de MRO, a pergunta era composição.**

## `isinstance`, e quando perguntar

```python
isinstance(x, Pessoa)      # True para um Aluno também
type(x) is Pessoa          # False para um Aluno
```

O `isinstance` respeita a hierarquia e o `type(...) is` não. Use o `isinstance` quando precisar
perguntar — e uma cadeia de testes `isinstance` decidindo comportamento costuma ser um método que
deveria ter sido sobrescrito.

## Quando a herança está certa

Quando a subclasse É o pai em todo lugar em que o pai é usado, e só muda COMO algo é feito. Um
`Aluno` é uma `Pessoa` — todo método que recebe uma `Pessoa` funciona com um.

**Quando a subclasse precisa recusar um método do pai** — "um quadrado é um retângulo, mas mudar a
largura dele tem de mudar a altura" — a relação não era o que parecia. A seção depois da próxima é
a alternativa.
