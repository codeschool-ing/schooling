---
title: `*args`, `**kwargs`, e desempacotar nas duas direções
version: 2
---

```python
def total(*prices):
    return sum(prices)

total(10, 20, 30)       # prices is the tuple (10, 20, 30)
```

`*args` recolhe numa tupla os argumentos posicionais que ninguém nomeou. `**kwargs` recolhe num
dicionário os argumentos nomeados que ninguém declarou:

```python
def log(message, **fields):
    print(message, fields)

log("saved", rows=12, source="csv")     # fields is {'rows': 12, 'source': 'csv'}
```

Os nomes são convenção, não sintaxe — `*a` funciona. **Use os nomes convencionais**, porque quem lê
os reconhece de relance.

## As mesmas estrelas na chamada

```python
args = [10, 20, 30]
total(*args)                    # three arguments, not one list

options = {"port": 6543, "timeout": 30}
connect("db.example.tld", **options)
```

Uma estrela desempacota uma sequência em argumentos posicionais; duas desempacotam um dicionário em
argumentos nomeados. **A estrela significa "espalhe isto" nos dois lugares**, que é a ideia que vale
levar — uma função recolhe com ela, uma chamada espalha com ela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Uma estrela numa definição recolhe argumentos posicionais soltos numa tupla só. A mesma estrela numa chamada espalha uma sequência de volta em argumentos soltos. Ela quer dizer espalhe isto nos dois lugares.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">def total(*precos) — a função recolhe</text> <rect x=\"20\" y=\"32\" width=\"58\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"49\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">10</text> <rect x=\"90\" y=\"32\" width=\"58\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"119\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">20</text> <rect x=\"160\" y=\"32\" width=\"58\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"189\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">30</text> <path d=\"M236 49 L300 49\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"306\" y=\"32\" width=\"226\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"419\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">prices = (10, 20, 30)</text> <text x=\"20\" y=\"118\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">total(*args) — a chamada espalha</text> <rect x=\"20\" y=\"128\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"128\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">args = [10, 20, 30]</text> <path d=\"M242 145 L300 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"306\" y=\"128\" width=\"58\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"335\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">10</text> <rect x=\"376\" y=\"128\" width=\"58\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"405\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">20</text> <rect x=\"446\" y=\"128\" width=\"58\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"475\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">30</text> <text x=\"360\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Duas estrelas fazem o mesmo com nomes: **campos os recolhe num dicionário,</text> <text x=\"360\" y=\"207\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e connect(**options) espalha um dicionário de volta em argumentos nomeados.</text> </svg>", "caption": "Uma estrela, dois sentidos: a definição recolhe com ela e a chamada espalha com ela."}
```

## A estrela sozinha

```python
def charge(account, cents, *, refundable=False, dry_run=False):
    ...

charge(account, 1200, refundable=True)      # fine
charge(account, 1200, True)                 # TypeError
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
