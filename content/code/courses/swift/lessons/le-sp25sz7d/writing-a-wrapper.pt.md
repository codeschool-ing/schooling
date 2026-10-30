---
title: Escrevendo um property wrapper
version: 1
---

**Um property wrapper é um tipo marcado com `@propertyWrapper` que tem uma propriedade chamada
`wrappedValue`.** Esse é o contrato inteiro. Todo o resto, o que ele guarda, o que confere e como é
inicializado, é Swift comum das lições 5 e 6:

```schooling-example
{"language": "swift", "file": "Clamped.swift", "parts": [{"code": "@propertyWrapper\nstruct Clamped {\n    private var value: Int\n    let range: ClosedRange<Int>", "note": "**O `@propertyWrapper` torna o tipo utilizável depois de um `@`.** O que ele guarda é com ele: aqui, o valor e a faixa em que ele precisa ficar."}, {"code": "    init(wrappedValue: Int, _ range: ClosedRange<Int>) {\n        self.range = range\n        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)\n    }", "note": "O inicializador que o compilador chama. **O `wrappedValue:` recebe o valor inicial da propriedade**, o `= 45` lá embaixo, e o outro parâmetro é o que estiver entre parênteses depois do `@Clamped`."}, {"code": "    var wrappedValue: Int {\n        get { value }\n        set { value = min(max(newValue, range.lowerBound), range.upperBound) }\n    }\n}", "note": "O único membro obrigatório. Toda leitura de uma propriedade com wrapper chama este getter e toda escrita chama este setter, então **a regra mora aqui, uma vez**."}, {"code": "struct StudySession {\n    @Clamped(0...600) var minutes = 45\n    @Clamped(0...1200) var weeklyGoal = 300\n}", "note": "Duas propriedades, duas faixas, uma regra. Cada `@Clamped(…)` cria a sua própria instância de `Clamped`."}, {"code": "var session = StudySession()\nsession.minutes = 900\nsession.weeklyGoal = 2000\nprint(session.minutes, session.weeklyGoal)\nsession.minutes = -5\nprint(session.minutes)", "note": "Quem chama lê e escreve `minutes` como um `Int` comum. Nada no lugar da chamada mostra que há um wrapper, e isso é a conveniência e o risco ao mesmo tempo."}]}
```

```
ana@vm:~/sw/l16$ swift Clamped.swift
600 1200
0
```

**Uma regra, escrita uma vez, aplicada a duas propriedades com faixas diferentes**, e o comportamento
do `ByHand.swift` sem nada da repetição dele: 900 minutos viraram 600, uma meta de 2.000 virou os 1.200
que a faixa dela permite, e −5 virou 0.

## O armazenamento escondido é de verdade

O `_minutes` do compilador é uma propriedade armazenada comum, e código dentro do tipo pode usá-la. Ela
é `private`, então código de fora não pode, o que faz toda escrita passar pelo `wrappedValue`. Dentro,
ela é o caminho para chegar ao wrapper em vez de ao valor:

```swift
// Storage.swift
@propertyWrapper
struct Clamped {
    private var value: Int
    let range: ClosedRange<Int>

    init(wrappedValue: Int, _ range: ClosedRange<Int>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }

    var wrappedValue: Int {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }
}

struct StudySession {
    @Clamped(0...600) var minutes = 45

    func describe() -> String {
        "\(minutes) minutes, allowed \(_minutes.range)"
    }
}

let session = StudySession()
print(session.describe())
print(session._minutes.range)
```

```
ana@vm:~/sw/l16$ swiftc Storage.swift -o storage && ./storage
Storage.swift:28:15: error: '_minutes' is inaccessible due to 'private' protection level
17 | 
18 | struct StudySession {
19 |     @Clamped(0...600) var minutes = 45
   |                           `- note: '_minutes' declared here
20 | 
21 |     func describe() -> String {
   :
26 | let session = StudySession()
27 | print(session.describe())
28 | print(session._minutes.range)
   |               `- error: '_minutes' is inaccessible due to 'private' protection level
29 | 
```

**Um erro, e é sobre a linha 28, fora do tipo.** O `describe()` lê `_minutes.range` na linha 22, dentro
do tipo, e o compilador não teve nada a dizer. A última linha pede a mesma coisa de fora e é recusada,
com o motivo no vocabulário da lição 17: `_minutes` é **inacessível por causa do nível de proteção
`private`**, e a nota aponta de volta para a linha do `@Clamped` que o declarou. Apague a linha 28 e o
programa imprime a frase que o `describe()` monta.

## Três regras que vale saber antes de escrever vários

- **O valor inicial passa pelo wrapper.** O `= 45` é passado ao `init(wrappedValue:)`, e é por isso
  que esse inicializador também limita: `@Clamped(0...600) var minutes = 900` começa em 600, não em
  900.
- **Um wrapper não pode ser aplicado a um `let`.** Ele precisa de um setter para fazer sentido, e o
  compilador recusa `@Clamped(0...600) let minutes = 45`.
- **Propriedades com wrapper de um struct continuam no inicializador membro a membro**, pelo nome
  simples: `StudySession(minutes: 900)` funciona, e limita.

Um wrapper é a ferramenta certa para uma regra sobre **um valor**, a mesma em todo tipo que tem um
valor assim. Uma regra que relaciona duas propriedades, como uma pausa que precisa ser mais curta que a
sessão, não é assunto de uma propriedade só; ela pertence a um método do tipo, ou ao inicializador
dele.
