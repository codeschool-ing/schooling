---
title: O que roda aqui, e onde fica o muro
version: 1
---

**O SwiftData não compila no Linux, e o compilador da máquina deste curso diz isso numa linha.** As duas
peças de que uma consulta é feita rodam, porque não são do SwiftData: `#Predicate` e `SortDescriptor`
pertencem ao Foundation, que vem com o Swift em toda plataforma. Esta seção mostra as duas coisas: o
muro, e a parte da consulta que fica deste lado dele.

## O muro

Salve esta linha única como `swiftdata.swift`, num diretório `~/l13`, e rode:

```swift
// swiftdata.swift
import SwiftData
```

```
ana@vm:~/l13$ swift swiftdata.swift
swiftdata.swift:2:8: error: no such module 'SwiftData'
1 | // swiftdata.swift
2 | import SwiftData
  |        `- error: no such module 'SwiftData'
3 | 
```

`no such module` é o compilador procurando o framework entre os módulos que recebeu e não achando nada.
Num Mac com Xcode o mesmo arquivo compila, porque o SwiftData está nos SDKs do macOS e do iOS. **Não há
pacote a instalar que mude isso**, e é por isso que tudo nesta aula fora desta seção é lido.

## As partes de uma consulta, nos valores da aula 1

O `@Query(filter:sort:)` recebe um `Predicate` e uma ordenação, e os dois podem ser montados e avaliados
contra valores simples. Use de novo o pacote da aula 1, em `~/l13`: copie os cinco arquivos dele, e troque
o `Package.swift` por este, que acrescenta um programa chamado `query`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Planner",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PlannerCore", targets: ["PlannerCore"]),
    ],
    targets: [
        .target(name: "PlannerCore"),
        .executableTarget(name: "week", dependencies: ["PlannerCore"]),
        .executableTarget(name: "query", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

Salve isto como `Sources/query/main.swift`. As sessões dele são as cinco da aula 1, depois de o `week`
acrescentar a `s5` e marcá-la como feita:

```swift
// Sources/query/main.swift
import Foundation
import PlannerCore

let sessions = [
    StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true),
    StudySession(id: "s2", courseID: "mobile", date: "2026-10-20", minutes: 40, done: true),
    StudySession(id: "s3", courseID: "sql", date: "2026-10-23", minutes: 60),
    StudySession(id: "s4", courseID: "mobile", date: "2026-10-27", minutes: 45),
    StudySession(id: "s5", courseID: "mobile", date: "2026-10-22", minutes: 30, done: true),
]

// What a course's screen asks for: its sessions, latest first
let course = "mobile"
let ofCourse = #Predicate<StudySession> { $0.courseID == course }
let latestFirst = SortDescriptor(\StudySession.date, order: .reverse)
print(try sessions.filter(ofCourse).sorted(using: latestFirst).map(\.id))

// And what the week screen asks for: everything not done yet, in any course
let toDo = #Predicate<StudySession> { !$0.done }
print(try sessions.filter(toDo).sorted(using: latestFirst).map { "\($0.id) \($0.date) \($0.minutes) min" })

// Days are YYYY-MM-DD text, so a range of them is a comparison of strings
let week = #Predicate<StudySession> { $0.date >= "2026-10-19" && $0.date <= "2026-10-25" }
print(try sessions.filter(week).map(\.id))
```

```
ana@vm:~/l13$ swift build
Building for debugging...
[Constructing description]
[Planning deferred tasks]
[30 / 46] PlannerCore
[40 / 52] query-product
[43 / 52] week-product
[46 / 53] PlannerCore
[52 / 55]
[55 / 55] query-product
Build complete! (5.34 secs)
ana@vm:~/l13$ .build/debug/query
["s4", "s5", "s2"]
["s4 2026-10-27 45 min", "s3 2026-10-23 60 min"]
["s1", "s2", "s3", "s5"]
```

**Estes são os predicados que as telas da seção 04 entregam ao SwiftData**, escritos contra
`StudySession` em vez de `SessionRecord`. As sessões do curso mobile voltam da mais recente para a mais
antiga, `s4`, `s5`, `s2`; as duas não feitas, `s4` e `s3`, vêm dos dois cursos. A terceira linha é a
escolha da aula 1 se pagando pela segunda vez: como um dia é texto `YYYY-MM-DD`, "esta semana" são duas
comparações de strings, que um armazenamento consegue responder sem chamar código nenhum seu.

## O predicado que é recusado

O planner já sabe achar uma semana: o `mondayOf` da aula 1. É tentador filtrar por ele. O `echo` abaixo
acrescenta um predicado que faz isso ao fim de `Sources/query/main.swift`, e o `grep` guarda a única linha
do longo relatório do compilador que diz por quê:

```
ana@vm:~/l13$ echo 'let thisWeek = #Predicate<StudySession> { mondayOf($0.date) == "2026-10-19" }' >> Sources/query/main.swift
ana@vm:~/l13$ swift build 2>&1 | grep -m1 "Global functions"
/home/ana/l13/Sources/query/main.swift:26:43: error: Global functions are not supported in this predicate (from macro 'Predicate')
ana@vm:~/l13$ sed -i '$d' Sources/query/main.swift
ana@vm:~/l13$ swift build 2>&1 | tail -1
Build complete! (0.87 secs)
```

**A recusa vem em tempo de compilação**, da macro, antes de qualquer coisa rodar. Um predicado tem de
poder ser descrito para um armazenamento que não sabe nada de funções Swift, então uma chamada a uma
função sua é rejeitada onde está escrita, nas palavras acima. Dentro do SwiftData a mesma regra vale, com
a mesma macro, e a correção honesta é a que a terceira linha da saída já usou: comparar o texto guardado,
e calcular os dois dias em Swift comum antes de montar o predicado.

O `sed -i '$d'` apaga de novo a última linha do arquivo, e o pacote volta a compilar.
