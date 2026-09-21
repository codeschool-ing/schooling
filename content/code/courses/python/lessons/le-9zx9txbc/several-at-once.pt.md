---
title: Dois num `with`, e a quantidade que você não sabe
version: 1
---

```python
with open(orig, encoding="utf-8") as a, open(dest, "w", encoding="utf-8") as b:
    b.write(a.read())
```

Vírgulas. Os dois entram da esquerda para a direita, os dois saem da direita para a esquerda, e o
segundo não entra se o primeiro levantar erro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Dois gerenciadores de contexto numa linha entram da esquerda para a direita e saem da direita para a esquerda, em volta do corpo no meio. Se o primeiro levantar erro na entrada, o segundo nunca é aberto e nunca precisa ser fechado.\"> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <rect x=\"150\" y=\"34\" width=\"420\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">entra a</text> <rect x=\"190\" y=\"74\" width=\"340\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">entra b</text> <rect x=\"230\" y=\"114\" width=\"260\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o corpo</text> <rect x=\"190\" y=\"154\" width=\"340\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">sai b</text> <rect x=\"150\" y=\"194\" width=\"420\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">sai a</text> <text x=\"130\" y=\"66\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">na entrada</text> <text x=\"130\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">na saída</text> <path d=\"M112 78 L112 156\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"360\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">se o primeiro levantar erro na entrada, o segundo nunca chega a entrar</text> </svg>", "caption": "Entra pela esquerda, sai pela direita — que é a única ordem que deixa o segundo usar o que o primeiro abriu."}
```

## A forma entre parênteses

```python
with (
    open(orig, encoding="utf-8") as a,
    open(dest, "w", encoding="utf-8") as b,
):
    ...
```

Desde o Python 3.10, o que torna uma linha longa legível sem uma barra invertida.

## Aninhar é a mesma coisa com mais indentação

```python
with open(orig) as a:
    with open(dest, "w") as b:
```

Comportamento idêntico. Use a forma com vírgula; guarde o aninhamento para quando algo entre as
duas linhas precisar acontecer.

## `ExitStack`, para a quantidade que você não sabe

```python
from contextlib import ExitStack

with ExitStack() as pilha:
    arquivos = [pilha.enter_context(open(p, encoding="utf-8")) for p in caminhos]
    juntar(arquivos)
```

Todo arquivo é fechado na saída, em ordem inversa, termine o bloco como terminar. Esta é a
resposta quando a contagem vem do dado e não do código — e escrever isso com um `try`/`finally` e
uma lista é a versão que vaza os que foram abertos antes da falha.

O `pilha.callback(func, arg)` registra um desfazer arbitrário, para uma coisa que não tem
gerenciador próprio.

## A ordem importa

As saídas rodam ao contrário, que é o que você quer: o que foi aberto por último é desfeito
primeiro, e um gerenciador pode contar com os de fora ainda vivos enquanto ele arruma.
