---
title: Geradores ponta com ponta
version: 2
---

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def lines(path):\n    with open(path, encoding=\"utf-8\") as f:\n        for line in f:\n            yield line.rstrip(\"\\n\")",
      "note": "**O `lines` produz.** Abre o arquivo e produz uma linha por vez, sem a quebra de linha."
    },
    {
      "code": "def errors(lines):\n    for line in lines:\n        if \" ERROR \" in line:\n            yield line",
      "note": "**O `errors` filtra.** Entram linhas e saem só as linhas de erro."
    },
    {
      "code": "def durations(lines):\n    for line in lines:\n        m = DURATION.search(line)\n        if m:\n            yield int(m[\"ms\"])",
      "note": "**O `durations` transforma.** Cada linha que o padrão `DURATION` casa vira um inteiro, os milissegundos que ele capturou, e as linhas que ele não casa ficam de fora."
    },
    {
      "code": "total = sum(durations(errors(lines(path))))",
      "note": "**O `sum` consome**, e é o único estágio que pede alguma coisa."
    }
  ]
}
```

Quatro estágios, um valor por vez, do começo ao fim. Nada é construído em lugar nenhum, e a coisa
toda custa a memória de uma linha, seja qual for o arquivo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 252\" role=\"img\" aria-label=\"A versão ansiosa constrói uma lista inteira em cada estágio, então um arquivo de um milhão de linhas fica na memória três vezes. A versão preguiçosa passa um valor pelos quatro estágios e guarda uma linha por vez, seja qual for o tamanho do arquivo.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">listas o tempo todo — três cópias inteiras</text> <rect x=\"14\" y=\"34\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"84\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">lines</text> <rect x=\"198\" y=\"34\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"268\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">errors</text> <rect x=\"169\" y=\"38\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <rect x=\"169\" y=\"45\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <rect x=\"169\" y=\"52\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <path d=\"M164 62 L190 62\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"382\" y=\"34\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"452\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">durations</text> <rect x=\"353\" y=\"38\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <rect x=\"353\" y=\"45\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <rect x=\"353\" y=\"52\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <path d=\"M348 62 L374 62\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"566\" y=\"34\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"636\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sum</text> <rect x=\"537\" y=\"38\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <rect x=\"537\" y=\"45\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <rect x=\"537\" y=\"52\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect> <path d=\"M532 62 L558 62\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"20\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">uma lista inteira entre cada par — o arquivo, três vezes</text> <text x=\"20\" y=\"128\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">geradoras o tempo todo — um valor por vez</text> <rect x=\"14\" y=\"138\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"84\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">lines</text> <rect x=\"198\" y=\"138\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"268\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">errors</text> <rect x=\"169\" y=\"142\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--phosphor)\"></rect> <path d=\"M164 166 L190 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"382\" y=\"138\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"452\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">durations</text> <rect x=\"353\" y=\"142\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--phosphor)\"></rect> <path d=\"M348 166 L374 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"566\" y=\"138\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"636\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sum</text> <rect x=\"537\" y=\"142\" width=\"14\" height=\"4\" rx=\"1\" fill=\"var(--phosphor)\"></rect> <path d=\"M532 166 L558 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"20\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">um valor entre cada par — uma linha, seja qual for o peso do arquivo</text> </svg>", "caption": "Os mesmos quatro estágios, a mesma resposta. Um deles custa o arquivo e o outro custa uma linha."}
```

## Leia de dentro para fora, ou de baixo para cima

**O `errors` e o `durations` recebem um iterável e produzem outro**, que é o que os torna componíveis em qualquer ordem que
faça sentido.

Este é o pipeline do `linux-terminal` num processo só — `grep` e depois `sed` e depois `awk`, com
a mesma propriedade: nenhum estágio espera o anterior terminar.

## Nada roda até a última linha

As três chamadas constroem três objetos geradores e não fazem nada. O `sum` puxa, que puxa, que
puxa, que lê uma linha do arquivo. **Tire o `sum` e o arquivo nunca é aberto.**

## Onde pôr a leitura

```python
def durations(lines):        # takes lines, not a path
```

Cada estágio recebe um ITERÁVEL em vez de um nome de arquivo, que é o que o torna testável com uma
lista de três strings e reaproveitável em outra fonte. Só o primeiro estágio sabe de um arquivo.

## E onde a preguiça acaba

```python
top = sorted(durations(errors(lines(path))), reverse=True)[:10]
```

O `sorted` precisa de tudo, então isto guarda toda duração em memória — os inteiros, e não as
linhas, o que em geral está bem. O `heapq.nlargest(10, …)` é a versão que guarda dez.

**Saber qual linha do seu pipeline é a que acumula** é a habilidade prática aqui, e quase sempre é
a ordenação.
