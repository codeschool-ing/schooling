---
title: `split(",")` não é ler um CSV
version: 2
---

```python
import csv

with open(path, newline="", encoding="utf-8") as f:
    for row in csv.reader(f):
        print(row[0], row[2])      # a list of strings
```

## Por que não `split(",")`

```
name,city,score
Ada,"Porto, Portugal",91
```

O `split(",")` dá quatro pedaços e põe `Portugal"` na coluna da nota. Ele não levanta erro; o total
no fim simplesmente sai errado. Uma vírgula entre aspas, uma quebra de linha entre aspas, uma aspa
escapada dentro de um campo entre aspas — o formato tem regras, e a biblioteca as conhece.

**Este é de longe o jeito mais comum de um script de dados estar errado em silêncio.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"A linha Ada, entre aspas Porto vírgula Portugal, noventa e um. Separada por vírgulas ela se parte em quatro pedaços e a coluna da nota guarda um pedaço da cidade. O leitor de csv dá três, porque ele sabe que uma vírgula entre aspas não é separador.\"> <text x=\"360\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">name,city,score</text> <text x=\"360\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">Ada,&quot;Porto, Portugal&quot;,91</text> <text x=\"20\" y=\"80\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">split(&quot;,&quot;) — quatro pedaços</text> <rect x=\"25\" y=\"90\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"105\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Ada</text> <text x=\"105\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">row[0]</text> <rect x=\"195\" y=\"90\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"275\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">&quot;Porto</text> <text x=\"275\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">row[1]</text> <rect x=\"365\" y=\"90\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"445\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\"> Portugal&quot;</text> <text x=\"445\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">row[2]</text> <rect x=\"535\" y=\"90\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"615\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">91</text> <text x=\"615\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">row[3]</text> <text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a coluna da nota agora guarda meia cidade</text> <text x=\"20\" y=\"190\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">csv.reader — três campos</text> <rect x=\"26\" y=\"200\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"134\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Ada</text> <text x=\"134\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">row[&quot;name&quot;]</text> <rect x=\"252\" y=\"200\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Porto, Portugal</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">row[&quot;city&quot;]</text> <rect x=\"478\" y=\"200\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"586\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">91</text> <text x=\"586\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">row[&quot;score&quot;]</text> </svg>", "caption": "Nada levanta erro. A linha tem o tamanho errado, a nota é um pedaço da cidade, e o total no fim simplesmente sai errado."}
```

## `DictReader`, que é o que se usa

```python
with open(path, newline="", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        print(row["name"], row["score"])
```

Ele lê o cabeçalho e dá um dicionário por linha. Uma coluna inserida no meio do arquivo então não
quebra nada, e `row["score"]` diz o que `row[2]` não dizia.

O `fieldnames=` fornece os nomes quando o arquivo não tem cabeçalho — e se você o passar para um
arquivo que TEM um, o cabeçalho chega como linha de dado.

## `newline=""`, que não é opcional

O módulo `csv` cuida das quebras de linha ele mesmo, porque um campo pode conter uma quebra dentro
das aspas dele. O modo texto traduzindo `\r\n` na entrada atrapalha isso, e o sintoma é uma linha em
branco entre cada linha de verdade em arquivos escritos no Windows.

**Passe `newline=""` em todo `open` que um leitor ou escritor `csv` vai tocar.** Está no primeiro
exemplo da documentação exatamente por isso.

## Tudo é string

```python
total = sum(int(row["score"]) for row in rows)
```

`row["score"]` é `"91"`. Não há informação de tipo num arquivo CSV — um número, uma data e uma
célula vazia chegam todos como `str`, e `""` é como uma célula vazia se parece, e não `None`.

**Converta na fronteira e deixe a linha ruim se nomear:**

```python
try:
    score = int(row["score"])
except ValueError:
    raise ValueError(f"{path}:{n}: score is not a number: {row['score']!r}")
```

## Os outros dialetos

`delimiter=";"` para os arquivos que o Excel escreve em boa parte da Europa, `delimiter="\t"` para
TSV. O `csv.Sniffer` adivinha, e adivinhar num arquivo que você não olhou é como um script decide
que um ponto e vírgula é dado.
