---
title: Dois decoradores, e duas ordens diferentes
version: 1
---

```python
@cronometrado
@repetir(vezes=3)
def buscar(url):
    ...
```

é

```python
buscar = cronometrado(repetir(vezes=3)(buscar))
```

**Eles se APLICAM de baixo para cima**: o mais perto do `def` envolve primeiro, e o de cima envolve
aquele.

**Eles RODAM de cima para baixo**: uma chamada entra no wrapper do `cronometrado`, que chama o
wrapper do `repetir`, que chama o `buscar`.

Essas são duas ordens diferentes, e as duas estão corretas ao mesmo tempo — o wrapper mais de fora
é o último aplicado e o primeiro em que se entra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Decoradores empilhados se aplicam de baixo para cima, então o mais perto do def envolve primeiro e acaba mais por dentro. Uma chamada então roda de cima para baixo, entrando primeiro no wrapper mais de fora. O último aplicado é o primeiro em que se entra.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <text x=\"182\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">aplicados, de baixo para cima</text> <rect x=\"20\" y=\"36\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">buscar</text> <rect x=\"20\" y=\"94\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">repetir(vezes=3)</text> <path d=\"M182 76 L182 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"20\" y=\"152\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">cronometrado</text> <path d=\"M182 134 L182 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"558\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">entrados, de cima para baixo</text> <rect x=\"396\" y=\"36\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">cronometrado</text> <rect x=\"396\" y=\"94\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">repetir(vezes=3)</text> <path d=\"M558 76 L558 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"396\" y=\"152\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">buscar</text> <path d=\"M558 134 L558 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"360\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Com o cronometrado em cima ele mede as três tentativas; com o repetir em cima, uma.</text> <text x=\"360\" y=\"239\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">As mesmas duas linhas, trocadas, e o número no painel quer dizer outra coisa.</text> </svg>", "caption": "Duas ordens, as duas verdadeiras ao mesmo tempo — e é por isso que trocar as duas linhas muda o que o cronômetro mede."}
```

## E é por isso que a ordem importa

```python
@cronometrado
@repetir(vezes=3)     # a cronometragem mede as três tentativas

@repetir(vezes=3)
@cronometrado         # a cronometragem mede cada tentativa em separado
```

Os mesmos dois decoradores, sentidos diferentes. Nenhum está errado; eles respondem perguntas
diferentes, e a pilha é onde a resposta é decidida.

## A que está sempre errada

```python
@app.route("/linhas")
@exige_login
def linhas(): ...
```

contra

```python
@exige_login
@app.route("/linhas")     # o framework registrou a função DESPROTEGIDA
def linhas(): ...
```

Um decorador que REGISTRA a função precisa ser o mais de fora, porque ele registra o que lhe for
entregue — e o que lhe é entregue é o que estiver abaixo dele. A segunda versão protege uma função
que ninguém chama e serve uma que não está protegida.

**Essa é uma forma de defeito real em código web**, e ela é silenciosa.

## E o conselho

Dois é uma pilha que alguém consegue ler. Três é uma pilha que alguém vai errar. Se a ordem importa
e não é óbvia, um comentário ao lado custa uma linha — e um decorador único que faz as duas coisas
costuma ser a resposta honesta.
