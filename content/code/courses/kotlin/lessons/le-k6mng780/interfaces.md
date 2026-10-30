---
title: Interfaces
version: 1
---

The planner reads sessions from somewhere: memory today, a file in a later course, a database on the
phone in `mobile-offline`. Code that shows the week should not care which. **An interface names what
a store can do, and any class that promises to do it can stand in for it.**

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

`interface Store` declares a property and two functions. `load` has no body, so every class that
implements `Store` must write one. `total` has a body, a **default implementation**, so a class may
keep it, as `MemoryStore` does, or replace it, as `FixedStore` does. `: Store` after a class's
constructor says it implements the interface, and **`override` is required on every member that
fulfils or replaces one from the interface**, so a typo in a name is a compile error rather than a
second, unrelated function.

`report` takes a `Store`, and works with both classes without knowing either. That is the whole value
of an interface: the code that uses it depends on the promise, not on who keeps it.

## A promise left unkept

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

The class claims to be a `Store` and does not provide `load`, and the compiler names the missing
member. An interface cannot hold state, so `val name: String` in an interface is a property every
implementation must provide; it has no backing field of its own. A class can implement as many
interfaces as it likes, separated by commas.
