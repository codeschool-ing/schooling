---
title: do e catch
version: 1
---

Pegar um erro quer dizer decidir o que o programa faz em vez disso. **Um bloco `do` roda código que
pode lançar, e as cláusulas `catch` depois dele dizem o que fazer com cada tipo de falha.** O planner
lê quatro durações que uma estudante digitou, e cada falha ganha uma frase própria:

```schooling-example
{"language": "swift", "file": "DoCatch.swift", "parts": [{"code": "// DoCatch.swift\nenum PlannerError: Error {\n    case notANumber(String)\n    case tooLong(minutes: Int)\n}\n\nfunc parseMinutes(_ text: String) throws -> Int {\n    guard let minutes = Int(text) else { throw PlannerError.notANumber(text) }\n    guard minutes <= 240 else { throw PlannerError.tooLong(minutes: minutes) }\n    return minutes\n}\n", "note": "O mesmo enum de erro e a mesma função da seção 01. Nada na função diz quem vai tratar o que ela lança."}, {"code": "for typed in [\"45\", \"forty\", \"300\", \"900\"] {\n    do {\n        let minutes = try parseMinutes(typed)\n        print(\"\\(typed): \\(minutes) minutes added\")", "note": "O `do` abre um bloco onde erros são pegos. Dentro dele, o `try` ainda marca a chamada que pode falhar; se ela lança, o resto do bloco é pulado e o Swift olha as cláusulas `catch` abaixo, em ordem."}, {"code": "    } catch PlannerError.notANumber(let text) {\n        print(\"\\(typed): \\\"\\(text)\\\" is not a number of minutes\")", "note": "Uma cláusula `catch` é um padrão, como um `case` da aula 7. Esta só casa com `notANumber`, e o `let text` pega o valor que o caso carregava."}, {"code": "    } catch PlannerError.tooLong(let minutes) where minutes >= 600 {\n        print(\"\\(typed): \\(minutes) minutes looks like a typo\")\n    } catch PlannerError.tooLong(let minutes) {\n        print(\"\\(typed): \\(minutes) minutes is longer than one study block\")", "note": "Duas cláusulas para o mesmo caso, separadas pelo `where`. A ordem importa: ganha a primeira cláusula cujo padrão casa, então a mais estreita, 600 minutos ou mais, vem primeiro."}, {"code": "    } catch {\n        print(\"\\(typed): unexpected \\(error)\")\n    }\n}", "note": "Um `catch` puro pega o que sobrou, e lhe dá o nome `error` sem ninguém pedir. Aqui ele nunca roda, porque as cláusulas acima cobrem os dois casos, e a seção 02 diz por que ele ainda é obrigatório."}]}
```

```
ana@vm:~/sw/l12$ swift DoCatch.swift
45: 45 minutes added
forty: "forty" is not a number of minutes
300: 300 minutes is longer than one study block
900: 900 minutes looks like a typo
```

Quatro entradas e quatro linhas diferentes, e **o laço seguiu depois de cada falha**: um `catch` trata
o erro, e o programa continua depois do bloco `do` como se nada tivesse sido lançado. `300` e `900`
são o mesmo caso, `tooLong`, mandados para cláusulas diferentes pelo `where`.

## Por que o último catch é obrigatório

A `parseMinutes` é declarada `throws`, sem tipo depois, o que quer dizer que ela pode lançar
**qualquer** erro, de qualquer tipo que conforme a `Error`. O compilador conhece os dois casos de
`PlannerError`, e não sabe que a `parseMinutes` não lança mais nada. Então dentro de uma função que
não lança, um `do` precisa pegar tudo:

```swift
// NotExhaustive.swift
enum PlannerError: Error {
    case notANumber(String)
    case tooLong(minutes: Int)
}

func parseMinutes(_ text: String) throws -> Int {
    guard let minutes = Int(text) else { throw PlannerError.notANumber(text) }
    return minutes
}

func add(_ typed: String) {
    do {
        print(try parseMinutes(typed))
    } catch PlannerError.notANumber(let text) {
        print("not a number: \(text)")
    } catch PlannerError.tooLong(let minutes) {
        print("too long: \(minutes)")
    }
}
```

```
ana@vm:~/sw/l12$ swiftc NotExhaustive.swift -o notexhaustive
NotExhaustive.swift:14:15: error: errors thrown from here are not handled because the enclosing catch is not exhaustive
12 | func add(_ typed: String) {
13 |     do {
14 |         print(try parseMinutes(typed))
   |               `- error: errors thrown from here are not handled because the enclosing catch is not exhaustive
15 |     } catch PlannerError.notANumber(let text) {
16 |         print("not a number: \(text)")
```

`errors thrown from here are not handled because the enclosing catch is not exhaustive`: os dois
casos de `PlannerError` estão cobertos, e o compilador ainda não consegue provar que nada mais chega.
A correção é um `catch` puro no fim, como o `DoCatch.swift` tem, ou marcar `add` como `throws` para que
o que sobrar suba para quem a chamou. A seção 04 mostra a terceira correção, uma função que declara
exatamente que tipo lança.

## O que pôr num catch

Um catch que imprime e segue está certo para um laço sobre entradas, como aqui. **Um catch que não
faz nada, `catch { }`, quase nunca está certo**: ele transforma uma falha em silêncio, e a estudante
cuja sessão não foi salva não fica sabendo. Se realmente não há nada a fazer, escreva no `catch` o
porquê, e deixe quem lê julgar.
