---
title: Parênteses, e receber algo de volta
version: 2
---

```python
m = re.search(r"(\d{4})-(\d{2})-(\d{2})", line)
m.group(0)      # the whole match
m.group(1)      # '2026'
m.groups()      # ('2026', '09', '21')
```

Parênteses CAPTURAM. O `group(0)` é tudo o que o padrão casou; o resto é numerado da esquerda para
a direita pelo parêntese que abre.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"A linha com a coincidência inteira marcada em cima e os três grupos capturados marcados embaixo, numerados de um a três pelo parêntese que abre, da esquerda para a direita.\"> <text x=\"360\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">(\\d{4})-(\\d{2})-(\\d{2})</text> <text x=\"180\" y=\"76\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"17\" fill=\"var(--paper)\" xml:space=\"preserve\">pedido 2026-09-21 ok</text> <path d=\"M257 56 L257 46 L367 46 L367 56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"383\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">m.group(0)</text> <path d=\"M257 94 L257 104 L301 104 L301 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <circle cx=\"279\" cy=\"122\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"279\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text> <text x=\"279\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">'2026'</text> <path d=\"M312 94 L312 104 L334 104 L334 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <circle cx=\"323\" cy=\"122\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"323\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text> <text x=\"323\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">'09'</text> <path d=\"M345 94 L345 104 L367 104 L367 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <circle cx=\"356\" cy=\"122\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"356\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text> <text x=\"356\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">'21'</text> <text x=\"360\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Dê nome a eles assim que passarem de dois: m[&quot;ano&quot;] sobrevive a um grupo inserido</text> <text x=\"360\" y=\"207\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e m.group(3) é um número que alguém tem de contar parênteses para conferir.</text> </svg>", "caption": "O grupo zero é tudo o que o padrão casou. O resto é numerado pelo parêntese que abre — e é por isso que inserir um na frente renumera os outros, em silêncio."}
```

## Grupos com nome

```python
m = re.search(r"(?P<year>\d{4})-(?P<month>\d{2})", line)
m["year"]              # '2026'
m.group("month")       # '09'
m.groupdict()          # {'year': '2026', 'month': '09'}
```

**Dê nome a eles no momento em que houver mais de dois.** O `m.group(3)` é um número que alguém
precisa contar achando o terceiro parêntese que abre, e inserir um grupo na frente renumera tudo
depois dele — em silêncio.

## Sem captura

```python
r"(?:https?)://(\S+)"
```

`(?:…)` agrupa sem capturar, que é o que você quer quando os parênteses estão ali pelo `?` ou pelo
`|` e não para recolher alguma coisa. Ele mantém estável a numeração dos grupos que você QUER.

## Um grupo que não participou

```python
m = re.match(r"(\+\d+ )?(\d+)", "5551234")
m.group(1)       # None, not ''
```

Um grupo opcional que não estava lá dá `None`. `m.group(1) or ""` é a resposta de sempre, e
esquecer disso é um `AttributeError` em `None` algumas linhas depois.

## Alternância

```python
r"ERROR|WARN|INFO"
r"(?:ERROR|WARN|INFO)"        # when it is part of something bigger
```

O `|` tem a MENOR precedência de tudo na linguagem, então `^ERROR|WARN$` quer dizer "começa com
ERROR" ou "termina com WARN" — quase nunca o que se queria. Ponha entre parênteses.
