---
title: Result, um erro que você pode guardar
version: 1
---

Um erro lançado precisa ser tratado na hora: pego, repassado ou convertido. Às vezes a falha precisa
ser **guardada**, num array, devolvida a um callback ou entregue a uma tela que a desenha depois.
**`Result<Success, Failure>` é um valor que guarda ou um sucesso ou um erro**, um enum com dois casos,
`.success` e `.failure`, cada um carregando o seu valor.

```swift
// ResultDemo.swift
enum PlannerError: Error {
    case notANumber(String)
}

func minutes(from text: String) -> Result<Int, PlannerError> {
    guard let minutes = Int(text) else { return .failure(.notANumber(text)) }
    return .success(minutes)
}

let results = ["45", "forty"].map { minutes(from: $0) }
for result in results {
    switch result {
    case .success(let minutes): print("success:", minutes)
    case .failure(let error): print("failure:", error)
    }
}

let hours = results[0].map { Double($0) / 60 }
print(hours)
print(try results[0].get())

func parseMinutes(_ text: String) throws -> Int {
    guard let minutes = Int(text) else { throw PlannerError.notANumber(text) }
    return minutes
}
let caught = Result { try parseMinutes("forty") }
print(caught, type(of: caught))
```

```
ana@vm:~/sw/l12$ swift ResultDemo.swift
success: 45
failure: notANumber("forty")
success(0.75)
45
failure(ResultDemo.PlannerError.notANumber("forty")) Result<Int, Error>
```

A `minutes(from:)` não lança nada. Ela devolve um `Result<Int, PlannerError>`, e **o erro faz parte do
valor de retorno**, então quem chama pode mapear duas strings em dois resultados e guardar os dois. Um
`switch` sobre cada resultado, com um `case` por desfecho, os lê de volta.

Três operações vêm com ele:

- **`map`** transforma o sucesso e deixa uma falha intacta: `results[0].map { Double($0) / 60 }`
  transformou `success(45)` em `success(0.75)`, horas em vez de minutos, sem desembrulhá-lo;
- **`get()`** transforma um `Result` de volta numa chamada que lança: o valor, ou o erro lançado, e é
  por isso que precisa de `try`;
- **`Result { … }`**, o inicializador chamado `Result(catching:)`, vai no sentido contrário e
  transforma uma chamada que lança num `Result`. A última linha mostra a pegadinha dele: o tipo é
  `Result<Int, Error>`, com `Error` e não `PlannerError`, porque a `parseMinutes` é declarada com
  `throws` puro e o compilador não sabe mais que isso.

## Result ou throws

Antes de o Swift ter `async`/`await`, uma função que terminava depois chamava uma closure com um
`Result`, e a maior parte do código iOS mais antigo ainda faz isso. As funções `async` da aula 14
lançam em vez disso, e **em código novo, `throws` é o padrão**: o compilador obriga quem chama a lidar
com ele, coisa que um `Result` esquecido numa variável não faz. O `Result` continua sendo a ferramenta
certa onde uma falha é dado, guardado para depois, como num array de desfechos ou num valor que uma
tela desenha.
