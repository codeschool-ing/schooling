---
title: O que uma closure captura
version: 1
---

Uma closure pode usar nomes do lugar onde foi escrita. Parece óbvio até você notar que **a closure
pode rodar depois que esse lugar deixou de existir**. O Swift mantém vivo o que a closure usa enquanto
a closure viver. Isso se chama **captura**, e tem consequências para o que a closure enxerga.

## Um contador que sobrevive à sua função

```swift
// Counter.swift
func makeCounter() -> () -> Int {
    var count = 0
    return {
        count += 1
        return count
    }
}
let next = makeCounter()
print(next(), next(), next())
let other = makeCounter()
print(other())
```

```
ana@vm:~/sw/l03$ swift Counter.swift
1 2 3
1
```

`makeCounter` retornou, e o `count` local normalmente teria sumido com ela. Em vez disso a closure o
capturou, então cada chamada a `next` encontra o mesmo `count` e soma um. `other` veio de uma segunda
chamada a `makeCounter`, então capturou um segundo `count`, e é por isso que recomeça do 1.

## Capturado por referência, a menos que você diga o contrário

Uma closure captura a **variável**, não o valor que ela tinha quando a closure foi escrita. Uma lista
de captura, entre colchetes antes dos parâmetros, copia o valor naquele momento:

```swift
// CaptureList.swift
var goal = 300
let report = { print("goal \(goal)") }
let fixed = { [goal] in print("fixed \(goal)") }
goal = 360
report()
fixed()
```

```
ana@vm:~/sw/l03$ swift CaptureList.swift
goal 360
fixed 300
```

As duas closures foram escritas quando `goal` valia 300. `report` capturou a variável e leu 360 quando
finalmente rodou; `fixed` copiou 300 na lista de captura e o manteve. **Qual você quer depende de para
que serve a closure**: um relatório deve mostrar a meta de hoje, e o registro de qual era a meta quando
uma sessão começou não deve mudar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l03-capture\" aria-label=\"À esquerda: duas closures devolvidas por duas chamadas a makeCounter. next aponta para a própria variável capturada count, agora 3; other aponta para outro count, agora 1. À direita: uma variável goal valendo 360. A closure report aponta para a variável e lê 360 quando roda. A closure fixed guarda sua própria cópia, 300, feita quando foi escrita.\"><defs><marker id=\"l03-capture-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"170\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">duas chamadas, duas variáveis</text><rect x=\"30\" y=\"60\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">next</text><line x1=\"140\" y1=\"82\" x2=\"205\" y2=\"82\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l03-capture-ah-phosphor)\"></line><rect x=\"210\" y=\"60\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"265\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">count</text><text x=\"265\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">3</text><text x=\"265\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">capturado</text><rect x=\"30\" y=\"150\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">other</text><line x1=\"140\" y1=\"172\" x2=\"205\" y2=\"172\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l03-capture-ah-phosphor)\"></line><rect x=\"210\" y=\"150\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"265\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">count</text><text x=\"265\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"265\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">capturado</text><line x1=\"360\" y1=\"30\" x2=\"360\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></line><rect x=\"400\" y=\"100\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"455\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">goal</text><text x=\"455\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">360</text><rect x=\"580\" y=\"50\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">report</text><line x1=\"580\" y1=\"80\" x2=\"515\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l03-capture-ah-phosphor)\"></line><text x=\"560\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a variável, lida quando roda</text><rect x=\"580\" y=\"170\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">fixed</text><rect x=\"600\" y=\"198\" width=\"70\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"635\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">300</text><text x=\"560\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma cópia, feita quando foi escrita</text></svg>", "caption": "Cada closure mantém vivo o que capturou. Uma variável é compartilhada com a closure; uma lista de captura guarda uma cópia."}
```

As listas de captura voltam na lição 11, em que `[weak self]` é o jeito de impedir que uma closure
mantenha um objeto vivo para sempre. É o motivo mais comum para escrever uma, e precisa das classes da
lição 5 antes.

## Escapando

Uma closure passada para uma função e rodada só lá dentro, como o `repeatTwice` rodou sua ação, é
**não escapável**: não pode sobreviver à chamada. Guarde-a para rodar depois e o compilador reclama:

```swift
// Escaping.swift
var handlers: [() -> Void] = []
func later(_ action: () -> Void) {
    handlers.append(action)
}
```

```
ana@vm:~/sw/l03$ swiftc Escaping.swift -o escaping
Escaping.swift:4:21: error: converting non-escaping parameter 'action' to generic parameter 'Element' may allow it to escape
2 | var handlers: [() -> Void] = []
3 | func later(_ action: () -> Void) {
4 |     handlers.append(action)
  |                     `- error: converting non-escaping parameter 'action' to generic parameter 'Element' may allow it to escape
5 | }
6 | 
```

A mensagem é prolixa, e as palavras importantes estão no fim: **"may allow it to escape"**, pode deixá-la
escapar. Pôr a closure num array que continua existindo depois que `later` retorna a deixaria escapar
da chamada. Escrever o parâmetro como `_ action: @escaping () -> Void` é como se diz que isso é
intencional, e é também um aviso a quem lê a assinatura: tudo o que essa closure captura será mantido
vivo enquanto ela estiver guardada. A lição 11 é sobre quanto isso custa.
