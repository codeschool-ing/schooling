---
title: Closures que seguram o self
version: 1
---

Uma closure que usa um nome de fora dela o **captura**: mantém o valor, ou a referência, vivo enquanto
a própria closure estiver viva (aula 3). Quando a closure é guardada numa propriedade de uma classe
e usa `self`, isso é um laço de dois: o objeto segura a closure, e a closure segura o objeto. **É o
ciclo de retenção mais comum em código Swift, porque nada na linha que o cria parece uma
referência.**

A contagem regressiva do planner roda uma closure quando um bloco de estudo termina. Duas versões da
mesma classe, uma capturando `self` com força e outra com `weak`:

```swift
// Closures.swift
final class Countdown {
    let course: String
    var onFinish: (() -> Void)?
    init(course: String) { self.course = course }
    deinit { print("\(course) countdown freed") }

    func strongReport() {
        onFinish = { print("finished \(self.course)") }
    }

    func weakReport() {
        onFinish = { [weak self] in
            guard let self else { return }
            print("finished \(self.course)")
        }
    }
}

func run(_ name: String, weakly: Bool) {
    let countdown = Countdown(course: name)
    if weakly { countdown.weakReport() } else { countdown.strongReport() }
    countdown.onFinish?()
}

run("Swift", weakly: false)
run("Kotlin", weakly: true)
print("both functions returned")
```

```
ana@vm:~/sw/l11$ swift Closures.swift
finished Swift
finished Kotlin
Kotlin countdown freed
both functions returned
```

As duas closures rodaram e imprimiram. Só uma contagem regressiva foi liberada: **a de Swift, cuja
closure capturou `self` com força, continua na memória** depois que `run` retornou, segurada pela
própria closure, que ela segura. A closure da de Kotlin capturou `self` com `weak`, então quando `run`
retornou nada segurava o objeto e ele foi embora.

## A lista de captura

`[weak self] in` é uma **lista de captura**: colchetes antes do `in`, dizendo como cada nome é
capturado. Sem ela, `self` é capturado com força. Com `weak`, a closure segura uma referência fraca,
`self` dentro dela é um opcional, e `guard let self else { return }` o transforma de volta numa
referência forte pelo resto da closure, ou sai em silêncio se o objeto já foi. `[unowned self]` também
existe, com a promessa da seção 05 e a quebra da seção 05.

O compilador ajuda numa metade disso. Dentro de uma closure guardada para depois, uma closure que
**escapa**, o Swift obriga você a escrever `self.course` em vez de `course`, para que todo uso de
`self` fique visível na página. Esse `self.` é o lugar de parar e perguntar quem segura quem.

## Closures que não vazam

Uma closure passada para `map`, `filter` ou `sorted` roda durante a chamada e some quando a chamada
retorna; ela **não escapa**, e pode usar `self` à vontade, sem `self.`, porque não sobrevive à linha.
Só uma closure guardada, numa propriedade, num array, num timer ou numa tarefa, pode entrar num ciclo.
O `Task { }` da aula 14 é uma dessas, e a mesma lista de captura funciona lá.
