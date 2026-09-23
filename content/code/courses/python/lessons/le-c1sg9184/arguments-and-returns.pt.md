---
title: `*args, **kwargs`, e o `return` que todo mundo esquece
version: 2
---

```python
def timed(func):
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        print(f"{func.__name__} took {time.perf_counter() - start:.3f}s")
        return result
    return wrapper
```

Dois fatos mecânicos, e os dois enganos que vêm de perder qualquer um deles.

## O wrapper é o que é chamado

```python
def wrapper():              # no
    ...

@timed
def load(path): ...

load("data.csv")            # TypeError: timed.<locals>.wrapper() takes 0
                            #            positional arguments but 1 was given
```

Depois da decoração, o `load` É o wrapper. O que quem chama passar chega ali, então o wrapper
precisa aceitar qualquer coisa — `*args, **kwargs` — e repassar direto, com as estrelas de novo na
chamada.

**O erro nomeia `timed.<locals>.wrapper`**, e o nome qualificado é a primeira pista de que
há decoração envolvida — o `timed` é o decorador, e o `wrapper` é a função que ele
construiu.

## O wrapper é o que devolve

```python
def wrapper(*args, **kwargs):
    func(*args, **kwargs)       # no return
```

Agora toda função decorada responde `None`. Nada levanta erro, o trabalho ainda acontece, e o
defeito parece ser a função decorada estando quebrada — em nove funções de uma vez, se você
decorou nove.

**`result = func(...)` e `return result`**, ou `return func(...)` quando não há o que fazer
depois.

## Manter algo de antes e de depois

```python
        start = time.perf_counter()
        try:
            return func(*args, **kwargs)
        finally:
            print(f"{func.__name__} took {time.perf_counter() - start:.3f}s")
```

O `try`/`finally` da aula 8 é como a parte do "depois" ainda acontece quando a função envolvida
levanta erro. Um decorador de cronometragem que só registra no sucesso é um que não diz nada sobre
a chamada que travou.

## Deixar a exceção passar

Não a capture a menos que o trabalho do decorador seja capturá-la. Um wrapper que engole uma
exceção escondeu uma falha num lugar em que ninguém vai olhar, e fez isso em todo lugar em que ele
é aplicado.
