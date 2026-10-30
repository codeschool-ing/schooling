---
title: Igual, ou o mesmo
version: 1
---

"Estas duas sessões são a mesma?" tem dois sentidos, e o Swift dá a cada um o seu operador. **`==`
pergunta se dois valores são iguais**: mesmo curso, mesmos minutos. **`===` pergunta se duas
referências alcançam a mesma instância.** Uma struct só tem a primeira pergunta, porque dois valores
de struct nunca são "o mesmo". Uma classe tem a segunda de graça, e a primeira só se você a escrever.

```swift
// Identity.swift
struct SessionValue: Equatable {
    var course: String
    var minutes: Int
}
final class SessionRef {
    var minutes: Int
    init(minutes: Int) { self.minutes = minutes }
}
let a = SessionValue(course: "Swift", minutes: 45)
let b = SessionValue(course: "Swift", minutes: 45)
print(a == b)

let x = SessionRef(minutes: 45)
let y = SessionRef(minutes: 45)
let z = x
print(x === y, x === z)
```

```
ana@vm:~/sw/l05$ swift Identity.swift
true
false true
```

**O `: Equatable` depois do nome da struct foi tudo o que bastou para ganhar o `==`.** Ele declara
que a struct segue o protocolo `Equatable` da biblioteca padrão, e quando toda propriedade armazenada
é ela mesma comparável, o compilador escreve a comparação: iguais quando toda propriedade é igual. A
lição 8 é sobre protocolos; por ora, leia `: Equatable` como "valores deste tipo podem ser
comparados".

Na classe, `x` e `y` guardam o mesmo número de minutos e ainda assim são duas instâncias, então o
`===` responde `false`; `z` foi atribuído a partir de `x`, então `x === z` é `true`. Pedir `==` a uma
classe sem tê-lo escrito é recusado:

```swift
// NoEquals.swift
final class SessionRef {
    var minutes: Int
    init(minutes: Int) { self.minutes = minutes }
}
let x = SessionRef(minutes: 45)
let y = SessionRef(minutes: 45)
print(x == y)
```

```
ana@vm:~/sw/l05$ swiftc NoEquals.swift -o noequals
NoEquals.swift:8:9: error: binary operator '==' cannot be applied to two 'SessionRef' operands
6 | let x = SessionRef(minutes: 45)
7 | let y = SessionRef(minutes: 45)
8 | print(x == y)
  |         `- error: binary operator '==' cannot be applied to two 'SessionRef' operands
9 | 
```

O compilador não vai adivinhar o que igualdade quer dizer para uma classe, porque para uma classe a
resposta honesta é uma decisão: duas contas com o mesmo nome são pessoas diferentes. Você pode tornar
uma classe `Equatable` e escrever o `==` você mesmo, como mostra a lição 8. **Para uma struct o
palpite está certo, e isso é parte do motivo de structs serem o padrão para dados.**
