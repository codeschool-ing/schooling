---
title: `split(",")` não é ler um CSV
version: 1
---

```python
import csv

with open(caminho, newline="", encoding="utf-8") as f:
    for linha in csv.reader(f):
        print(linha[0], linha[2])      # uma lista de strings
```

## Por que não `split(",")`

```
nome,cidade,nota
Ada,"Porto, Portugal",91
```

O `split(",")` dá quatro pedaços e põe `Portugal"` na coluna da nota. Ele não levanta erro; o total
no fim simplesmente sai errado. Uma vírgula entre aspas, uma quebra de linha entre aspas, uma aspa
escapada dentro de um campo entre aspas — o formato tem regras, e a biblioteca as conhece.

**Este é de longe o jeito mais comum de um script de dados estar errado em silêncio.**

## `DictReader`, que é o que se usa

```python
with open(caminho, newline="", encoding="utf-8") as f:
    for linha in csv.DictReader(f):
        print(linha["nome"], linha["nota"])
```

Ele lê o cabeçalho e dá um dicionário por linha. Uma coluna inserida no meio do arquivo então não
quebra nada, e `linha["nota"]` diz o que `linha[2]` não dizia.

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
total = sum(int(linha["nota"]) for linha in linhas)
```

`linha["nota"]` é `"91"`. Não há informação de tipo num arquivo CSV — um número, uma data e uma
célula vazia chegam todos como `str`, e `""` é como uma célula vazia se parece, e não `None`.

**Converta na fronteira e deixe a linha ruim se nomear:**

```python
try:
    nota = int(linha["nota"])
except ValueError:
    raise ValueError(f"{caminho}:{n}: nota não é um número: {linha['nota']!r}")
```

## Os outros dialetos

`delimiter=";"` para os arquivos que o Excel escreve em boa parte da Europa, `delimiter="\t"` para
TSV. O `csv.Sniffer` adivinha, e adivinhar num arquivo que você não olhou é como um script decide
que um ponto e vírgula é dado.
