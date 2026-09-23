---
title: `try`/`finally`, com um nome
version: 2
---

```python
with open(path, encoding="utf-8") as f:
    process(f)
```

Três coisas acontecem, em ordem: a PREPARAÇÃO (o arquivo é aberto), o CORPO, e o DESFAZER (o
arquivo é fechado). A terceira acontece termine a segunda como terminar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 284\" role=\"img\" aria-label=\"Três estágios em ordem: a preparação, o corpo e o desfazer. O corpo pode chegar ao fim, retornar, sair do laço ou levantar erro, e cada um desses quatro caminhos passa pelo desfazer. Uma exceção então segue subindo depois.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"180\" y=\"26\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a preparação — o arquivo é aberto</text> <path d=\"M360 66 L360 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"180\" y=\"88\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o corpo</text> <rect x=\"24\" y=\"144\" width=\"152\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"100\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ele chega ao fim</text> <path d=\"M360 128 L100 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <path d=\"M100 180 L360 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"200\" y=\"144\" width=\"152\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"276\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ele retorna</text> <path d=\"M360 128 L276 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <path d=\"M276 180 L360 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"376\" y=\"144\" width=\"152\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"452\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ele sai do laço</text> <path d=\"M360 128 L452 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <path d=\"M452 180 L360 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"552\" y=\"144\" width=\"152\" height=\"32\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"628\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ele levanta erro</text> <path d=\"M360 128 L628 140\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <path d=\"M628 180 L360 196\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"180\" y=\"200\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o desfazer — o arquivo é fechado</text> <text x=\"700\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a exceção segue subindo</text> <text x=\"360\" y=\"254\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Escrito por extenso, isto é a aula 8: um try com um finally embaixo.</text> <text x=\"360\" y=\"271\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">O que o with acrescenta é que ninguém precisa lembrar de escrever o finally.</text> </svg>", "caption": "O desfazer não fica no pé de quem lembrou. Ele mora ao lado da preparação, dentro da coisa que está sendo usada."}
```

## A mesma coisa, escrita por extenso

```python
f = open(path, encoding="utf-8")
try:
    process(f)
finally:
    f.close()
```

É isso que o `with` faz, e a aula 8 escreveu. O que o `with` acrescenta é que o desfazer mora ao
lado da preparação, dentro da coisa que está sendo usada, em vez de no fim de quem lembrou.

## "Termine o corpo como terminar"

- ele chega ao fim
- ele dá `return`
- ele dá `break` ou `continue` num laço
- ele levanta erro

**Nos cinco o desfazer roda.** A exceção então segue para cima, sem mudança — o gerenciador
arrumou e não interferiu.

## O que isso compra, numa frase

Quem USA não consegue esquecer. Um `open` sem `with` é um `close` que alguém precisa lembrar em
todo caminho de saída de toda função, para sempre; o `with` é uma linha e o problema não existe.

## Onde você já viu isso

```python
with open(path) as f: ...            # lesson 9
with lock: ...                       # a threading lock
with conn: ...                       # a database transaction
with tempfile.TemporaryDirectory() as d: ...
```

Cada um é a mesma forma com um desfazer diferente: fechar, soltar, confirmar ou desfazer, apagar.

## E a frase a levar

**Se alguma coisa precisa ser desfeita, o desfazer pertence à coisa que fez** — e não a um
comentário, nem a quem chama, nem a um `finally` que alguém vai esquecer.
