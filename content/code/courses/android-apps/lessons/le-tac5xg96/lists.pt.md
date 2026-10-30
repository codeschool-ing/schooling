---
title: Uma lista de fotos, e a aritmética da rolagem
version: 1
---

**Uma lista multiplica tudo o que as seções 03 e 04 mediram.** Uma capa no tamanho certo tem 852.800
bytes; uma lista de quarenta cartões são quarenta delas, e uma rolagem rápida pede uma dúzia num
segundo. Três coisas mantêm isso acessível, e o planner já tem duas: capas decodificadas no tamanho
do cartão, e um cache em memória com limite, que descarta o que saiu da tela há mais tempo. A terceira
é que um cartão que sai da tela cancela o seu pedido, o que o `AsyncImage` faz sozinho porque o
pedido pertence ao tempo de vida do composable.

A lista de cursos é a `LazyColumn` da aula 8 com uma capa em cada cartão:

```kotlin
// app/src/main/java/com/example/planner/ui/CourseList.kt
package com.example.planner.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import com.example.planner.data.Course

@Composable
fun CourseList(courses: List<Course>, coverOf: (Course) -> String?) {
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        items(courses, key = { it.id }) { course ->
            CourseCard(course.name, coverOf(course))
        }
    }
}
```

```kotlin
// app/src/main/java/com/example/planner/data/Model.kt
package com.example.planner.data

import java.time.LocalDate

data class Course(val id: String, val name: String)

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)
```

**`key = { it.id }` importa mais com imagens do que sem elas.** Ele amarra o estado de cada item,
inclusive a capa carregada, ao curso e não à posição, então um curso inserido no topo não faz todo
cartão abaixo dele mostrar a imagem do vizinho por um quadro.

## O que o cache guarda depois de uma rolagem

O teste carrega quarenta capas diferentes pelo carregador do app, primeiro no tamanho do cartão e
depois, num segundo carregador, em tamanho cheio, como faria uma lista sem pedidos dimensionados, e lê
o cache em memória depois de cada rodada:

```kotlin
// app/src/test/java/com/example/planner/ListMemoryTest.kt
package com.example.planner

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import coil3.imageDecoderEnabled
import coil3.request.ImageRequest
import kotlinx.coroutines.runBlocking
import mockwebserver3.MockWebServer
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class ListMemoryTest {
    @Test
    fun fortyCovers(): Unit = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val server = MockWebServer().apply { serveCovers(80) }
        server.start()
        for (sized in listOf(true, false)) {
            val loader = plannerImageLoader(context).newBuilder()
                .imageDecoderEnabled(false)
                .diskCache(null)
                .build()
            for (i in 1..40) {
                val request = ImageRequest.Builder(context)
                    .data(server.url("/covers/$sized/$i.png").toString())
                    .apply { if (sized) size(720, 400) }
                    .build()
                loader.execute(request)
            }
            val cache = loader.memoryCache!!
            println("sized=$sized: ${cache.size} of ${cache.maxSize} bytes held")
        }
        server.close()
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*ListMemoryTest" 2>&1 | grep -E "^    [a-z]|PASSED|FAILED|^BUILD|^e: "
    sized=true: 2558400 of 3355443 bytes held
    sized=false: 0 of 3355443 bytes held
ListMemoryTest > fortyCovers PASSED
BUILD SUCCESSFUL in 39s
```

**O limite é o primeiro número a ler: 3.355.443 bytes.** É um quinto da memória que o aparelho que o
Robolectric imita permite a um app, e é pequeno; um celular com mais memória dá um limite maior pela
mesma regra. Capas dimensionadas de 852.800 bytes cabem três por vez, e o cache guarda as três vistas
mais recentemente, que são as que uma rolagem para trás pediria primeiro.

**Sem tamanho, o cache não guardou nada.** Cada bitmap de 48.000.000 bytes é maior que o limite
inteiro, e o Coil não guarda uma entrada maior que o seu cache. Toda capa que voltasse à tela seria
decodificada de novo a partir do disco ou baixada de novo, a 48 MB por vez. Num celular cujo limite
seja dez vezes maior a história é a mesma, porque dez vezes 3,4 MB ainda é menos que uma capa sem
tamanho. É assim que uma lista de fotos engasga num celular que parece ter memória de sobra.

Os quatro testes da aula, juntos:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "PASSED|FAILED|^BUILD"
BitmapMemoryTest > theSizeIsTheMemory PASSED
CacheTest > memoryThenDisk PASSED
ListMemoryTest > fortyCovers PASSED
StatesScreenshotTest > fourStates PASSED
BUILD SUCCESSFUL in 40s
```

**Não executado:** a mesma rolagem num celular, observada com o profiler de memória do Android
Studio, que mostra os bitmaps como alocações enquanto a lista se mexe. Os números acima são as
contagens de bytes dos próprios bitmaps, lidas na JVM.
