---
title: Interfaces
version: 1
---

O planejador lê sessões de algum lugar: da memória hoje, de um arquivo na aula 13, de um
banco de dados no celular no `mobile-offline`. O código que mostra a semana não deveria se importar
com qual. **Uma interface nomeia o que um armazenamento sabe fazer, e qualquer classe que prometa
fazê-lo pode ocupar o lugar dele.**

```kotlin
// Interfaces.kt
interface Store {
    val name: String
    fun load(): List<Int>
    fun total(): Int = load().sum()
}

class MemoryStore(private val minutes: List<Int>) : Store {
    override val name = "memory"
    override fun load() = minutes
}

class FixedStore : Store {
    override val name = "fixed"
    override fun load() = listOf(60, 60)
    override fun total() = 120
}

fun report(store: Store) = "${store.name}: ${store.total()} min"

fun main() {
    println(report(MemoryStore(listOf(45, 30))))
    println(report(FixedStore()))
}
```

```
ana@vm:~/kt/l11$ kotlinc Interfaces.kt -include-runtime -d interfaces.jar && java -jar interfaces.jar
memory: 75 min
fixed: 120 min
```

`interface Store` declara uma propriedade e duas funções. `load` não tem corpo, então toda classe que
implementa `Store` precisa escrever um. `total` tem corpo, uma **implementação padrão**, então uma
classe pode mantê-la, como `MemoryStore` faz, ou trocá-la, como `FixedStore` faz. `: Store` depois do
construtor de uma classe diz que ela implementa a interface, e **o `override` é obrigatório em todo
membro que cumpre ou troca um da interface**, então um erro de grafia num nome é um erro de compilação
e não uma segunda função sem relação.

`report` recebe um `Store`, e funciona com as duas classes sem conhecer nenhuma. Esse é todo o valor de
uma interface: o código que a usa depende da promessa, não de quem a cumpre.

## Uma promessa não cumprida

```kotlin
// Broken.kt
interface Store {
    fun load(): List<Int>
}

class Broken : Store

fun main() {
    println(Broken().load())
}
```

```
ana@vm:~/kt/l11$ kotlinc Broken.kt -include-runtime -d broken.jar
Broken.kt:6:1: error: class 'Broken' is not abstract and does not implement abstract member:
fun load(): List<Int>
class Broken : Store
^^^^^^^^^^^^
```

A classe diz ser um `Store` e não fornece o `load`, e o compilador nomeia o membro que falta. Uma
interface não guarda estado, então `val name: String` numa interface é uma propriedade que toda
implementação precisa fornecer; ela não tem campo de apoio próprio. Uma classe implementa quantas
interfaces quiser, separadas por vírgula.
