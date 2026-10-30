---
title: O mesmo DTO com o Moshi
version: 1
---

**O Moshi resolve o mesmo problema com adaptadores em vez de um plugin do compilador.** Um adaptador
é uma classe que lê e escreve um tipo, e o Moshi encontra o certo para cada campo. Você pode deixá-lo
montar os adaptadores por reflexão quando o app roda, ou fazer um gerador de código escrevê-los
durante o build; o gerador é mais rápido, pega erros no build, e é o que esta seção usa. Ele roda no
**KSP**, o Kotlin Symbol Processing, que o arquivo de build da seção 03 já aplica, com
`ksp(libs.moshi.codegen)` nomeando o gerador.

O DTO tem o mesmo formato com as anotações do Moshi:

```kotlin
// app/src/main/java/com/example/planner/data/SessionJson.kt
package com.example.planner.data

import com.squareup.moshi.FromJson
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass
import com.squareup.moshi.ToJson
import java.time.LocalDate

@JsonClass(generateAdapter = true)
data class SessionJson(
    val id: Long,
    @Json(name = "course_id") val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)

object LocalDateAdapter {
    @ToJson fun toJson(date: LocalDate): String = date.toString()
    @FromJson fun fromJson(text: String): LocalDate = LocalDate.parse(text)
}
```

`@JsonClass(generateAdapter = true)` pede um adaptador gerado, e `@Json(name = ...)` é o
`@SerialName` do Moshi. Um `LocalDate` precisa de ajuda aqui como precisou na seção 05, e a forma
dessa ajuda no Moshi é mais curta: qualquer objeto com um método `@ToJson` e um `@FromJson` vira um
adaptador quando é acrescentado à instância de `Moshi`.

```kotlin
// app/src/test/java/com/example/planner/data/MoshiTest.kt
package com.example.planner.data

import com.squareup.moshi.Moshi
import org.junit.Test

class MoshiTest {
    private val adapter = Moshi.Builder()
        .add(LocalDateAdapter)
        .build()
        .adapter(SessionJson::class.java)

    private fun attempt(label: String, text: String) {
        val outcome = try {
            adapter.fromJson(text).toString()
        } catch (e: Exception) {
            "${e::class.simpleName}: ${e.message}"
        }
        println("$label -> $outcome")
    }

    @Test
    fun theSameFourPayloads() {
        attempt("extra key", """{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45, "room": "B2"}""")
        attempt("no done", """{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45}""")
        attempt("no minutes", """{"id": 7, "course_id": "android", "date": "2026-10-27"}""")
        attempt("null minutes", """{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": null}""")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*MoshiTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD"
    extra key -> SessionJson(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
    no done -> SessionJson(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
    no minutes -> JsonDataException: Required value 'minutes' missing at $
    null minutes -> JsonDataException: Expected an int but was NULL at path $.minutes
MoshiTest > theSameFourPayloads PASSED
BUILD SUCCESSFUL in 6s
```

Três das quatro respostas batem com a seção 04. A quarta é a diferença que importa: **o Moshi ignora
uma chave desconhecida por padrão**, onde a kotlinx.serialization a recusa até você ligar
`ignoreUnknownKeys`. Nenhum dos dois padrões está errado, e uma equipe que leva código de uma
biblioteca para a outra sem saber disso publica um app que quebra no próximo campo do servidor.

O adaptador gerado é um arquivo Kotlin comum no diretório de build, e vale abrir uma vez:

```
ana@vm:~/planner$ find app/build/generated/ksp -name "*.kt"
app/build/generated/ksp/debug/kotlin/com/example/planner/data/SessionJsonJsonAdapter.kt
ana@vm:~/planner$ grep -nE "class SessionJsonJsonAdapter|options: JsonReader.Options|missingProperty" app/build/generated/ksp/debug/kotlin/com/example/planner/data/SessionJsonJsonAdapter.kt
26:public class SessionJsonJsonAdapter(
29:  private val options: JsonReader.Options = JsonReader.Options.of("id", "course_id", "date",
85:          id = id ?: throw Util.missingProperty("id", "id", reader),
86:          courseId = courseId ?: throw Util.missingProperty("courseId", "course_id", reader),
87:          date = date ?: throw Util.missingProperty("date", "date", reader),
88:          minutes = minutes ?: throw Util.missingProperty("minutes", "minutes", reader),
100:          id ?: throw Util.missingProperty("id", "id", reader),
101:          courseId ?: throw Util.missingProperty("courseId", "course_id", reader),
102:          date ?: throw Util.missingProperty("date", "date", reader),
103:          minutes ?: throw Util.missingProperty("minutes", "minutes", reader),
```

**Este é o código que a reflexão teria de deduzir em tempo de execução**, toda vez que o app abrisse.
Lê-lo também resolve o que o Moshi faz com uma chave ausente: o `fromJson` gerado guarda uma variável
local por campo e lança `missingProperty` para a que ainda estiver `null` no fim.

## Qual, então

| | kotlinx.serialization | Moshi com codegen |
|---|---|---|
| como o código é escrito | um plugin do compilador, dentro da classe | KSP, um adaptador gerado à parte |
| uma chave desconhecida, por padrão | um erro, até `ignoreUnknownKeys = true` | ignorada |
| um `LocalDate` | um `KSerializer` nomeado na propriedade | um objeto com `@ToJson` e `@FromJson` |
| também usada por | rotas tipadas do Navigation, Ktor | exemplos mais antigos do Retrofit, muitos apps existentes |

**Use a que o código já tem.** Duas bibliotecas de JSON num app significam dois conjuntos de regras
sobre o mesmo JSON, e o bug mora na diferença. Para um app novo este curso escolhe a
kotlinx.serialization, e a seção 07 a liga ao Retrofit.
