---
title: O bloco é do tamanho da coisa que pode falhar
version: 2
---

```python
try:
    port = int(raw)
except ValueError:
    port = 5432
```

O `try` segura a coisa que pode falhar. O `except` nomeia a classe e diz o que fazer. É a
construção inteira.

## Mantenha o `try` pequeno

```python
try:                              # NO
    rows = load(path)
    total = sum(r["amount"] for r in rows)
    report(total)
except KeyError:
    ...
```

Três coisas na rede e uma delas é a que você queria. O `KeyError` que você esperava era de
`r["amount"]`; o que você acabou de capturar pode ser de dentro do `report`, três arquivos adiante
— e você nunca vai saber, porque o tratamento é o mesmo.

**Ponha o `try` em volta da linha que falha**, e de nada mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um try em volta de três linhas pega um KeyError de qualquer uma delas, e o tratador não sabe de qual. Um try em volta da única linha que pode falhar pega só aquela, e as outras duas ficam livres para falhar alto.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"185\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">o try em volta de tudo</text> <rect x=\"20\" y=\"36\" width=\"330\" height=\"90\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-dasharray=\"4 3\"></rect> <text x=\"34\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rows = load(path)</text> <text x=\"34\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">total = sum(r[&quot;amount&quot;] for r in rows)</text> <text x=\"34\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">report(total)</text> <path d=\"M110 134 L160 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <path d=\"M260 134 L210 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"20\" y=\"160\" width=\"330\" height=\"32\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"185\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">except KeyError:</text> <text x=\"185\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">duas falhas caem aqui e são lidas igual</text> <text x=\"535\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">o try em volta da linha que falha</text> <rect x=\"370\" y=\"66\" width=\"330\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-dasharray=\"4 3\"></rect> <text x=\"384\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rows = load(path)</text> <text x=\"384\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">total = sum(r[&quot;amount&quot;] for r in rows)</text> <text x=\"384\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">report(total)</text> <path d=\"M535 104 L535 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"370\" y=\"160\" width=\"330\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"535\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">except KeyError:</text> <text x=\"535\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">uma falha cai aqui, e é a que você queria</text> </svg>", "caption": "O tratador é o mesmo dos dois jeitos. O que muda é por quantas falhas diferentes ele responde."}
```

## Vários tipos

```python
except FileNotFoundError:
    ...
except PermissionError:
    ...
except OSError as e:          # anything else from the filesystem
    ...
```

As cláusulas são tentadas em ordem e a PRIMEIRA que casa vence, então as específicas vêm antes. Uma
classe base acima de uma subclasse faz da cláusula da subclasse código morto, e o Python não vai
avisar.

## `as e`, e o que fazer com ele

```python
except ValueError as e:
    raise ValueError(f"{path}: port must be a number, not {raw!r}") from e
```

Capturar uma falha para dizer algo melhor sobre ela é uma das duas boas razões para capturar. A
outra é ter uma alternativa — um padrão, um segundo servidor, uma linha a pular.

**"Porque pode falhar" não é uma razão.** Se o tratamento não sabe o que fazer, o código acima
talvez saiba, e o traceback certamente sabe.

## O tratamento que esconde o defeito

```python
except Exception:
    pass          # the most expensive two lines in this course
```

Um `pass` num tratamento quer dizer: algo deu errado, e eu decidi que ninguém precisa saber. Se uma
falha é mesmo segura de ignorar, o tratamento diz isso num comentário e nomeia a classe — e esse
comentário é o que quem lê precisa seis meses depois.
