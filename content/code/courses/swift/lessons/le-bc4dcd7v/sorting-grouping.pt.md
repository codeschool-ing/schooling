---
title: Ordenar, agrupar e achar o maior
version: 1
---

Um relatório do planner quer as sessões mais longas primeiro e os minutos por curso. As duas coisas
são uma chamada.

```swift
// Sorting.swift
let week: [(course: String, minutes: Int)] = [
    ("Swift", 45), ("Kotlin", 30), ("Swift", 60), ("SQL", 20), ("Kotlin", 50),
]
print([45, 30, 60, 20, 50].sorted())
let longestFirst = week.sorted { $0.minutes > $1.minutes }
print(longestFirst.map { "\($0.course) \($0.minutes)" })
let byCourseThenLength = week.sorted {
    ($0.course, $1.minutes) < ($1.course, $0.minutes)
}
print(byCourseThenLength.map { "\($0.course) \($0.minutes)" })
if let longest = week.max(by: { $0.minutes < $1.minutes }) {
    print("longest:", longest.course, longest.minutes)
}
```

```
ana@vm:~/sw/l04$ swift Sorting.swift
[20, 30, 45, 50, 60]
["Swift 60", "Kotlin 50", "Swift 45", "Kotlin 30", "SQL 20"]
["Kotlin 50", "Kotlin 30", "SQL 20", "Swift 60", "Swift 45"]
longest: Swift 60
```

O `sorted()` sem argumento funciona com qualquer coisa que se compare com `<`, como números e strings.
Para o resto, **o `sorted(by:)` recebe uma closure que responde a uma pergunta: o primeiro destes dois
vem antes do segundo?** `$0.minutes > $1.minutes` diz que o mais longo vem primeiro.

A segunda ordenação compara tuplas, que o Swift compara elemento por elemento: primeiro pelo nome do
curso e, só quando os nomes são iguais, pelos minutos. Trocar `$0` e `$1` na segunda posição inverte
essa metade da comparação, então as sessões de cada curso vêm da mais longa para a mais curta. O
`max(by:)` recebe o mesmo tipo de closure e devolve um opcional, porque um array vazio não tem maior
item.

## Agrupando

```swift
// Grouping.swift
let week: [(course: String, minutes: Int)] = [
    ("Swift", 45), ("Kotlin", 30), ("Swift", 60), ("SQL", 20), ("Kotlin", 50),
]
let byCourse = Dictionary(grouping: week) { $0.course }
let totals = byCourse.mapValues { sessions in
    sessions.reduce(0) { $0 + $1.minutes }
}
for course in totals.keys.sorted() {
    print(course, byCourse[course]?.count ?? 0, totals[course] ?? 0)
}
```

```
ana@vm:~/sw/l04$ swift Grouping.swift
Kotlin 2 80
SQL 1 20
Swift 2 105
```

O `Dictionary(grouping:by:)` percorre o array uma vez e arquiva cada sessão sob a chave que a closure
devolve, então `byCourse` é um `[String: [(course: String, minutes: Int)]]`: cada curso com sua lista
de sessões. O `mapValues` é o `map` dos valores de um dicionário, mantendo as chaves, e aqui ele
transforma cada lista num total. **Agrupar e depois reduzir cada grupo** é a forma de quase todo resumo
que um planner mostra: por curso, por dia, por semana. O aviso da seção 03 continua valendo, então o
laço ordena as chaves.
