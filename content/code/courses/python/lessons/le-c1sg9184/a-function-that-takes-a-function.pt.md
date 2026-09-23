---
title: A função de dentro, e o que ela lembra
version: 2
---

```python
def shout(text):
    return text.upper()

def twice(func):
    def wrapper(text):
        return func(func(text))
    return wrapper

loud = twice(shout)
loud("ada")        # 'ADA'
```

O `twice` recebe uma função e devolve uma função NOVA. Nada nisso é sintaxe especial — é o
"uma função é um valor" da aula 5, aplicado duas vezes num lugar só.

## O fechamento

O `wrapper` usa `func`, que não é parâmetro dele e não é global. É o parâmetro da função dentro da
qual o `wrapper` foi definido, e ele continua lá depois de `twice` ter devolvido.

**Isso é um fechamento**, e é a maquinaria em que a aula inteira se apoia: a função de dentro
lembra as variáveis que estavam em volta dela quando ela foi criada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um decorador devolve uma função nova que guarda a original dentro de si. Uma chamada entra no wrapper, passa pelo que ele faz antes, entra na original, volta pelo que ele faz depois, e quem chamou recebe essa resposta.\"> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"150\" y=\"44\" width=\"420\" height=\"120\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\"></rect> <text x=\"164\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o wrapper que o timed() devolveu</text> <rect x=\"176\" y=\"76\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"251\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que ele faz antes</text> <rect x=\"394\" y=\"76\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"469\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que ele faz depois</text> <rect x=\"250\" y=\"118\" width=\"220\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">load_rows, a original</text> <path d=\"M330 91 L352 91 L352 113\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M474 134 L494 134 L494 111\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"20\" y=\"91\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a chamada chega aqui</text> <path d=\"M138 91 L146 91\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"702\" y=\"91\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a resposta, de volta</text> <path d=\"M574 91 L586 91\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"360\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">O wrapper alcança a original por um nome que nunca foi parâmetro dele</text> <text x=\"360\" y=\"207\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e não é global — é um fechamento, e é a maquinaria inteira desta aula.</text> </svg>", "caption": "O wrapper é uma função comum com a original guardada dentro. Nada aqui é sintaxe — é uma função que ainda estava por ali quando a de dentro foi feita."}
```

```python
a = twice(shout)
b = twice(strip)
```

Dois wrappers, cada um lembrando de um `func` diferente. Eles não interferem, porque cada chamada
a `twice` criou uma função interna nova com as próprias vizinhanças.

## Por que a função de dentro existe

Porque um decorador precisa devolver algo CHAMÁVEL que ainda não foi chamado. Ele não pode
devolver `func(x)` — ele não tem um `x`. Ele devolve uma função que vai chamar `func` quando
alguém eventualmente chamar ELA.

## A forma, antes de qualquer sintaxe

```python
def decorator(func):
    def wrapper(...):
        # before
        result = func(...)
        # after
        return result
    return wrapper
```

Todo decorador desta aula é essa forma com os detalhes preenchidos. O `@` é um atalho para a linha
que o usa, e é a próxima seção.
