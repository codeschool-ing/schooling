---
title: Cópias que só são feitas quando alguém escreve
version: 1
---

A seção 03 prometeu que copiar uma struct é barato mesmo quando ela guarda um array de mil sessões.
**A cópia é real no que você consegue observar e adiada no que a máquina faz.** Um array guarda os
elementos num buffer de memória em outro lugar, e uma atribuição copia só a pequena struct que aponta
para o buffer. Os dois arrays então compartilham um buffer até um deles ser alterado, e essa
alteração é o momento em que os elementos são copiados. Isso se chama **copy-on-write**, cópia na
escrita, e dá para ver acontecendo perguntando a cada array onde está o seu buffer:

```swift
// Cow.swift
func buffer(_ array: [Int]) -> UnsafeRawPointer {
    array.withUnsafeBufferPointer { UnsafeRawPointer($0.baseAddress!) }
}
let week = [45, 30, 60]
var copy = week
print("after the assignment, same buffer:", buffer(week) == buffer(copy))
copy.append(90)
print("after the append, same buffer:", buffer(week) == buffer(copy))
print(week, copy)
```

```
ana@vm:~/sw/l05$ swift Cow.swift
after the assignment, same buffer: true
after the append, same buffer: false
[45, 30, 60] [45, 30, 60, 90]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l05-cow\" aria-label=\"Duas etapas. Primeiro, depois de var copy = week, os arrays week e copy apontam para um único buffer com 45, 30, 60. Depois, após copy.append(90), week ainda aponta para o buffer antigo e copy aponta para um novo com 45, 30, 60, 90.\"><defs><marker id=\"l05-cow-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l05-cow-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"170\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">depois de var copy = week</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">depois de copy.append(90)</text><path d=\"M355 10 L355 210\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"30\" y=\"50\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">week</text><path d=\"M110 65 L198 95\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-cow-ah)\"></path><rect x=\"30\" y=\"110\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">copy</text><path d=\"M110 125 L198 95\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-cow-ah)\"></path><rect x=\"200\" y=\"78\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[45, 30, 60]</text><text x=\"170\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">um buffer, dois arrays</text><rect x=\"390\" y=\"50\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">week</text><path d=\"M470 65 L528 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-cow-ah)\"></path><rect x=\"530\" y=\"48\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"605\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[45, 30, 60]</text><rect x=\"390\" y=\"110\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">copy</text><path d=\"M470 125 L528 125\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-cow-ah2)\"></path><rect x=\"530\" y=\"108\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"605\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[45, 30, 60, 90]</text><text x=\"540\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a escrita o copiou antes</text></svg>", "caption": "Uma atribuição compartilha o buffer; a primeira escrita num buffer compartilhado o copia, e só o array que escreveu fica com o novo."}
```

O `withUnsafeBufferPointer` lhe empresta o endereço dos elementos de um array pela duração de uma
closure, e a palavra `Unsafe` no nome dele é um aviso para levar a sério: nada neste curso precisa
dele além desta medida. O que importa é a resposta. **Um buffer depois da atribuição, dois depois do
append**, e o original ficou com os seus três elementos. Arrays, dicionários, conjuntos e strings
funcionam todos assim, então passar um grande para uma função não custa nada até alguém escrever
nele.

## A sua struct ganha isso de graça, quase sempre

Uma struct cujas propriedades são arrays e strings herda o comportamento deles: copiá-la copia
algumas referências a buffers, e os buffers são copiados quando alguém escreve. Uma struct sua que
guarda uma instância de **classe** não herda, porque a classe é compartilhada e nada a copia. A
biblioteca padrão lhe dá a ferramenta para construir o copy-on-write você mesmo,
`isKnownUniquelyReferenced`, que responde se uma instância de classe tem exatamente uma referência
para ela:

```swift
// Unique.swift
final class Storage {
    var minutes: [Int] = []
}
struct Log {
    var storage = Storage()
    mutating func add(_ session: Int) {
        if !isKnownUniquelyReferenced(&storage) {
            print("shared, copying before writing")
            let fresh = Storage()
            fresh.minutes = storage.minutes
            storage = fresh
        }
        storage.minutes.append(session)
    }
}
var monday = Log()
monday.add(45)
var tuesday = monday
tuesday.add(30)
print(monday.storage.minutes, tuesday.storage.minutes)
```

```
ana@vm:~/sw/l05$ swift Unique.swift
shared, copying before writing
[45] [45, 30]
```

O primeiro `add` encontrou o armazenamento sem compartilhamento e escreveu no lugar. Depois de
`tuesday = monday`, dois valores `Log` seguravam um único `Storage`, então o segundo `add` o copiou
primeiro, e `monday` ficou com a sua única sessão. **Sem a verificação, `tuesday.add(30)` teria
mudado `monday` também**: uma struct com uma classe dentro se comporta como classe, a menos que
alguém tenha escrito isto. Você raramente vai escrever, porque os arrays já fazem; vale reconhecer
quando um tipo de uma biblioteca se documenta como copy-on-write.
