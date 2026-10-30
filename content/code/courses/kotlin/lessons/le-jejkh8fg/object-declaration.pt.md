---
title: object: uma classe com exatamente uma instância
version: 1
---

Às vezes um programa precisa de um de alguma coisa: uma configuração, um registro, um relógio. O Java
faz isso com uma classe, um construtor privado e um campo estático guardando a única instância, e erra
os detalhes com frequência suficiente para "singleton" ser uma palavra que faz as pessoas suspirarem.
**O `object` do Kotlin declara uma classe e a única instância dela de uma vez**, e a linguagem cuida de
criá-la exatamente uma vez.

```kotlin
// Planner.kt
object Planner {
    private val sessions = mutableListOf<Int>()

    init {
        println("Planner created")
    }

    fun add(minutes: Int) {
        sessions.add(minutes)
    }

    val total: Int
        get() = sessions.sum()
}

fun main() {
    println("start")
    Planner.add(45)
    Planner.add(30)
    println(Planner.total)
    println(Planner === Planner)
}
```

```
ana@vm:~/kt/l10$ kotlinc Planner.kt -include-runtime -d planner.jar && java -jar planner.jar
start
Planner created
75
true
```

`Planner` é usado pelo nome, sem chamada de construtor: o nome **é** a instância. Ele tem
propriedades, funções e um bloco `init` como qualquer classe, e nenhum parâmetro de construtor, porque
ninguém chama construtor.

## Criado no primeiro uso

`start` foi impresso antes de `Planner created`. **O objeto é montado na primeira vez em que algo
encosta nele**, não quando o programa começa, e a JVM garante que isso aconteça uma vez mesmo que duas
threads encostem nele no mesmo instante. Essa é a parte que os singletons escritos à mão em Java erram,
e aqui ela não é código seu.

## Para que serve um `object`

Um `object` serve para **algo que não tem estado próprio, ou cujo estado é de fato um só para o
programa inteiro**: um conjunto de funções auxiliares que andam juntas, uma tabela de constantes, uma
implementação padrão de uma interface. As sessões do planejador são o exemplo errado de propósito. Uma
lista global de sessões é fácil de começar, e a seção 07 mostra quanto ela custa na primeira vez em que
duas partes do programa, ou dois testes, acham que são donas dela.
