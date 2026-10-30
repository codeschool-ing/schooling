---
title: Uma chamada por vez, até ela aguardar
version: 1
---

A seção 03 disse que um ator roda uma chamada por vez. **A regra exata é uma chamada por vez entre
pontos de suspensão.** Quando um método de um ator chega a um `await`, ele larga o ator, e outra
chamada esperando na fila pode rodar antes que a primeira retome. Isso se chama **reentrância**, e é
uma escolha deliberada: um ator que ficasse trancado durante todo `await` ficaria parado esperando uma
rede, e dois atores esperando um pelo outro nunca mais andariam.

O custo é um bug que parece impossível. O planner reserva tempo de estudo contra um orçamento semanal
de minutos livres. Ele confere se há espaço, grava a reserva num servidor e então desconta os minutos:

```swift
// Booking.swift
actor WeekPlan {
    var free = 100

    func book(_ minutes: Int, for course: String) async -> Bool {
        guard free >= minutes else {
            print("\(course): refused, \(free) free")
            return false
        }
        await saveToServer(course)
        free -= minutes
        print("\(course): booked \(minutes), \(free) free")
        return true
    }

    func saveToServer(_ course: String) async {
        try? await Task.sleep(for: .milliseconds(100))
    }
}

let plan = WeekPlan()
async let a = plan.book(80, for: "Swift")
async let b = plan.book(80, for: "Kotlin")
_ = await (a, b)
print("free at the end: \(await plan.free)")
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Booking.swift -o booking && ./booking
Swift: booked 80, 20 free
Kotlin: booked 80, -60 free
free at the end: -60
```

**Duas reservas de 80 minutos contra 100 livres, as duas aceitas, e o orçamento em −60.** Compilou no
modo Swift 6, e não há corrida de dados nele: toda leitura e escrita de `free` aconteceu no ator, uma
por vez. O bug está na ordem. A primeira chamada conferiu `free`, achou 100 e chegou ao
`await saveToServer`, onde largou o ator. A segunda chamada rodou, conferiu `free`, ainda achou 100 e
chegou ao mesmo `await`. Cada uma então retomou e subtraiu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l15-reentrancy\" aria-label=\"Seis passos num ator, em ordem de tempo. Swift confere que 80 de 100 minutos estão livres, então aguarda o servidor e larga o ator. Kotlin confere, ainda vê 100, e também aguarda. Swift retoma e subtrai, deixando 20; Kotlin retoma e subtrai, deixando menos 60.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">no ator, em ordem de tempo</text><text x=\"30\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"50\" y=\"50\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Swift</text><rect x=\"150\" y=\"50\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">free &gt;= 80?  100</text><text x=\"395\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">confere</text><text x=\"30\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"50\" y=\"81\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Swift</text><rect x=\"150\" y=\"81\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"265\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await saveToServer</text><text x=\"395\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">larga o ator</text><text x=\"30\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"50\" y=\"112\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Kotlin</text><rect x=\"150\" y=\"112\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">free &gt;= 80?  100</text><text x=\"395\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">confere, ainda 100</text><text x=\"30\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><rect x=\"50\" y=\"143\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Kotlin</text><rect x=\"150\" y=\"143\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"265\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await saveToServer</text><text x=\"395\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">larga o ator</text><text x=\"30\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><rect x=\"50\" y=\"174\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Swift</text><rect x=\"150\" y=\"174\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">free -= 80  → 20</text><text x=\"395\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">retoma</text><text x=\"30\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><rect x=\"50\" y=\"205\" width=\"90\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"95\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Kotlin</text><rect x=\"150\" y=\"205\" width=\"230\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">free -= 80  → -60</text><text x=\"395\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">retoma</text><text x=\"560\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">as duas conferências viram 100</text><text x=\"560\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">antes de qualquer subtração</text></svg>", "caption": "Reentrância no Booking.swift: cada await deixou a outra reserva entrar entre a conferência e a subtração."}
```

## Termine a mudança antes do await

**Trate todo `await` dentro de um ator como um lugar em que o estado do ator pode mudar sem você
ver.** Uma conferência feita antes dele é uma conferência do passado. O conserto é fazer a conferência
e a mudança num pedaço só, sem `await` entre elas, e fazer a parte lenta depois:

```swift
// Reserved.swift
actor WeekPlan {
    var free = 100

    func book(_ minutes: Int, for course: String) async -> Bool {
        guard free >= minutes else {
            print("\(course): refused, \(free) free")
            return false
        }
        free -= minutes
        await saveToServer(course)
        print("\(course): booked \(minutes), \(free) free")
        return true
    }

    func saveToServer(_ course: String) async {
        try? await Task.sleep(for: .milliseconds(100))
    }
}

let plan = WeekPlan()
async let a = plan.book(80, for: "Swift")
async let b = plan.book(80, for: "Kotlin")
_ = await (a, b)
print("free at the end: \(await plan.free)")
```

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Reserved.swift -o reserved && ./reserved
Kotlin: refused, 20 free
Swift: booked 80, 20 free
free at the end: 20
```

Duas linhas trocaram de lugar. Os minutos agora são **reservados** antes de gravar, então a segunda
reserva vê 20 livres e é recusada. Qual dos dois cursos ganha depende de qual chamada chegou primeiro
ao ator, e isso pode mudar na sua máquina; o que não pode mais acontecer é os dois ganharem. Um
planner de verdade também devolveria os minutos se a gravação falhasse, que é o tratamento de erros da
lição 12 dentro de um método de ator, e a mesma regra vale para ele: decida, depois aguarde.
