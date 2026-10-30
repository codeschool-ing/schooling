---
title: Visibilidade: public, private, protected e internal
version: 1
---

Tudo em Kotlin é **público por padrão**: visível para qualquer código que enxergue a classe. O padrão
do Java é privado ao pacote, e o Kotlin escolheu o contrário porque a maioria das declarações de uma
biblioteca existe para ser usada. Os outros três modificadores estreitam isso:

| modificador | num membro de classe | no topo de um arquivo |
|---|---|---|
| `public` (o padrão) | visível em todo lugar | visível em todo lugar |
| `private` | só dentro desta classe | só dentro deste arquivo |
| `protected` | esta classe e as subclasses dela | não permitido |
| `internal` | em qualquer lugar do mesmo **módulo** | em qualquer lugar do mesmo módulo |

Um módulo é o que é compilado junto: um módulo Gradle, uma execução do `kotlinc`. O `internal` importa
quando a lição 19 divide o planejador em módulos, onde ele quer dizer "público dentro deste módulo,
invisível para os outros".

## Escondendo as partes que cumprem uma promessa

O rastreador do planejador guarda um registro das sessões e um total corrente, e o total precisa ser
sempre igual à soma do registro. **Essa promessa só vale se nada mais escrever em nenhum dos dois**:

```kotlin
// Tracker.kt
class Tracker {
    private val log = mutableListOf<Int>()
    var total: Int = 0
        private set

    fun add(minutes: Int) {
        log.add(minutes)
        total += minutes
    }

    fun sessions(): List<Int> = log.toList()
}

fun main() {
    val t = Tracker()
    t.add(45)
    t.add(30)
    println(t.total)
    println(t.sessions())
    t.total = 0
}
```

```
ana@vm:~/kt/l07$ kotlinc Tracker.kt -include-runtime -d tracker.jar
Tracker.kt:21:7: error: cannot access 'total': it is private in 'Tracker'.
    t.total = 0
      ^^^^^
```

`log` é privado, então só o `add` o muda. `total` tem getter público e `private set`, então a última
linha, que tenta zerá-lo de fora, é recusada pelo nome. Tire-a e o programa roda:

```kotlin
// TrackerOk.kt
class Tracker {
    private val log = mutableListOf<Int>()
    var total: Int = 0
        private set

    fun add(minutes: Int) {
        log.add(minutes)
        total += minutes
    }

    fun sessions(): List<Int> = log.toList()
}

fun main() {
    val t = Tracker()
    t.add(45)
    t.add(30)
    println(t.total)
    println(t.sessions())
}
```

```
ana@vm:~/kt/l07$ kotlinc TrackerOk.kt -include-runtime -d trackerok.jar && java -jar trackerok.jar
75
[45, 30]
```

`sessions()` devolve uma cópia, como a lição 5 aconselhou, então quem recebe a lista não alcança o
rastreador por ela. **A classe agora é o único código capaz de quebrar a própria promessa**, o que
torna a promessa algo que se verifica num arquivo só.

## Comece privado

O hábito que decorre disso é o mesmo de `val` antes de `var`: **deixe um membro `private` até algo de
fora precisar dele**. Alargar depois é uma mudança de uma palavra que não quebra ninguém; estreitar um
membro público depois quebra todo chamador que já o usa.
