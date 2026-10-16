---
title: A página é um registro; o kernel é o estado
version: 1
---

**Um notebook parece um script que se lê de cima para baixo, e não é.** É um registro do que
aconteceu, na ordem em que aconteceu, e a ordem só fica anotada num lugar: o número entre colchetes
ao lado de cada célula. Esta aula é sobre a distância entre a página e o kernel, porque todo
notebook que "funcionava ontem" e falha hoje caiu nela.

Comece um notebook novo em `pydata` para esta aula e digite duas células:

```python
total = 0
```

```python
total = total + 10
total
```
```
10
```

Rode a primeira, depois a segunda. A página mostra `[1]` e `[2]` ao lado delas e `10` embaixo da
segunda. Agora rode a segunda de novo, sem tocar na primeira:

```python
total = total + 10
total
```
```
20
```

**A célula não mudou e a resposta mudou.** O kernel guardou `total` da execução anterior e somou
a ele, então o mesmo código dá `20`, depois `30`, e o colchete sobe para `[3]`, `[4]`. Um script
rodado duas vezes começa do nada nas duas; uma célula rodada duas vezes começa de onde o kernel
ficou. Nada na página distingue as duas situações a não ser o colchete, e só se você olhar para ele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"À esquerda, a página: duas células, a primeira marcada 1 e a segunda marcada 3 com a saída 20 embaixo. À direita, o histórico do kernel: a execução 1 põe total em 0, a 2 soma 10 e deixa 10, a 3 soma 10 de novo e deixa 20.\" data-fig=\"record\"><defs><marker id=\"record-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a página</text><text x=\"530\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o kernel, execução a execução</text><rect x=\"40\" y=\"45\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">total = 0</text><text x=\"24\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[1]</text><rect x=\"40\" y=\"110\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">total = total + 10</text><text x=\"24\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[3]</text><text x=\"170\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">20</text><text x=\"170\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só a última saída fica</text><rect x=\"400\" y=\"45\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">total = 0</text><text x=\"388\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"640\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">total</text><text x=\"690\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0</text><rect x=\"400\" y=\"107\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">total + 10</text><text x=\"388\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"640\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">total</text><text x=\"690\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">10</text><rect x=\"400\" y=\"169\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">total + 10</text><text x=\"388\" y=\"192\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"640\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">total</text><text x=\"690\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">20</text><line x1=\"300\" y1=\"68\" x2=\"374\" y2=\"68\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#record-ah)\"></line><line x1=\"300\" y1=\"130\" x2=\"374\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#record-ah)\"></line><line x1=\"300\" y1=\"145\" x2=\"374\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#record-ah)\"></line></svg>", "caption": "A página guarda a última saída de cada célula. Só o kernel sabe que a segunda rodou duas vezes."}
```

## O contador de execução é a única testemunha

Cada vez que o kernel termina uma célula ele incrementa um contador, e o JupyterLab escreve esse
número ao lado da célula. Daí saem três coisas, e vale lê-las num notebook antes de confiar nele:

- **Contadores que sobem de um em um página abaixo**, de `[1]` a `[n]`, querem dizer que ele rodou
  uma vez, de cima para baixo, num só kernel. Esse notebook diz o que parece dizer.
- **Um contador maior que os vizinhos**, `[1]`, `[2]`, `[9]`, quer dizer que uma célula rodou de
  novo depois, e tudo abaixo dela pode ter visto um estado diferente do de cima.
- **Uma célula sem contador** nunca rodou neste kernel, e a saída dela, se houver, é de uma sessão
  anterior.

O kernel também guarda a entrada de cada célula, em ordem, e esse é o histórico verdadeiro. No
IPython a lista se chama `In`, e a próxima célula pede a ela as três entradas mais recentes:

```python
In[-4:-1]
```

```
['total = 0', 'total = total + 10\ntotal', 'total = total + 10\ntotal']
```

Isso é o que aconteceu, ao contrário do que a página mostra: uma atribuição, e depois a mesma soma
duas vezes. O resto desta aula pega essa diferença e a faz dar errado de cada um dos jeitos em que
ela dá errado na prática.
