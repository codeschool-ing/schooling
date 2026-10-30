---
title: Arrays, em ordem e por posição
version: 1
---

Um **array** é uma lista ordenada de valores de um tipo. `[45, 30, 60]` é um `[Int]`, abreviação de
`Array<Int>`, e todo item dele é um `Int`: o compilador não deixa uma `String` entrar. A ordem é a
razão de ser de um array, e a posição de um item é o seu **índice**, contado a partir do zero.

```swift
// Arrays.swift
var sessions = [45, 30, 60]
sessions.append(20)
sessions += [50]
print(sessions, sessions.count)
print(sessions[0], sessions[sessions.count - 1])
sessions.insert(15, at: 0)
let removed = sessions.remove(at: 2)
print(sessions, "removed \(removed)")
for (index, minutes) in sessions.enumerated() {
    print(index, minutes)
}
let empty: [Int] = []
print(empty.isEmpty, String(describing: empty.first), String(describing: sessions.first))
```

```
ana@vm:~/sw/l04$ swift Arrays.swift
[45, 30, 60, 20, 50] 5
45 50
[15, 45, 60, 20, 50] removed 30
0 15
1 45
2 60
3 20
4 50
true nil Optional(15)
```

O `append` acrescenta um item no fim e o `+=` acrescenta um array inteiro. `insert(_:at:)` e
`remove(at:)` trabalham por posição, e o `remove` devolve o que tirou. O `enumerated()` dá cada item
junto com seu índice, como um par que o laço separa em dois nomes. **`first` e `last` são opcionais**,
porque um array vazio não tem nenhum dos dois, e é a aula 2 chegando a um lugar que você vai
encontrar todo dia.

## Um índice que não existe

`sessions[0]` não é opcional. O Swift confia que você sabe que o array é longo o bastante, e confere
enquanto o programa roda:

```swift
// OutOfRange.swift
let sessions = [45, 30]
print(sessions[5])
```

```
ana@vm:~/sw/l04$ swiftc OutOfRange.swift -o outofrange
ana@vm:~/sw/l04$ ./outofrange 2>&1 | head -3
Swift/ContiguousArrayBuffer.swift:695: Fatal error: Index out of range

*** Signal 4: Backtracing from 0x7fdd0f3731ef... done ***
```

**Ler além do fim para o programa**, com o mesmo tipo de relatório do estouro da aula 1, e a primeira
linha diz por quê. Ela cita um arquivo da biblioteca padrão em vez do seu, porque é lá que a
verificação mora; a linha sua que pediu está mais abaixo no relatório completo. É o resultado certo:
em C, a mesma linha lê qualquer memória que estiver ali, e o programa segue com um número que ninguém
escreveu. Quando não tiver certeza de que um índice existe, confira `sessions.indices.contains(5)`
antes, ou use `first` e `last`, que fazem a pergunta por você.

## Um array let é um array fixo

A aula 1 disse que o que o `let` significa para uma lista ficaria para a aula 5. Eis a metade de que
você precisa agora:

```swift
// LetArray.swift
let sessions = [45, 30]
sessions.append(60)
print(sessions)
```

```
ana@vm:~/sw/l04$ swiftc LetArray.swift -o letarray
LetArray.swift:3:10: error: cannot use mutating member on immutable value: 'sessions' is a 'let' constant
1 | // LetArray.swift
2 | let sessions = [45, 30]
  | `- note: change 'let' to 'var' to make it mutable
3 | sessions.append(60)
  |          `- error: cannot use mutating member on immutable value: 'sessions' is a 'let' constant
4 | print(sessions)
5 | 
```

O `append` é um membro **mutante**: ele muda o array em que é chamado, e um array `let` não pode ser
mudado de jeito nenhum, nem com um acréscimo no fim. A nota oferece a correção. A aula 5 explica por
que um array se comporta como um número aqui, e não como um objeto que outra parte do código poderia
mudar pelas suas costas, que é o motivo mais profundo.
