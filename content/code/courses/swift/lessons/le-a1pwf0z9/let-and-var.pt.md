---
title: let e var
version: 1
---

O Swift tem duas palavras para dar nome a um valor, e a diferença entre elas é a primeira coisa que
o compilador vai cobrar de você. **`let` dá nome a uma constante: depois que tem um valor, fica com
ele.** `var` dá nome a uma variável, que pode receber um valor novo quantas vezes você quiser.

Uma estudante define uma meta semanal de 300 minutos e depois tenta aumentá-la:

```swift
// Goal.swift
let goal = 300
goal = 360
print(goal)
```

```
ana@vm:~/sw/l01$ swiftc Goal.swift -o goal
Goal.swift:3:1: error: cannot assign to value: 'goal' is a 'let' constant
1 | // Goal.swift
2 | let goal = 300
  | `- note: change 'let' to 'var' to make it mutable
3 | goal = 360
  | `- error: cannot assign to value: 'goal' is a 'let' constant
4 | print(goal)
5 | 
```

**O compilador recusa, e nenhum programa é gerado.** Leia a mensagem de cima para baixo. A primeira
linha dá o arquivo, a linha e a coluna, `Goal.swift:3:1`, depois o tipo da mensagem, `error`, e
depois o que está errado. Abaixo, o compilador reimprime as linhas em volta do problema, com uma
marca sob o lugar a que se refere, e uma `note` que aponta para a linha 2, onde `goal` foi declarado,
com a correção: trocar `let` por `var`. A maioria dos erros do Swift tem esse formato, e a nota
muitas vezes é a resposta.

## Quando um valor precisa mudar

Os minutos estudados na semana são um total acumulado, então pertencem a um `var`:

```swift
// Week.swift
let goal = 300
var studied = 0
studied += 45
studied += 30
studied += 60
print("\(studied) of \(goal) minutes")
```

```
ana@vm:~/sw/l01$ swiftc Week.swift -o week && ./week
135 of 300 minutes
```

O `+=` soma a uma variável no lugar: `studied += 45` é `studied = studied + 45`. Tanto `goal` quanto
`studied` são números, e só um deles pode mudar.

## A opinião do compilador sobre var

O Swift prefere `let`, e diz isso. Dentro de uma função, um `var` que nunca recebe valor novo ganha
um aviso:

```swift
// Warn.swift
func weekReport() {
    var goal = 300
    var studied = 0
    studied += 45
    print("\(studied) of \(goal) minutes")
}
weekReport()
```

```
ana@vm:~/sw/l01$ swiftc Warn.swift -o warn && ./warn
Warn.swift:3:9: warning: variable 'goal' was never mutated; consider changing to 'let' constant [#VariableNeverMutated]
1 | // Warn.swift
2 | func weekReport() {
3 |     var goal = 300
  |         `- warning: variable 'goal' was never mutated; consider changing to 'let' constant [#VariableNeverMutated]
4 |     var studied = 0
5 |     studied += 45

[#VariableNeverMutated]: <https://docs.swift.org/compiler/documentation/diagnostics/variable-never-mutated>
45 of 300 minutes
```

Desta vez o programa foi gerado e rodou: um **aviso** é um conselho, e só um `error` para o build. O
compilador percebeu que `goal` foi declarado com `var` e nunca reatribuído, e sugere `let`. A última
linha do aviso é um link para uma página que explica o diagnóstico, e todo aviso com um nome entre
colchetes tem uma.

O aviso aparece aqui e não apareceu no `Week.swift` porque o compilador verifica os nomes dentro de
uma função desse jeito, onde consegue ver todos os usos. Um nome no nível de cima de um arquivo é
visível para o resto do programa, e o compilador não tenta. A aula 3 é sobre funções.

**Por que a preferência importa.** Um `let` é uma promessa a quem lê: o que esse valor era na linha
2, ainda é. Quando você lê cem linhas depois que `goal` vale 300, não precisa procurar uma linha que
o mudou. Num app, em que um valor pode ser lido por várias partes do código ao mesmo tempo, a aula
15 mostra que um valor que ninguém pode mudar é também um valor que ninguém pode mudar na hora
errada. **Escreva `let` por padrão, e troque para `var` quando o compilador ou o programa pedir.**

## let não congela tudo

O `let` prende o nome a um valor. O que isso significa para uma lista ou um registro depende de o
valor ser de um tipo de valor ou de um tipo de referência, que é o assunto da aula 5. Para os
números e textos desta aula, as duas ideias coincidem: um número `let` não muda de jeito nenhum.
