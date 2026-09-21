---
title: Os três que não levantam erro
version: 1
---

Cada um destes produz uma resposta errada em vez de um erro, que é o que os torna dignos de uma
seção.

## Alterar uma lista enquanto a itera

```python
>>> xs = [1, 2, 4, 3]
>>> for x in xs:
...     if x % 2 == 0:
...         xs.remove(x)
>>> xs
[1, 4, 3]
```

O `4` sobreviveu — um número par, numa lista que não devia ter sobrado nenhum. O laço guarda a
própria posição, e não uma cópia da lista: remover o `2` deslizou o `4` de volta para a posição 1,
que o laço já tinha passado, então a posição 2 tinha o `3`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Um laço sobre uma lista da qual ele também remove. O laço guarda a própria posição: remover o dois desliza o quatro de volta para a posição um, que o laço já passou, então o quatro nunca é testado e um número par sobrevive.\"> <text x=\"102\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o cursor</text> <rect x=\"110\" y=\"34\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"133\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text> <rect x=\"162\" y=\"34\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">2</text> <rect x=\"214\" y=\"34\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"237\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">4</text> <rect x=\"266\" y=\"34\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"289\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">3</text> <rect x=\"110\" y=\"70\" width=\"46\" height=\"3\" rx=\"1\" fill=\"var(--amber)\"></rect> <text x=\"340\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">1 é ímpar, então fica</text> <rect x=\"110\" y=\"84\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"133\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text> <rect x=\"162\" y=\"84\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"185\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">2</text> <rect x=\"214\" y=\"84\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"237\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">4</text> <rect x=\"266\" y=\"84\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"289\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">3</text> <rect x=\"162\" y=\"120\" width=\"46\" height=\"3\" rx=\"1\" fill=\"var(--amber)\"></rect> <text x=\"340\" y=\"100\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">2 é par, então sai</text> <rect x=\"110\" y=\"134\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"133\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text> <rect x=\"162\" y=\"134\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">4</text> <rect x=\"214\" y=\"134\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"237\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">3</text> <rect x=\"214\" y=\"170\" width=\"46\" height=\"3\" rx=\"1\" fill=\"var(--amber)\"></rect> <text x=\"340\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o 4 voltou para trás do cursor, então a posição 2 é o 3</text> <rect x=\"110\" y=\"184\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"133\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text> <rect x=\"162\" y=\"184\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">4</text> <rect x=\"214\" y=\"184\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"237\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">3</text> <text x=\"289\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">x</text> <text x=\"340\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a posição 3 passou do fim, então o laço para</text> <text x=\"360\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">xs é [1, 4, 3], e o 4 nunca foi olhado</text> </svg>", "caption": "O laço conta posições e a lista se move debaixo dele. Nada levanta erro, e sai um número par de um laço escrito para removê-los."}
```

**Itere uma cópia, ou construa uma lista nova:**

```python
xs = [x for x in xs if x % 2 != 0]      # a resposta de sempre
for x in xs[:]:                          # ou itere uma cópia
```

O mesmo vale para um dicionário — mudar o tamanho dele durante a iteração levanta `RuntimeError`, o
que ao menos é barulhento.

## O erro de um a mais

```python
for i in range(1, len(itens)):    # pula itens[0]
for i in range(len(itens) + 1):   # IndexError na última volta
```

Os dois vêm de calcular um índice. **`for item in itens` não tem como errar por um**, e o `enumerate`
também não.

## A variável que sobrevive ao laço

```python
for item in itens:
    ...
print(item)        # o último — ou NameError se itens estava vazia
```

O Python não tem escopo de bloco: a variável do laço permanece depois dele, guardando o que tinha por
último. Lê-la de propósito é legítimo e raro; lê-la sem querer é um defeito que funciona com toda
entrada não vazia e levanta erro com a vazia.

## E um que levanta, mais cedo ou mais tarde

```python
total = 0
for linha in linhas:
    total += linha["valor"]
```

Correto — até uma linha não ter `valor`. `linha.get("valor", 0)` é a decisão de tratar isso como
zero, dita em voz alta. A aula 8 é a outra resposta: capturar e dizer qual linha.
