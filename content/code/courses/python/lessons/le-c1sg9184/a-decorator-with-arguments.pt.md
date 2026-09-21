---
title: A terceira camada, e por que todo mundo consulta
version: 1
---

```python
@repetir(vezes=3)
def buscar(url):
    ...
```

Escreva o `@` como chamada, como a seção anterior disse:

```python
buscar = repetir(vezes=3)(buscar)
```

**Duas chamadas.** O `repetir(vezes=3)` roda primeiro e precisa devolver um DECORADOR; esse
decorador é então chamado com `buscar`. Então há três camadas em vez de duas.

```python
def repetir(vezes):                     # 1. recebe o argumento
    def decorador(func):                # 2. recebe a função
        @functools.wraps(func)
        def wrapper(*args, **kwargs):   # 3. recebe a chamada
            for tentativa in range(vezes):
                try:
                    return func(*args, **kwargs)
                except OSError:
                    if tentativa == vezes - 1:
                        raise
        return wrapper
    return decorador
```

Leia de dentro para fora: o `wrapper` faz o trabalho, o `decorador` faz um wrapper para uma função,
o `repetir` faz um decorador para uma configuração.

## Por que não dá para ser duas camadas

Porque o `@` aplica o que vem depois dele à função abaixo. Se o `repetir` recebesse a função, ele
não teria onde pôr o `vezes`. A chamada precisa acontecer antes de o `@` fazer qualquer coisa.

## O que pega as pessoas

```python
@repetir            # sem parênteses
def buscar(url): ...
```

Agora o `vezes` é a FUNÇÃO, e o `decorador` é o que o `buscar` vira — então chamar `buscar(url)`
chama `decorador(url)` e devolve um wrapper em vez de um resultado. Nada levanta erro até muito
depois, e a mensagem é sobre outra coisa.

**Um decorador que recebe argumentos precisa sempre ser escrito com parênteses**, mesmo vazios, a
não ser que ele tenha sido construído de propósito para aceitar os dois jeitos.

## E a nota honesta

Esta é a parte da aula que as pessoas consultam toda vez, inclusive quem escreve isso com
frequência. Escrever o `@` como chamada é o que a torna legível, e não há vergonha nenhuma em
fazer isso no papel antes de digitar.
