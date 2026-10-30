---
title: Closures: o que uma lambda lembra
version: 1
---

Uma lambda usa nomes de em volta dela, os parâmetros e as variáveis locais da função em que foi
escrita. **Ela não copia os valores; guarda as próprias variáveis**, e as guarda enquanto a lambda
existir, mesmo depois de a função que as declarou já ter retornado. Uma lambda junto com as variáveis
que ela segura se chama closure.

```kotlin
// Closures.kt
fun makeCounter(): () -> Int {
    var count = 0
    return { ++count }
}

fun main() {
    var total = 0
    val add: (Int) -> Unit = { total += it }
    add(45)
    add(30)
    println(total)

    val next = makeCounter()
    println(next())
    println(next())
    val other = makeCounter()
    println(other())
    println(next())
}
```

```
ana@vm:~/kt/l04$ kotlinc Closures.kt -include-runtime -d closures.jar && java -jar closures.jar
75
1
2
1
3
```

Duas coisas acontecem aqui que uma cópia de valor não explicaria.

**`add` mudou `total`.** A lambda segura o próprio `total`, um `var` do `main`, então `total += it`
muda a variável que o `main` imprime. As lambdas do Java não fazem isso: só leem variáveis locais que
são efetivamente finais. O Kotlin permite, e na JVM isso funciona movendo `total` para um pequeno
objeto no heap para onde o `main` e a lambda apontam.

**`makeCounter` retornou, e `count` continuou vivo.** Cada chamada a `makeCounter` cria um `count`
novo e uma lambda que o segura. `next` e `other` seguram `count` diferentes, e é por isso que
`other()` imprimiu 1 enquanto `next()` seguiu até 3. A variável sobreviveu à função que a declarou,
porque uma lambda ainda precisava dela.

## A surpresa que isso causa

Uma lambda lê a variável quando roda, não quando foi escrita:

```kotlin
// Late.kt
fun main() {
    var course = "Kotlin"
    val show = { println("studying $course") }
    course = "Android"
    show()
}
```

```
ana@vm:~/kt/l04$ kotlinc Late.kt -include-runtime -d late.jar && java -jar late.jar
studying Android
```

`show` foi escrita quando `course` era `"Kotlin"` e imprimiu `"Android"`, porque, na hora em que
rodou, esse era o valor da variável que ela segura. **A solução, quando você quer o valor do momento
em que escreveu, é uma cópia `val`**, tirada antes de a lambda ser criada. É a mesma regra dos smart
casts da lição 2, vista do outro lado: um `var` que outra coisa enxerga é um `var` que muda debaixo de
você.

Isso importa mais adiante, nas lições 14 e 15, quando uma lambda roda em outra thread ou depois de um
atraso. Uma closure que captura um `var` e roda em outro lugar é o jeito clássico de ler um valor que
já mudou, e as corrotinas do Kotlin foram desenhadas para você raramente precisar de uma.
