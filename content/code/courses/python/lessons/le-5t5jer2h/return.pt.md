---
title: Um valor, vários valores, e a diferença para imprimir
version: 1
---

```python
def analisar(linha):
    nome, _, cidade = linha.partition(",")
    return nome, cidade        # uma tupla, e os parênteses são opcionais
```

O `return` encerra a função na hora e devolve um valor. Vários valores são uma tupla, e quem chama
desempacota do mesmo jeito que a aula 3 desempacotava qualquer outra:

```python
nome, cidade = analisar(linha)
```

**Acima de três, dê nomes.** Uma função que devolve cinco coisas numa tupla é uma função cujo
chamador precisa lembrar de uma ordem, que é exatamente o que a aula 3 disse sobre uma lista de
campos.

## Retorno antecipado

```python
def preco_de(plano):
    if plano == "gratuito":
        return 0
    if plano not in PRECOS:
        raise ValueError(f"plano desconhecido: {plano}")
    return PRECOS[plano]
```

Vários `return` são Python comum, e não algo de que ter culpa. A forma de guarda da aula 4 é
construída em cima disso: tire os casos resolvidos no topo e deixe o corpo num nível só.

## Devolver contra imprimir

```python
def total(linhas):
    print(sum(l["valor"] for l in linhas))     # dá para ler; não dá para usar

def total(linhas):
    return sum(l["valor"] for l in linhas)     # dá para usar; quem chama imprime
```

**Uma função que imprime a resposta a deu a uma pessoa e não ao programa.** Nada consegue somá-la,
testá-la ou gravá-la num arquivo. Calcule e devolva; imprima na borda, onde o programa fala com
alguém.

Esta é a forma mais comum em código de quem está começando, e é o motivo de a mesma função não dar
para reaproveitar no script seguinte.

## `return` sem nada

```python
    if not linhas:
        return
```

Devolve `None`, e se lê como "não há o que fazer aqui". Tudo bem por si; **não o misture com
devolver um valor na mesma função** a menos que `None` signifique alguma coisa para quem chama,
porque aí toda chamada precisa de um teste que ninguém vai escrever.
