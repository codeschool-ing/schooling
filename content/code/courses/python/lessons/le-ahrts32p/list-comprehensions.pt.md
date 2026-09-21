---
title: `[f(x) for x in xs if p(x)]`
version: 1
---

```python
com_desconto = [preco * 0.9 for preco in precos if preco > 100]
```

Seis linhas de laço numa, e a primeira coisa que ela diz é **o que está sendo construído**.

## Lendo

A ordem em que se escreve não é a ordem em que roda:

```
[  preco * 0.9        for preco in precos      if preco > 100  ]
   o que guardar      de onde vem              quais
```

A execução vai da direita para a esquerda: pegue cada preço, teste, e se passar, avalie a expressão.
A leitura vai da esquerda para a direita, que é o que a torna legível.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 282\" role=\"img\" aria-label=\"O laço e a compreensão são as mesmas três partes em outra ordem. A expressão guardada é a última linha do laço e a primeira coisa da compreensão; a origem e o teste vêm depois dela.\"> <text x=\"20\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">o laço</text> <text x=\"52\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" xml:space=\"preserve\">com_desconto = []</text> <text x=\"52\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" xml:space=\"preserve\">for preco in precos:</text> <text x=\"52\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" xml:space=\"preserve\">    if preco &gt; 100:</text> <text x=\"52\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" xml:space=\"preserve\">        com_desconto.append(preco * 0.9)</text> <circle cx=\"32\" cy=\"68\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></circle> <text x=\"32\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text> <circle cx=\"32\" cy=\"92\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></circle> <text x=\"32\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text> <circle cx=\"32\" cy=\"116\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"32\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text> <text x=\"20\" y=\"150\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">a compreensão</text> <text x=\"52\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper-dim)\" xml:space=\"preserve\">[</text> <text x=\"61\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\" xml:space=\"preserve\">preco * 0.9</text> <text x=\"160\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\" xml:space=\"preserve\"> for preco in precos</text> <text x=\"340\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--amber)\" xml:space=\"preserve\"> if preco &gt; 100</text> <text x=\"475\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper-dim)\" xml:space=\"preserve\">]</text> <circle cx=\"110.5\" cy=\"174\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"110.5\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text> <text x=\"110.5\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o que guardar</text> <circle cx=\"250\" cy=\"174\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></circle> <text x=\"250\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text> <text x=\"250\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">de onde vem</text> <circle cx=\"407.5\" cy=\"174\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></circle> <text x=\"407.5\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text> <text x=\"407.5\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">quais</text> <text x=\"360\" y=\"248\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">A leitura vai da esquerda para a direita. A execução vai ao contrário:</text> <text x=\"360\" y=\"265\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">pegue cada preço, teste, e só então calcule a expressão.</text> </svg>", "caption": "A compreensão diz o que está sendo construído antes de dizer de onde vem. É essa troca de ordem o que ela compra."}
```

## As formas

```python
[x * 2 for x in xs]                  # mapear
[x for x in xs if x > 0]             # filtrar
[x * 2 for x in xs if x > 0]         # os dois
[y for linha in grade for y in linha]  # achatar — os laços na ordem em que você os escreveria
```

**A aninhada é a única que surpreende.** As cláusulas `for` se leem da esquerda para a direita
exatamente como comandos `for` aninhados, que é o oposto do que a maioria supõe.

## Quando ela deixa de ser mais clara

```python
# três condições e uma expressão condicional — isto é um laço
[transformar(x) if ok(x) else alternativa(x) for x in xs if a(x) and b(x)]
```

Duas regras que se sustentam:

**Se não couber numa linha, é um laço.** Não "quebre a linha" — a quebra é o sinal.

**Se você quiser fazer qualquer coisa além de construir um valor, é um laço.** Uma compreensão não
registra em log, não dá `break`, não atribui a nada fora de si. Isso é uma qualidade — é por isso que
dá para confiar no que uma delas faz numa olhada — e é também a fronteira.

## Para o que ela não serve

```python
[print(x) for x in xs]      # não
```

Isso constrói uma lista de `None` e a joga fora, pelo efeito colateral. Escreva o laço; tem o mesmo
comprimento e diz o que quer dizer.
