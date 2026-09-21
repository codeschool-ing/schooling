---
title: A função de dentro, e o que ela lembra
version: 1
---

```python
def gritar(texto):
    return texto.upper()

def duas_vezes(func):
    def wrapper(texto):
        return func(func(texto))
    return wrapper

alto = duas_vezes(gritar)
alto("ada")        # 'ADA'
```

O `duas_vezes` recebe uma função e devolve uma função NOVA. Nada nisso é sintaxe especial — é o
"uma função é um valor" da aula 5, aplicado duas vezes num lugar só.

## O fechamento

O `wrapper` usa `func`, que não é parâmetro dele e não é global. É o parâmetro da função dentro da
qual o `wrapper` foi definido, e ele continua lá depois de `duas_vezes` ter devolvido.

**Isso é um fechamento**, e é a maquinaria em que a aula inteira se apoia: a função de dentro
lembra as variáveis que estavam em volta dela quando ela foi criada.

```python
a = duas_vezes(gritar)
b = duas_vezes(limpar)
```

Dois wrappers, cada um lembrando de um `func` diferente. Eles não interferem, porque cada chamada
a `duas_vezes` criou uma função interna nova com as próprias vizinhanças.

## Por que a função de dentro existe

Porque um decorador precisa devolver algo CHAMÁVEL que ainda não foi chamado. Ele não pode
devolver `func(x)` — ele não tem um `x`. Ele devolve uma função que vai chamar `func` quando
alguém eventualmente chamar ELA.

## A forma, antes de qualquer sintaxe

```python
def decorador(func):
    def wrapper(...):
        # antes
        resultado = func(...)
        # depois
        return resultado
    return wrapper
```

Todo decorador desta aula é essa forma com os detalhes preenchidos. O `@` é um atalho para a linha
que o usa, e é a próxima seção.
