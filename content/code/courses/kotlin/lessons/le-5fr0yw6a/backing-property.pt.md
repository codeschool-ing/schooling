---
title: Um MutableStateFlow privado e um StateFlow público
version: 1
---

Se toda tela pudesse definir o total, ninguém saberia quem o definiu, e um bug que escreve 0 poderia
estar em qualquer lugar. A lição 5 tinha a resposta para listas, uma `MutableList` privada entregue como
`List`, e a forma aqui é a mesma. **A classe dona do estado guarda um `MutableStateFlow` privado e o expõe
como um `StateFlow` somente leitura**; as mudanças passam pelas funções dela.

```kotlin
// src/main/kotlin/Backing.kt
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

class WeekTotal {
    private val _minutes = MutableStateFlow(0)
    val minutes: StateFlow<Int> = _minutes.asStateFlow()

    fun add(m: Int) {
        require(m > 0) { "minutes must be positive: $m" }
        _minutes.update { it + m }
    }
}

fun main() {
    val week = WeekTotal()
    week.add(45)
    week.add(30)
    println(week.minutes.value)
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=BackingKt
75
```

O nome com sublinhado para a metade privada é uma convenção que os guias de estilo do Kotlin e do
Android descrevem: `_minutes` é a propriedade de apoio, `minutes` a que o mundo vê. **O `asStateFlow()` a
embrulha para quem chama não conseguir fazer cast de volta para `MutableStateFlow`** e escrever pelo cast.
Escrever de fora é recusado na compilação:

```kotlin
// src/main/kotlin/BackingWrite.kt
fun main() {
    val week = WeekTotal()
    week.minutes.value = 0
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=BackingWriteKt 2>&1 | head -3
e: file:///home/ana/kt/planner/src/main/kotlin/BackingWrite.kt:4:18 'val' cannot be reassigned.

FAILURE: Build failed with an exception.
```

Apague o `BackingWrite.kt` depois de ver a mensagem, como o `NotSuspend.kt` da lição 14.

## `update`, não `value +=`

`_minutes.value += m` lê o valor e escreve um novo em dois passos. Se duas corrotinas em threads
diferentes fizerem isso no mesmo instante, as duas podem ler 45 e as duas escrever 45 mais os próprios
minutos, e uma soma se perde. **O `update { it + m }` tenta de novo até a leitura e a escrita acontecerem
sem nada no meio**, então somas concorrentes contam todas. O planejador roda numa thread hoje; o
`android-apps` não, e o hábito não custa nada.
