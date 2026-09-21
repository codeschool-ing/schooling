---
title: Cinco que você já usou
version: 1
---

Cada um deles é uma função que recebe uma função.

## `@property`

`area = property(area)`, dentro de um corpo de classe. O objeto `property` implementa o protocolo
que faz o acesso a atributo chamar a sua função — a aula 6 teve o comportamento, e isto é o que ele
é.

## `@staticmethod` e `@classmethod`

`f = staticmethod(f)` e `f = classmethod(f)`. Cada um envolve a função num objeto que decide o que,
se é que alguma coisa, é passado como primeiro argumento.

## `@functools.cache`

```python
@functools.cache
def fib(n):
    return n if n < 2 else fib(n - 1) + fib(n - 2)
```

Um wrapper segurando um dicionário de argumentos para resultados. O `fib(100)` vai de impossível a
instantâneo, e o decorador são vinte linhas que você não escreveu.

**Os argumentos precisam ser hasheáveis**, porque eles são a chave do dicionário — então um
argumento lista levanta `TypeError`, e a mensagem é sobre o cache e não sobre a sua função.

O `@functools.lru_cache(maxsize=128)` é a versão limitada, e ela recebe um argumento, o que a torna
um decorador de três camadas como o da seção anterior.

## `@pytest.fixture` e companhia

O framework de testes da aula 16 usa decoradores para registrar coisas: esta função fornece uma
fixture, esta é um teste, rode esta três vezes com estes argumentos. **O trabalho do decorador ali
é o registro** — ele põe a função numa lista que o framework lê depois, que é a nota do "aplicado
na definição" de antes fazendo trabalho de verdade.

## E o `@dataclass`

O da aula 6, e o diferente da lista: ele recebe uma CLASSE, acrescenta métodos a ela, e a devolve.
A mesma regra — uma função que recebe uma coisa e devolve uma coisa — com uma classe no meio.
