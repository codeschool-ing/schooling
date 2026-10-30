---
title: Uma classe é compartilhada
version: 1
---

O mesmo programa com `class` no lugar de `struct` dá números diferentes, e a diferença é o ponto
todo. **Uma variável de classe guarda uma referência**, um endereço onde a instância mora, e
atribuí-la copia o endereço. Dois nomes passam então a alcançar uma instância, e uma mudança feita
por qualquer um deles é vista pelos dois:

```swift
// Shares.swift
final class StudySession {
    var course: String
    var minutes: Int
    init(course: String, minutes: Int) {
        self.course = course
        self.minutes = minutes
    }
}
let monday = StudySession(course: "Swift", minutes: 45)
let tuesday = monday
tuesday.minutes = 60
print(monday.minutes, tuesday.minutes)

func extend(_ session: StudySession) {
    session.minutes += 15
}
extend(monday)
print(monday.minutes, tuesday.minutes)

let week = [monday, tuesday]
week[0].minutes = 0
print(monday.minutes, tuesday.minutes, week[1].minutes)
```

```
ana@vm:~/sw/l05$ swift Shares.swift
60 60
75 75
0 0 0
```

**Todo número de toda linha é igual**, porque só houve uma sessão. `tuesday = monday` criou um
segundo nome para ela, não uma segunda sessão. A função `extend` recebeu a referência, e mudar a
instância por ela mudou a instância de quem chamou, sem `inout` e sem `&` para avisar quem lê. O
array guarda duas referências àquela única instância, então zerar os minutos do primeiro elemento
zerou também os do segundo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l05-value-reference\" aria-label=\"Dois painéis. À esquerda, uma struct: monday e tuesday são duas caixas separadas, uma com minutes 45 e outra com minutes 60, porque a atribuição copiou o valor. À direita, uma classe: monday e tuesday são duas etiquetas com setas para uma única caixa compartilhada com minutes 60, porque a atribuição copiou a referência.\"><defs><marker id=\"l05-vr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">tipo de valor: struct</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">tipo de referência: class</text><path d=\"M355 12 L355 248\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40\" y=\"60\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">monday</text><rect x=\"54\" y=\"98\" width=\"92\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">minutes: 45</text><rect x=\"200\" y=\"60\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tuesday</text><rect x=\"214\" y=\"98\" width=\"92\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"260\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">minutes: 60</text><text x=\"170\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tuesday = monday copia o valor</text><text x=\"170\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">dois valores, cada um muda sozinho</text><rect x=\"390\" y=\"60\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"440\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">monday</text><path d=\"M490 75 L578 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-vr-ah)\"></path><rect x=\"390\" y=\"112\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"440\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tuesday</text><path d=\"M490 127 L578 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-vr-ah)\"></path><rect x=\"580\" y=\"76\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">minutes: 60</text><text x=\"540\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tuesday = monday copia a referência</text><text x=\"540\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">dois nomes, uma instância no heap</text></svg>", "caption": "A atribuição copia o que o nome guarda. Um nome de struct guarda o valor, então a cópia é um segundo valor; um nome de classe guarda uma referência, então a cópia é um segundo caminho até a mesma instância."}
```

## Aqui `let` quer dizer menos

`monday`, `tuesday` e `week` são todos `let`, e o programa mudou minutos por cada um deles. Não é
contradição. **Para uma classe, `let` prende a referência, não a instância**: `monday` vai sempre
apontar para a mesma sessão, e as propriedades `var` dessa sessão ainda podem mudar. A aula 1 disse
que `let` e imutabilidade coincidem para números e textos; para uma classe elas se separam.
`monday = StudySession(course: "Kotlin", minutes: 30)` seria recusado, porque isso muda a referência.

## Quando compartilhar é o que você quer

Compartilhar não é defeito. Uma tela do planner e uma tela de estatísticas que devem mostrar os
minutos de uma sessão, e ver uma mudança ao mesmo tempo, querem exatamente uma sessão entre elas, e
uma classe lhes dá isso. O custo é o que este programa mostra: qualquer código que segure a
referência pode mudar o que todos os outros veem, a qualquer momento, e quem lê uma linha não
consegue saber. A seção 08 pesa os dois.
