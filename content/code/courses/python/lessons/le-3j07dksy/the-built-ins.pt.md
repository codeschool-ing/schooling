---
title: Cinco tipos e um retorno que não é um valor
version: 1
---

```python
def carregar(caminho: str) -> bytes: ...
def taxa(codigo: str) -> float: ...
def valida(linha: dict) -> bool: ...
def contar(itens: list) -> int: ...
```

`int`, `str`, `bool`, `float`, `bytes` — a própria classe é a anotação. Não há o que importar nem
nada especial a aprender.

## `None` como retorno

```python
def salvar(linhas: list) -> None:
    ...
```

`-> None` quer dizer que a função não devolve nada útil. Não é "não devolve valor" — toda função
Python devolve algo, e esta devolve `None`.

**Escreva.** Uma função sem anotação de retorno é uma que um verificador pode pular inteira, e o
`-> None` também é uma declaração de intenção: esta está aqui pelo efeito.

## `int` e `float`

```python
def metade(n: float) -> float: ...
metade(4)          # tudo bem
```

Um verificador aceita `int` em todo lugar em que `float` é pedido — um caso especial deliberado do
sistema de tipos, porque recusar tornaria toda anotação numérica cansativa. O contrário não vale.

## `bool` é um `int`

`True` é `1` e `bool` é subclasse de `int`, então um `bool` é aceito onde um `int` é pedido. Isso
de vez em quando é o que você quer e em geral é acidente, e um verificador não te salva disso.

## `str` e `bytes` não se trocam

A aula 9 disse isso sobre o `==`, e o verificador diz sobre argumentos: uma função anotada `str`
recusa `bytes`, que é exatamente o engano de fronteira daquela seção.

## E a anotação vazia

```python
def f(x):          # sem anotação: o verificador não supõe nada
```

Um parâmetro sem anotação é `Any` para a maioria dos verificadores no modo padrão — o que quer
dizer que a conferência para ali. Isso não é falha; é como um arquivo é anotado aos poucos.
