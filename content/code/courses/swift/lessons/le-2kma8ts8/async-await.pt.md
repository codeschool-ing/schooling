---
title: async e await
version: 1
---

**`async` marca uma função que pode pausar, e `await` marca cada lugar em que ela pode pausar.** As
duas palavras são toda a sintaxe. Aqui está o programa da seção 02 de novo, com os mesmos dois
atrasos e a mesma saída, e nenhuma closure:

```swift
// Planner.swift
func loadCourse(named name: String) async -> String {
    try? await Task.sleep(for: .milliseconds(200))
    return name
}

func loadMinutes(for course: String) async -> [Int] {
    try? await Task.sleep(for: .milliseconds(200))
    return [45, 30, 60]
}

print("asking for the course")
let course = await loadCourse(named: "Swift")
print("got \(course), asking for its sessions")
let minutes = await loadMinutes(for: course)
print("\(course): \(minutes.reduce(0, +)) minutes")
```

```
ana@vm:~/sw/l14$ swift Planner.swift
asking for the course
got Swift, asking for its sessions
Swift: 135 minutes
```

A ordem na página é a ordem no tempo. `let course = await loadCourse(named: "Swift")` se lê como uma
chamada comum que devolve uma `String`, e é uma, com uma diferença que não aparece na saída:
**enquanto espera, a thread em que rodava fica livre** para rodar outro trabalho. Quando a resposta
chega, a função continua da linha depois do `await`, talvez em outra thread. O semáforo também sumiu,
porque o nível de cima de um script pode usar `await` diretamente e o programa espera cada linha
antes da seguinte.

`Task.sleep(for:)` é o jeito assíncrono de esperar, e faz o papel da rede aqui. A seção 07 explica
por que ele pode lançar um erro e o que o `try?` na frente dele joga fora.

## O await é obrigatório, e um lugar de onde esperar também

O compilador cobra as duas pontas da regra. Uma chamada a uma função `async` sem `await` é recusada,
e também um `await` dentro de uma função que não é `async`:

```swift
// Report.swift
func loadCourse(named name: String) async -> String {
    name
}

func report() {
    let course = await loadCourse(named: "Swift")
    print(course)
}

report()
```

```
ana@vm:~/sw/l14$ swiftc Report.swift -o report
Report.swift:7:24: error: 'async' call in a function that does not support concurrency
 4 | }
 5 | 
 6 | func report() {
   |      `- note: add 'async' to function 'report()' to make it asynchronous
 7 |     let course = await loadCourse(named: "Swift")
   |                        `- error: 'async' call in a function that does not support concurrency
 8 |     print(course)
 9 | }
```

**O erro é sobre o `report`, não sobre a chamada.** Uma função que não é `async` roda do começo ao fim
sem pausar, então não tem como esperar nada, e o compilador diz isso: uma chamada `async` numa função
que não suporta concorrência. A nota dele oferece a primeira saída, marcar `report` como `async`, o
que passa a pergunta para quem chama `report`. Em algum lugar no topo de toda cadeia tem de haver um
ponto que inicia trabalho assíncrono a partir de código que não é assíncrono. Num script esse ponto é
o nível de cima; num app é uma **tarefa**, o assunto da seção 04.

## O que o `await` promete, e o que não promete

O `await` é um **ponto de suspensão**: um lugar em que a função pode pausar e outro código pode rodar
antes que ela continue. Não é a promessa de que algo roda em paralelo. No `Planner.swift` as duas
cargas rodaram uma depois da outra, 200 milissegundos cada, porque a segunda precisa da resposta da
primeira. As seções 05 e 06 rodam trabalho independente ao mesmo tempo, e as medições mostram a
diferença.
