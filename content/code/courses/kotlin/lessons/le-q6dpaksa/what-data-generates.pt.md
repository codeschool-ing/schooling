---
title: O que uma palavra gera
version: 1
---

A `Course` da lição 7 era impressa como `Course@677327b6`, e dois cursos com o mesmo nome e a mesma
meta não eram iguais. Os dois são os padrões da JVM para um objeto, e os dois estão errados para uma
classe cujo trabalho inteiro é guardar valores. **`data` na frente de `class` diz ao compilador que a
classe é os seus valores**, e ele escreve as funções que decorrem disso:

```kotlin
// Data.kt
data class Session(val course: String, val minutes: Int, val done: Boolean = false)

fun main() {
    val a = Session("Kotlin", 45)
    val b = Session("Kotlin", 45)
    println(a)
    println(a == b)
    println(a.hashCode() == b.hashCode())
    println(setOf(a, b).size)
}
```

```
ana@vm:~/kt/l08$ kotlinc Data.kt -include-runtime -d data.jar && java -jar data.jar
Session(course=Kotlin, minutes=45, done=false)
true
true
1
```

O mesmo programa sem o `data`:

```kotlin
// Plain.kt
class Session(val course: String, val minutes: Int, val done: Boolean = false)

fun main() {
    val a = Session("Kotlin", 45)
    val b = Session("Kotlin", 45)
    println(a)
    println(a == b)
    println(a.hashCode() == b.hashCode())
    println(setOf(a, b).size)
}
```

```
ana@vm:~/kt/l08$ kotlinc Plain.kt -include-runtime -d plain.jar && java -jar plain.jar
Session@677327b6
false
false
2
```

Quatro linhas, quatro diferenças, todas por causa de uma palavra. O que o compilador gerou, a partir
das propriedades do construtor primário:

| função | o que faz |
|---|---|
| `toString()` | `Session(course=Kotlin, minutes=45, done=false)`: a classe e cada propriedade |
| `equals()` | duas sessões são iguais quando cada propriedade é igual |
| `hashCode()` | sessões iguais têm hash codes iguais, então conjuntos e chaves de mapa funcionam |
| `copy()` | uma sessão nova com algumas propriedades mudadas, seção 04 |
| `component1()`, `component2()`, … | uma por propriedade, em ordem, para a desestruturação, seção 05 |

**O conjunto é a linha que mais importa.** Sem `data`, um conjunto de sessões guarda duas sessões
idênticas, um mapa com chave de sessão nunca encontra a chave que recebeu um momento antes, e o
`distinct()` não remove nada. São bugs que não mostram erro: o programa roda e os números saem
errados.

## Quando uma classe deve ser data class

Quando dois objetos com os mesmos valores são a mesma coisa. Duas sessões planejadas de 45 minutos de
Kotlin no mesmo dia são intercambiáveis, assim como duas quantias de dinheiro ou duas datas. Um
`Tracker` da lição 7, com um registro que muda, não é: dois rastreadores com totais iguais continuam
sendo dois rastreadores diferentes, e uma data class diria que são iguais. **Data classes são para
valores; classes comuns são para coisas com identidade própria.** A maior parte do que um app Android
passa entre as camadas é do primeiro tipo, e é por isso que o `android-apps` declara data classes em
todo lugar.
