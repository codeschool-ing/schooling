---
title: Leia de baixo para cima
version: 1
---

Esta é a seção mais útil da aula e possivelmente da primeira metade do curso.

Quando o Python não consegue fazer o que uma linha diz, ele para e imprime um **traceback**. Parece
um muro. São quatro fatos numa ordem fixa, e a ordem está de cabeça para baixo de propósito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"As cinco linhas de um traceback com a ordem de leitura. A última linha é a primeira a ler: ela diz o que aconteceu. A linha acima do código diz onde. A linha do topo é a cadeia de chamadas que levou até ali e, num programa de um arquivo, não diz nada de que você precise.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <rect x=\"20\" y=\"24\" width=\"420\" height=\"134\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"32\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">Traceback (most recent call last):</text> <text x=\"32\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">  File &quot;/home/ada/greet.py&quot;, line 2, in &lt;module&gt;</text> <text x=\"32\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">    greeting = &quot;Hello, &quot; + nmae</text> <text x=\"32\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\" xml:space=\"preserve\">                           ^^^^</text> <text x=\"32\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\" xml:space=\"preserve\">NameError: name 'nmae' is not defined</text> <text x=\"486\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">terceiro — como chegou ali</text> <path d=\"M480 44 L452 44\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"486\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">segundo — qual arquivo e qual linha</text> <path d=\"M480 68 L452 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"486\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">primeiro — o que de fato aconteceu</text> <path d=\"M480 140 L452 140\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Num programa de um arquivo o topo tem uma linha só e dá para ignorar.</text> </svg>", "caption": "Três perguntas, respondidas de baixo para cima — por isso a linha mais útil é a que fica mais perto do cursor."}
```

```
Traceback (most recent call last):
  File "/home/ada/greet.py", line 2, in <module>
    greeting = "Hello, " + nmae
                           ^^^^
NameError: name 'nmae' is not defined
```

## A última linha primeiro: o que aconteceu

`NameError: name 'nmae' is not defined`

Duas metades. **`NameError`** é o tipo da falha — uma de talvez uma dúzia que você vai encontrar no
primeiro mês, e a aula 8 nomeia todas. **O texto depois dos dois pontos** é a queixa específica,
escrita para uma pessoa.

## A penúltima: onde

`File "/home/ada/greet.py", line 2` — o arquivo e a linha em que o interpretador estava. Depois a
própria linha, devolvida entre aspas, com `^^^^` embaixo da parte que ele não conseguiu resolver.

Esse circunflexo faz trabalho de verdade. Numa linha longa com quatro chamadas de função, ele diz
qual delas.

## O topo: como chegou ali

`Traceback (most recent call last)` quer dizer o que está escrito: a lista acima do erro é a cadeia
de chamadas que levou até aqui, **da mais antiga para a mais recente**. Num programa de um arquivo é
uma linha só e dá para ignorar. Quando o seu programa tem funções chamando funções, é essa parte que
conta o caminho.

## Por que de cabeça para baixo

Porque a última linha é a resposta, e a resposta deve estar perto de onde o seu olho já está — no pé
do terminal, onde você acabou de apertar Enter.

## Os quatro desta semana

| | quer dizer |
|---|---|
| `NameError` | você usou uma palavra para a qual o Python não tem significado — quase sempre um erro de digitação, às vezes um import faltando |
| `SyntaxError` | o arquivo não pôde ser lido de jeito nenhum; nada rodou |
| `TypeError` | a operação existe, mas não para estes tipos — `"2" + 2` |
| `IndentationError` | os espaços no começo de uma linha não se alinham |

**O `SyntaxError` é o diferente**, e vale saber por quê: os outros acontecem enquanto o seu programa
roda, então tudo acima da linha que falhou já aconteceu. Um `SyntaxError` acontece *antes* de
qualquer coisa rodar, porque o interpretador não conseguiu terminar de ler o arquivo. Se você vê um,
nenhuma parte do seu programa executou — nem o `print` da linha 1.
