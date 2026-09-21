---
title: `@d` é `f = d(f)`, escrito acima em vez de abaixo
version: 1
---

```python
@cronometrado
def carregar_linhas(caminho):
    ...
```

quer dizer exatamente:

```python
def carregar_linhas(caminho):
    ...
carregar_linhas = cronometrado(carregar_linhas)
```

**Essa é a coisa inteira que o símbolo `@` é.** São dois caracteres que poupam uma linha e põem a
informação no topo, onde quem lê a vê antes do corpo.

## As duas formas, lado a lado

```python
@cronometrado                    # o nome `carregar_linhas` agora se refere ao
def carregar_linhas(c): ...      # que quer que o `cronometrado` devolveu

carregar_linhas = cronometrado(carregar_linhas)    # a mesma religação, dita em voz alta
```

O nome é religado. A função original continua existindo — o wrapper a está segurando — mas nada
mais a alcança por aquele nome.

## Quando um decorador confunde você

Escreva-o da segunda forma. `@repetir(vezes=3)` vira `f = repetir(vezes=3)(f)`, e os dois pares de
parênteses deixam de ser misteriosos: o `repetir(vezes=3)` é chamado primeiro, e o que ele
devolver é chamado com `f`.

**Este é o truque mais útil desta aula**, e é por isso que a seção vem antes das mais difíceis.

## Funciona em classes e métodos também

```python
@dataclass
class Aluno: ...

class Retangulo:
    @property
    def area(self): ...
```

`@dataclass` é `Aluno = dataclass(Aluno)`; o `@property` da aula 6 é `area = property(area)` dentro
do corpo da classe. Nada de novo acontece — a mesma religação, num tipo diferente de objeto.

## E ele é aplicado na definição

O decorador roda quando o `def` roda, e não quando a função é chamada. Um decorador que imprime
algo imprime na importação, uma vez, o que de vez em quando é uma surpresa e em geral é como um
registro é preenchido.
