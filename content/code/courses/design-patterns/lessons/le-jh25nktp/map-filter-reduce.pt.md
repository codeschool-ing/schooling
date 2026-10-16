---
title: Map, filter, reduce, e a compreensão
version: 1
---

**A maioria dos laços sobre uma coleção faz uma de três coisas: guarda alguns itens, transforma cada
item, ou combina todos num valor só.** A programação funcional dá nome a cada uma, `filter`, `map` e
`reduce`, para que quem lê veja qual delas está acontecendo sem seguir o corpo do laço. O Python
acrescenta uma quarta grafia, a compreensão (*comprehension*), que na prática é a que a maior parte
do código Python usa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l15-pipeline\" aria-label=\"As multas de março como um encadeamento, da esquerda para a direita. Quatro empréstimos entram em filter, que mantém os que têm mais de zero dias de atraso: o primeiro livro da Bia, o filme do Caio e o filme da Duda; o segundo livro da Bia, devolvido antes, cai fora. Map transforma cada um dos três numa multa: 200, 750 e 200 centavos. Reduce soma tudo num valor só, 1150.\"><defs><marker id=\"l15-pipeline-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Bia, 4 dias</text><rect x=\"20.0\" y=\"85.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Caio, 15 dias</text><rect x=\"20.0\" y=\"130.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Bia, 0 dias</text><rect x=\"20.0\" y=\"175.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Duda, 4 dias</text><text x=\"80.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">4 empréstimos</text><rect x=\"173.0\" y=\"40.0\" width=\"104.0\" height=\"165.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--scan)\" stroke-width=\"1.2\"></rect><text x=\"225.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">filter</text><text x=\"225.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">days &gt; 0</text><path d=\"M140.0 55.0 L173.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M140.0 100.0 L173.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M140.0 145.0 L173.0 145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M140.0 190.0 L173.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M277.0 55.0 L305.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><rect x=\"307.0\" y=\"40.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"363.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Bia, 4 dias</text><path d=\"M277.0 100.0 L305.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><rect x=\"307.0\" y=\"85.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"363.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Caio, 15 dias</text><path d=\"M277.0 190.0 L305.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><rect x=\"307.0\" y=\"175.0\" width=\"112.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"363.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Duda, 4 dias</text><text x=\"225.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a devolução antecipada cai fora</text><rect x=\"438.0\" y=\"40.0\" width=\"104.0\" height=\"165.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--scan)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">map</text><text x=\"490.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">days * 50</text><path d=\"M419.0 55.0 L438.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M419.0 100.0 L438.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M419.0 190.0 L438.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><path d=\"M542.0 55.0 L560.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><rect x=\"562.0\" y=\"42.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><path d=\"M542.0 100.0 L560.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><rect x=\"562.0\" y=\"87.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">750</text><path d=\"M542.0 190.0 L560.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><rect x=\"562.0\" y=\"177.0\" width=\"46.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><path d=\"M608.0 122.0 L628.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l15-pipeline-dp-ah-paper-dim)\"></path><text x=\"580.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">3 multas, em centavos</text><rect x=\"630.0\" y=\"95.0\" width=\"76.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"668.0\" y=\"115.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">reduce +</text><text x=\"668.0\" y=\"128.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1150</text><path d=\"M608.0 55.0 L608.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "Cada etapa é uma função pura do que a anterior produziu, e cada uma pode ser lida e testada sozinha."}
```

## O mesmo total, de três jeitos

O total das multas de março, os 1.150 centavos do relatório da lição 14, escrito como laço, como uma
cadeia das três funções e como compreensão:

```schooling-example
{"language": "python", "file": "mfr.py", "parts": [
 {"code": "# mfr.py\nfrom datetime import date\nfrom functools import reduce\n\nTODAY = date(2026, 3, 31)\nLOANS = [(\"Bia\", date(2026, 3, 16), date(2026, 3, 20)),\n         (\"Caio\", date(2026, 3, 16), None),\n         (\"Bia\", date(2026, 3, 24), date(2026, 3, 21)),\n         (\"Duda\", date(2026, 3, 8), date(2026, 3, 12))]", "note": "Membro, data de vencimento e data de devolução. O filme do Caio ainda está fora; o segundo livro da Bia voltou antes."},
 {"code": "\n\ndef days_late(loan: tuple) -> int:\n    _, due, returned = loan\n    return max(((returned or TODAY) - due).days, 0)", "note": "Uma função pura do empréstimo, usada pelas três versões."},
 {"code": "\n\ntotal = 0\nfor loan in LOANS:\n    if days_late(loan) > 0:\n        total += days_late(loan) * 50\nprint(\"loop:\", total)", "note": "O laço faz os três trabalhos num corpo só: o `if` filtra, a multiplicação mapeia e `total +=` reduz."},
 {"code": "\nlate = filter(lambda loan: days_late(loan) > 0, LOANS)\nfines = map(lambda loan: days_late(loan) * 50, late)\nprint(\"filter, map, reduce:\", reduce(lambda a, b: a + b, fines, 0))\nprint(\"the same map, asked again:\", list(fines))", "note": "Cada trabalho com nome. `reduce` começa do 0 e dobra cada multa no total acumulado. A última linha pede as multas uma segunda vez."},
 {"code": "\nprint(\"comprehension:\", sum(days_late(loan) * 50 for loan in LOANS if days_late(loan) > 0))", "note": "A grafia do Python: o `if` no fim filtra, a expressão no começo mapeia, e `sum` é o reduce de que todo mundo precisa."}
]}
```

```
ana@laptop:~/patterns/functional$ python3 mfr.py
loop: 1150
filter, map, reduce: 1150
the same map, asked again: []
comprehension: 1150
```

As três concordam em 1150. A linha do meio é a surpresa: pedidas uma segunda vez, as multas são uma
lista vazia.

## Preguiçoso, e gasto

No Python 3, `map` e `filter` devolvem **iteradores**, não listas. Nada é calculado quando `late` e
`fines` são criados; cada multa é calculada quando `reduce` a pede, e quando `reduce` chega ao fim,
o iterador está esgotado. Pedir de novo não dá nada, em silêncio. A compreensão dentro de `sum(...)`
é uma expressão geradora e se comporta do mesmo jeito.

A preguiça é útil: um encadeamento sobre um milhão de linhas segura uma linha por vez, e um
encadeamento que nunca é consumido não custa nada. Também é a surpresa mais comum quando alguém que
vem do JavaScript, onde `array.map` devolve um array novo, escreve Python. Se você precisa dos
valores duas vezes, faça uma lista uma vez: `fines = list(map(...))`.

| linguagem | map e filter devolvem | reduce |
|---|---|---|
| Python | iteradores preguiçosos (`map`, `filter`, expressões geradoras) | `functools.reduce`, ou `sum`, `max`, `any`... |
| JavaScript e TypeScript | arrays novos, calculados na hora | `array.reduce(fn, start)` |
| Java | `Stream`s preguiçosos, consumidos uma vez como os iteradores do Python | `stream.reduce(start, fn)`, ou coletores |
| Go | nada embutido antes dos genéricos; pacotes `slices` e `maps` desde a 1.21, iteradores desde a 1.23 | um laço |

## Qual escrever

Guido van Rossum tirou o `reduce` dos embutidos e o pôs em `functools` no Python 3, argumentando que
um laço com acumulador costuma ser mais claro que uma lambda de dois argumentos. A maior parte do
estilo Python o segue. **Prefira a compreensão para map e filter, e uma redução com nome (`sum`,
`max`, `min`, `any`, `all`, `"".join`) para reduce.** Use `map` quando já tiver uma função com nome,
como em `map(str.upper, titles)`, e `reduce` quando o passo de combinação for uma função de verdade
com nome, como o `pipeline` da seção anterior.

O que vale em toda linguagem é o hábito de enxergar os três trabalhos. Um corpo de laço que filtra,
transforma, acumula e ainda registra log e atualiza um contador está fazendo quatro coisas num lugar
só; dividi-lo num filter, num map e numa soma torna cada passo uma função pura que pode ser testada e
reaproveitada sozinha.
