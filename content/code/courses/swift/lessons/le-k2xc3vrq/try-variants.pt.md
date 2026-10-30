---
title: try? e try!
version: 1
---

O compilador da seção 01 ofereceu três grafias. O `try` puro repassa o erro. As outras duas
**transformam o erro em outra coisa ali mesmo**: o `try?` num opcional, e o `try!` numa quebra.

```swift
// TryVariants.swift
enum PlannerError: Error {
    case notANumber(String)
}

func parseMinutes(_ text: String) throws -> Int {
    guard let minutes = Int(text) else { throw PlannerError.notANumber(text) }
    return minutes
}

let typed = ["45", "forty", "30", "", "60"]
let maybe = try? parseMinutes("forty")
print(maybe as Any)
let valid = typed.compactMap { try? parseMinutes($0) }
print(valid, valid.reduce(0, +))
let sure = try! parseMinutes("90")
print(sure)
let wrong = try! parseMinutes(typed[1])
print(wrong)
```

```
ana@vm:~/sw/l12$ swiftc TryVariants.swift -o tryvariants
ana@vm:~/sw/l12$ SWIFT_BACKTRACE=enable=no ./tryvariants
nil
[45, 30, 60] 135
90
tryvariants/TryVariants.swift:18: Fatal error: 'try!' expression unexpectedly raised an error: tryvariants.PlannerError.notANumber("forty")
Current stack trace:
0    libswiftCore.so                    0x00007fad0d162cd0 swift_reportError + 33
1    libswiftCore.so                    0x00007fad0d519190 _swift_stdlib_reportFatalErrorInFile + 109
2    libswiftCore.so                    0x00007fad0d1734e1 <unavailable> + 1520865
3    libswiftCore.so                    0x00007fad0d309e90 _assertionFailure(_:_:file:line:flags:) + 299
4    libswiftCore.so                    0x00007fad0d3692b0 swift_unexpectedError + 803
5    tryvariants                        0x000055e14ca67647 <unavailable> + 9799
6    libc.so.6                          0x00007fad0cc2a1ca <unavailable> + 172490
7    libc.so.6                          0x00007fad0cc2a200 __libc_start_main + 139
8    tryvariants                        0x000055e14ca66405 <unavailable> + 5125
```

## O try? guarda o sucesso e larga o motivo

`try? parseMinutes("forty")` dá um `Int?`: o número quando a chamada dá certo, `nil` quando ela lança,
e o erro em si é descartado. O `print(maybe as Any)` imprime `nil` sem o aviso que a lição 1 encontrou,
porque o `as Any` diz que o opcional é intencional.

**Ele serve onde o motivo não importa.** O `compactMap` (lição 4) guarda os valores que não são `nil`,
então `typed.compactMap { try? parseMinutes($0) }` lê uma lista de durações digitadas e guarda as que
são números: 45, 30 e 60, 135 minutos, deixando de fora `"forty"` e a string vazia. Isso está certo
para um total rápido. Está errado para um formulário, em que a estudante precisa saber qual campo não
era número, e só o erro sabe.

## O try! é uma promessa, e quebra quando ela é quebrada

O `try!` diz que a chamada não pode falhar ali, e **se falhar, o programa para**. O
`try! parseMinutes("90")` deu 90. O `try! parseMinutes(typed[1])` leu `"forty"`, e o processo terminou
com `'try!' expression unexpectedly raised an error`, citando o arquivo, a linha 18, e o erro. É o
desempacotamento forçado da lição 2 de novo, para erros, e merece a mesma desconfiança: honesto para
um valor escrito no próprio programa, como `"90"`, e uma quebra esperando o dia em que o valor vier de
outro lugar.

| | quando a chamada lança | o resultado | use quando |
|---|---|---|---|
| `try` | o erro vai para quem chamou, ou para um `catch` | o valor | alguém pode agir sobre o motivo |
| `try?` | o erro é descartado | um opcional | só importa sucesso ou falha |
| `try!` | o programa para | o valor | uma falha seria um bug deste programa |
