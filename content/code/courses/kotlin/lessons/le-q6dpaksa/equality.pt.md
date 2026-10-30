---
title: == e ===
version: 1
---

A aula 1 disse que o `==` do Kotlin chama o `equals`, e prometeu o `===` para depois. **O `==`
pergunta se dois valores são iguais; o `===` pergunta se são o mesmo objeto**, o mesmo lugar na
memória.

```kotlin
// Identity.kt
data class Session(val course: String, val minutes: Int)

fun main() {
    val a = Session("Kotlin", 45)
    val b = Session("Kotlin", 45)
    val c = a
    println(a == b)
    println(a === b)
    println(a === c)
    println(a != b)
    println(a !== b)
}
```

```
ana@vm:~/kt/l08$ kotlinc Identity.kt -include-runtime -d identity.jar && java -jar identity.jar
true
false
true
false
true
```

`a` e `b` foram montados separados com os mesmos valores: iguais, e dois objetos. `c = a` copia a
referência, não o objeto, então `a === c` é verdadeiro: uma sessão com dois nomes. `!=` e `!==` são as
negações.

## O `==` é seguro contra nulo

`a == b` não é exatamente `a.equals(b)`. É `a?.equals(b) ?: (b === null)`: **quando `a` é null ele não
lança exceção**, responde se `b` também é null. É por isso que o `==` funciona em valores anuláveis sem
chamada segura, onde o `a.equals(b)` do Java lançaria exceção com um `a` null.

## Qual você quer

Quase sempre `==`. **O `===` é para a rara pergunta "este é o mesmo objeto que eu já tenho"**: um cache
verificando que recebeu de volta a instância que guardou, ou um teste verificando que uma função
devolveu o próprio argumento e não uma cópia. Usar `===` para comparar valores é o bug do `==` do Java
de volta, e pode parecer que funciona:

```kotlin
// Interned.kt
fun main() {
    val a = "Kotlin"
    val b = "Kotlin"
    val c = "Kot" + "lin".lowercase()
    println(a === b)
    println(a === c)
    println(a == c)
}
```

```
ana@vm:~/kt/l08$ kotlinc Interned.kt -include-runtime -d interned.jar && java -jar interned.jar
true
false
true
```

`a === b` é `true` porque a JVM guarda uma cópia de cada literal de string e os dois nomes apontam para
ela. `c` é montada em tempo de execução, então é outro objeto com os mesmos caracteres, e o `===` diz
`false`. **Uma comparação que acerta com literais e erra com valores calculados é o tipo de bug que
passa em todo teste escrito com literais**, que é a maioria dos testes. O `==` deu a resposta certa
nos três.
