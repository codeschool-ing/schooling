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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 272\" role=\"img\" aria-label=\"Pede-se um iterador a uma lista, e é o iterador que guarda a posição. Cada next a move uma casa adiante; quando não sobra nada ele levanta StopIteration. A lista fica igual e pode ser pedida por outro iterador a qualquer momento.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"34\" width=\"190\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"115\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">[1, 2, 3]</text> <path d=\"M216 54 L268 54\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"274\" y=\"34\" width=\"300\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"424\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">iter(...)  a posição vive aqui</text> <text x=\"274\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">next(it)</text> <path d=\"M380 96 L430 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"442\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">1</text> <text x=\"274\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">next(it)</text> <path d=\"M380 130 L430 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"442\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">2</text> <text x=\"274\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">next(it)</text> <path d=\"M380 164 L430 164\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"442\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">3</text> <text x=\"274\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">next(it)</text> <path d=\"M380 198 L430 198\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"442\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">StopIteration</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Peça outro iterador à lista e você recomeça do início.</text> <text x=\"360\" y=\"253\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Peça qualquer coisa a um iterador gasto e ele levanta erro, para sempre.</text> </svg>", "caption": "O iterável é a coisa; o iterador é o dedo em cima dela. Só um dos dois se move, e ele só se move para a frente."}
```

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
