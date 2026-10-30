---
title: Uma String é uma coleção de caracteres
version: 1
---

Uma `String` também é uma coleção, de `Character`, e quase tudo o que você acabou de aprender funciona
nela: `count`, `first`, um laço `for`, `map`, `filter`. **O que não funciona é a primeira coisa que a
maioria das linguagens oferece: ler um caractere por uma posição inteira.** O motivo é que o Swift
conta caracteres como quem lê conta, e não é assim que a memória os guarda.

```swift
// Strings.swift
let course = "Programação"
print(course.count, course.utf8.count)
let composed = "é"
let decomposed = "e\u{301}"
print(composed == decomposed, composed.count, decomposed.count)
print(composed.utf8.count, decomposed.utf8.count)
print(course.prefix(4), course.uppercased(), course.contains("ama"))
let vowels = course.filter { "aeiouáãéíóõú".contains($0) }
print(vowels)
```

```
ana@vm:~/sw/l04$ swift Strings.swift
11 13
true 1 1
2 3
Prog PROGRAMAÇÃO true
oaaão
```

`"Programação"` tem onze caracteres, e ocupa treze bytes em UTF-8, porque `ç` e `ã` ocupam dois bytes
cada. Um programa que contasse bytes diria a uma estudante que o nome do curso é mais longo do que
parece.

O segundo par é o caso mais estranho. `"e\u{301}"` é a letra `e` seguida de um acento agudo
combinante, dois escalares Unicode que quem lê vê como um `é` só. O Swift concorda com quem lê: **as
duas strings contam como um caractere e são iguais**, embora uma ocupe dois bytes e a outra três. Um
nome digitado num teclado e colado de outro documento pode chegar em qualquer das duas formas, e o
`==` faz a coisa certa.

## Sem índices inteiros

```swift
// StringIndex.swift
let course = "Programação"
print(course[3])
```

```
ana@vm:~/sw/l04$ swiftc StringIndex.swift -o stringindex
StringIndex.swift:3:7: error: 'subscript(_:)' is unavailable: cannot subscript String with an Int, use a String.Index instead.
1 | // StringIndex.swift
2 | let course = "Programação"
3 | print(course[3])
  |       `- error: 'subscript(_:)' is unavailable: cannot subscript String with an Int, use a String.Index instead.
4 | 

Swift.String.subscript:3:10: note: 'subscript(_:)' has been explicitly marked unavailable here
1 | struct String {
2 | @available(*, unavailable, message: "cannot subscript String with an Int, use a String.Index instead.")
3 |   public subscript(i: Int) -> Character { get }}
  |          `- note: 'subscript(_:)' has been explicitly marked unavailable here
4 | 
```

O erro é explícito, `cannot subscript String with an Int`, e a segunda nota mostra onde a biblioteca
padrão recusa isso de propósito. Como um caractere pode ter de um a quatro bytes, achar o quarto
significa andar desde o começo; um índice inteiro pareceria instantâneo e seria lento, então o Swift
não oferece um. **O que ele oferece é o `String.Index`**, uma posição que você obtém andando:

```swift
// StringIndexFixed.swift
let course = "Programação"
let fourth = course.index(course.startIndex, offsetBy: 3)
print(course[fourth])
print(course[fourth...])
if let space = "Swift basics".firstIndex(of: " ") {
    print("Swift basics"[..<space])
}
```

```
ana@vm:~/sw/l04$ swift StringIndexFixed.swift
g
gramação
Swift
```

O `index(_:offsetBy:)` anda três caracteres a partir do começo e devolve essa posição.
`course[fourth...]` é tudo dali em diante, e o `firstIndex(of:)` acha um caractere, devolvendo um
índice opcional. Na prática você raramente vai contar posições: `prefix`, `split`, `contains` e
`firstIndex(of:)` cobrem quase tudo o que um planner faz com texto.
