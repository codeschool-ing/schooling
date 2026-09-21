---
title: `*args`, `**kwargs`, e desempacotar nas duas direções
version: 1
---

```python
def total(*precos):
    return sum(precos)

total(10, 20, 30)       # precos é a tupla (10, 20, 30)
```

`*args` recolhe numa tupla os argumentos posicionais que ninguém nomeou. `**kwargs` recolhe num
dicionário os argumentos nomeados que ninguém declarou:

```python
def log(mensagem, **campos):
    print(mensagem, campos)

log("salvo", linhas=12, origem="csv")     # campos é {'linhas': 12, 'origem': 'csv'}
```

Os nomes são convenção, não sintaxe — `*a` funciona. **Use os nomes convencionais**, porque quem lê
os reconhece de relance.

## As mesmas estrelas na chamada

```python
args = [10, 20, 30]
total(*args)                    # três argumentos, não uma lista

opcoes = {"porta": 6543, "timeout": 30}
conectar("db.example.tld", **opcoes)
```

Uma estrela desempacota uma sequência em argumentos posicionais; duas desempacotam um dicionário em
argumentos nomeados. **A estrela significa "espalhe isto" nos dois lugares**, que é a ideia que vale
levar — uma função recolhe com ela, uma chamada espalha com ela.

## A estrela sozinha

```python
def cobrar(conta, centavos, *, reembolsavel=False, simulacao=False):
    ...

cobrar(conta, 1200, reembolsavel=True)      # tudo bem
cobrar(conta, 1200, True)                   # TypeError
```

Tudo o que vem depois da estrela sozinha só dá para passar por nome. É como se torna impossível a
chamada ilegível, em vez de meramente desaconselhada, e vale a pena em qualquer função com dois
booleanos ou mais.

## Quando usá-los

Pouco, e para duas formas:

- uma quantidade genuinamente variável da mesma coisa — um `sum`, um `max`, um `join`
- um invólucro que repassa os argumentos direto para outra coisa, que é o decorador da aula 12

**`def f(*args, **kwargs)` numa função que depois lê `args[0]`** é uma assinatura que parou de dizer
o que a função recebe. Os parâmetros eram a documentação, e foram trocados por um dar de ombros.
