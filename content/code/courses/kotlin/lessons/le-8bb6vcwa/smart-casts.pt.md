---
title: Smart casts, e a verificação que o compilador lembra
version: 1
---

O jeito mais antigo de lidar com `null` é verificar, e o Kotlin mantém esse jeito e o melhora.
**Depois de `if (note != null)`, o compilador trata `note` como `String` enquanto a verificação
valer**, então `.length` compila com um ponto simples. Isso se chama smart cast: o compilador faz o
cast por você, porque acabou de ver você provar que ele é seguro.

```kotlin
// SmartCast.kt
fun describe(note: String?): String {
    if (note == null) {
        return "no note"
    }
    return "note of ${note.length} characters"
}

fun main() {
    println(describe(null))
    println(describe("read chapter 3"))
}
```

```
ana@vm:~/kt/l02$ kotlinc SmartCast.kt -include-runtime -d smartcast.jar && java -jar smartcast.jar
no note
note of 14 characters
```

A verificação aqui é a oposta, `note == null`, seguida de um `return`. O compilador acompanha isso
também: depois do `if`, o único jeito de ter chegado é com uma anotação, então `note` é `String` na
última linha. **Verificar e sair cedo é a forma mais legível**, porque o resto da função fica escrito
para o caso em que tudo está presente.

## Quando o compilador não lembra

Um smart cast é uma promessa de que o valor não muda entre a verificação e o uso. Para um `val` na
mesma função isso é óbvio. Para uma propriedade `var` de um objeto, não é: outra coisa poderia
pô-la em `null` no meio do caminho.

```kotlin
// Draft.kt
class Draft {
    var note: String? = "read chapter 3"
}

fun main() {
    val draft = Draft()
    if (draft.note != null) {
        println(draft.note.length)
    }
}
```

```
ana@vm:~/kt/l02$ kotlinc Draft.kt -include-runtime -d draft.jar
Draft.kt:9:17: error: smart cast to 'String' is impossible, because 'note' is a mutable property that could be mutated concurrently.
        println(draft.note.length)
                ^^^^^^^^^^
```

`class Draft` declara uma classe com uma propriedade, o que a aula 7 cobre. A mensagem diz o motivo
por inteiro: `note` é uma propriedade mutável que poderia ser alterada concorrentemente, então a
verificação numa linha não prova nada sobre a seguinte. **A solução é tirar uma cópia para um
`val`**, verificar a cópia e usar a cópia:

```kotlin
// DraftFixed.kt
class Draft {
    var note: String? = "read chapter 3"
}

fun main() {
    val draft = Draft()
    val note = draft.note
    if (note != null) {
        println(note.length)
    }
}
```

```
ana@vm:~/kt/l02$ kotlinc DraftFixed.kt -include-runtime -d draftfixed.jar && java -jar draftfixed.jar
14
```

O `note` local é um `val`, então nada o muda entre a verificação e o uso, e o smart cast é
permitido. A propriedade ainda muda depois; o que você imprimiu é o valor que ela tinha quando você a
copiou, que é o que você verificou.

## `is` faz cast do mesmo jeito

O mesmo mecanismo vale para qualquer verificação de tipo, não só para `null`. `if (value is String)`
faz `value` ser uma `String` dentro das chaves. A aula 9 se apoia muito nisso, porque é o que faz um
`when` sobre uma sealed class se ler tão bem.
