---
title: A f-string, e o que vem depois dos dois pontos
version: 1
---

```python
nome = "Ada"
print(f"Olá, {nome}")
```
```
Olá, Ada
```

Um `f` antes da aspa, e chaves em volta de **qualquer expressão** — não só de um nome:

```python
>>> f"{2 + 2}"
'4'
>>> f"{nome.upper()}"
'ADA'
```

## `=` para depurar

```python
>>> total = 41
>>> f"{total=}"
'total=41'
```

O nome e o valor, com um caractere. É o idioma de depuração por `print` no Python moderno e vale a
memória muscular.

## A especificação de formato

Depois de dois pontos dentro das chaves, você diz **como**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 272\" role=\"img\" aria-label=\"As partes de uma f-string, da esquerda para a direita: o f que faz as chaves significarem algo, a expressão dentro delas, os dois pontos que separam o quê do como, e o formato que diz dez de largura, alinhado à direita, com separador de milhar e duas casas decimais.\"> <text x=\"180\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper-dim)\" xml:space=\"preserve\">f&quot;</text> <text x=\"204\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper-dim)\" xml:space=\"preserve\">{</text> <text x=\"216\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\" xml:space=\"preserve\">total</text> <text x=\"276\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--amber)\" xml:space=\"preserve\">:</text> <text x=\"288\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" xml:space=\"preserve\">&gt;10,.2f</text> <text x=\"372\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper-dim)\" xml:space=\"preserve\">}&quot;</text> <circle cx=\"192\" cy=\"76\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"192\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text> <circle cx=\"246\" cy=\"76\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"246\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text> <circle cx=\"282\" cy=\"76\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"282\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text> <circle cx=\"330\" cy=\"76\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"330\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text> <path d=\"M180 96 L276.0 96\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"228\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o que imprimir</text> <path d=\"M288.0 96 L372.0 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"330\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">como imprimir</text> <rect x=\"150\" y=\"152\" width=\"436\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"168\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text> <text x=\"196\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o f é o que faz as chaves significarem algo</text> <rect x=\"150\" y=\"182\" width=\"436\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"168\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text> <text x=\"196\" y=\"194\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dentro das chaves, qualquer expressão</text> <rect x=\"150\" y=\"212\" width=\"436\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"168\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text> <text x=\"196\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">os dois pontos separam o quê do como</text> <rect x=\"150\" y=\"242\" width=\"436\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"168\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text> <text x=\"196\" y=\"254\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dez de largura, à direita, milhar, duas casas</text> </svg>", "caption": "Tudo antes dos dois pontos é o que imprimir. Tudo depois é como."}
```

```python
>>> f"{3.14159:.2f}"
'3.14'
>>> f"{1234567:,}"
'1,234,567'
>>> f"{0.734:.1%}"
'73.4%'
>>> f"{42:>8}"
'      42'
>>> f"{42:08}"
'00000042'
```

| | |
|---|---|
| `.2f` | duas casas decimais, fixas |
| `,` ou `_` | separador de milhar |
| `%` | como porcentagem, e multiplica por 100 |
| `>` `<` `^` | à direita, à esquerda, ao centro, numa largura |
| `0` | preencher com zeros |
| `e` | científica |
| `b` `o` `x` | binário, octal, hexadecimal |

**A largura pode ser uma variável**: `f"{nome:>{w}}"`.

## Chaves que você quer manter

Dobre: `f"{{literal}}"` imprime `{literal}`.

## Os dois jeitos mais antigos

Você vai encontrar os dois em código que não escreveu.

```python
"Olá, {}".format(nome)     # .format, do Python 2.6
"Olá, %s" % nome           # %, desde o começo
```

Os dois continuam funcionando. Nenhum dos dois vale ser escrito agora, com uma exceção honesta:
chamadas de log usam a forma `%` de propósito, para a formatação ser pulada quando a mensagem não
vai ser emitida.

## O que uma f-string não é

Ela não é um modelo que você guarda e preenche depois — é avaliada onde está escrita. E ela **não**
é como se monta SQL, um comando de shell ou HTML. O `sql-databases` tem uma seção sobre exatamente
o buraco que uma f-string abre ali, e a resposta é um parâmetro, toda vez.
