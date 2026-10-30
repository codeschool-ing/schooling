---
title: Encadeamento opcional, e ?? para um padrão
version: 1
---

O `if let` e o `guard let` desmontam o opcional. Dois operadores trabalham com ele sem desmontar:
**`?.` pergunta algo ao valor se ele estiver lá, e `??` fornece um valor para quando não estiver.**

## O ?. repassa o nil

`note?.count` pede o `count` de `note` se `note` guarda uma string, e dá `nil` sem perguntar se não
guarda. Então o resultado também é opcional: `note?.count` é um `Int?`, nunca um `Int`.

```swift
// Chain.swift
let notes: [String?] = ["read chapter 3", nil, ""]
for note in notes {
    let length = note?.count
    print(String(describing: length))
}
let shouted = notes[1]?.uppercased().count
print(String(describing: shouted))
```

```
ana@vm:~/sw/l02$ swift Chain.swift
Optional(14)
nil
Optional(0)
nil
```

O `String(describing:)` imprime um opcional como ele é, sem o aviso da aula 1, e é por isso que está
aqui. As três linhas são os três resultados que vale distinguir: **um comprimento, `nil` para a
anotação que falta e `0` para a vazia.**

`notes[1]?.uppercased().count` se lê como uma pergunta só: o comprimento da segunda anotação em
maiúsculas, se ela existir. O `?` depois de `notes[1]` é o único necessário. Se essa anotação é `nil`,
nada à direita dele roda, e a expressão inteira é `nil`. Se não é, `uppercased()` devolve uma `String`
simples e o `.count` é pedido dela. **Um `?` protege tudo o que vem depois dele na cadeia.**

## O ?? encerra a pergunta

O `??` é o **operador de coalescência de nil**. À esquerda, um opcional; à direita, um valor do tipo
simples. Ele dá o valor do lado esquerdo se houver e o do lado direito se não houver, então o
resultado nunca é opcional:

```swift
// Coalesce.swift
let entries = ["45", "forty", "30"]
var total = 0
for typed in entries {
    total += Int(typed) ?? 0
}
print("total \(total)")
let note: String? = nil
print("note: " + (note ?? "none"))
let length = note?.count ?? 0
print(length, type(of: length))
```

```
ana@vm:~/sw/l02$ swift Coalesce.swift
total 75
note: none
0 Int
```

`Int(typed) ?? 0` é um `Int`, então o `+=` aceita, e a palavra `"forty"` conta como zero. Compare com
o laço da seção 03: mais curto, e já não diz quais entradas foram puladas. **O `??` é a resposta certa
quando o padrão quer dizer o mesmo que o valor**, e a errada quando a estudante precisa saber que algo
faltou.

As duas últimas linhas juntam os dois operadores, como você vai vê-los na maior parte do código Swift:
`note?.count ?? 0` é "o comprimento da anotação, ou zero", e o `type(of:)` confirma que é um `Int`
simples.

## Um padrão que custa algo

O lado direito do `??` só roda quando é necessário. O Swift o avalia de forma preguiçosa, então um
padrão caro de produzir, como ler um arquivo, não é produzido quando o lado esquerdo tem valor. É um
fato pequeno, e quer dizer que você nunca precisa escrever um `if` só para evitar calcular um padrão.
