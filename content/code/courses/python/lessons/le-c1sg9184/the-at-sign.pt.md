---
title: `@d` é `f = d(f)`, escrito acima em vez de abaixo
version: 2
---

```python
@timed
def load_rows(path):
    ...
```

quer dizer exatamente:

```python
def load_rows(path):
    ...
load_rows = timed(load_rows)
```

**Essa é a coisa inteira que o símbolo `@` é.** São dois caracteres que poupam uma linha e põem a
informação no topo, onde quem lê a vê antes do corpo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"O arroba faz uma coisa: ele religa o nome. Depois que o decorador roda, o nome aponta para o que o decorador devolveu, e a função original continua lá — guardada pelo wrapper, e alcançável por mais nada.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <text x=\"360\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\">@timed</text> <text x=\"360\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">load_rows = timed(load_rows)</text> <text x=\"182\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">antes</text> <rect x=\"20\" y=\"88\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">load_rows</text> <path d=\"M182 128 L182 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"20\" y=\"164\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a função que você escreveu</text> <text x=\"558\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">depois</text> <rect x=\"396\" y=\"88\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"558\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">load_rows</text> <path d=\"M558 128 L558 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"396\" y=\"164\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o que o cronometrado devolveu</text> <path d=\"M558 204 L558 230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"396\" y=\"236\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"558\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a função que você escreveu</text> <text x=\"558\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">continua lá, guardada pelo wrapper</text> </svg>", "caption": "Dois caracteres que poupam uma linha e põem a informação acima do corpo, onde quem lê a encontra primeiro."}
```

## As duas formas, lado a lado

```python
@timed                          # the name `load_rows` now refers to
def load_rows(path): ...        # whatever `timed` returned

load_rows = timed(load_rows)    # the same rebinding, said out loud
```

O nome é religado. A função original continua existindo — o wrapper a está segurando — mas nada
mais a alcança por aquele nome.

## Quando um decorador confunde você

Escreva-o da segunda forma. `@retry(times=3)` vira `f = retry(times=3)(f)`, e os dois pares de
parênteses deixam de ser misteriosos: o `retry(times=3)` é chamado primeiro, e o que ele
devolver é chamado com `f`.

**Este é o truque mais útil desta aula**, e é por isso que a seção vem antes das mais difíceis.

## Funciona em classes e métodos também

```python
@dataclass
class Student: ...

class Rectangle:
    @property
    def area(self): ...
```

`@dataclass` é `Student = dataclass(Student)`; o `@property` da aula 6 é `area = property(area)` dentro
do corpo da classe. Nada de novo acontece — a mesma religação, num tipo diferente de objeto.

## E ele é aplicado na definição

O decorador roda quando o `def` roda, e não quando a função é chamada. Um decorador que imprime
algo imprime na importação, uma vez, o que de vez em quando é uma surpresa e em geral é como um
registro é preenchido.
