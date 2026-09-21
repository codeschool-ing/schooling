---
title: Dois métodos, e o que o `for` está fazendo
version: 1
---

```python
it = iter([1, 2, 3])
next(it)      # 1
next(it)      # 2
next(it)      # 3
next(it)      # StopIteration
```

`iter(x)` pede um iterador a `x` chamando o `__iter__` dele. `next(it)` chama o `__next__` do
iterador. Quando não sobra nada, o `__next__` levanta `StopIteration`.

## O que um laço `for` é

```python
for item in itens:
    corpo(item)
```

é, aproximadamente:

```python
it = iter(itens)
while True:
    try:
        item = next(it)
    except StopIteration:
        break
    corpo(item)
```

**Toda surpresa desta aula decorre disso.** O laço pede um iterador uma vez e então puxa valores
até a exceção — então um segundo laço sobre o mesmo ITERADOR não recebe nada, e um segundo laço
sobre a mesma LISTA recebe um iterador novo e funciona.

## `StopIteration` é um sinal, e não um erro

É uma exceção usada para controle de fluxo, e o laço `for` a engole. Você quase nunca vai
capturá-la; o `next(it, padrao)` é a versão que devolve um padrão em vez de levantar, e é o que
você quer ao pedir um valor.

```python
primeiro = next(it, None)
```

## Tudo o que você já usa

`range`, `zip`, `enumerate`, `map`, `filter`, um objeto de arquivo, o `.items()` de um dicionário,
toda expressão geradora. Alguns deles são iteradores e alguns produzem um novo a cada vez — a
próxima seção é essa distinção, e é a que importa na prática.

## Por que o protocolo existe

Porque o `for` então funciona com qualquer coisa que implemente dois métodos. Uma lista, um
arquivo, um cursor de banco, um fluxo de linhas de uma API — o laço não nota a diferença, e você
pode escrever algo novo sobre o que ele também não nota.
