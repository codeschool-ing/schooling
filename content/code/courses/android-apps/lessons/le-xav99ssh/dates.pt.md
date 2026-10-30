---
title: Datas, e o serializador que você mesmo escreve
version: 1
---

**Uma data guardada como `String` é uma data com a qual ninguém consegue fazer conta.** O total da
semana precisa saber se uma sessão cai entre segunda e domingo. `"2026-10-27" < "2026-11-02"` por
acaso funciona neste formato, e para de funcionar no dia em que o servidor escrever `27/10/2026`. O
modelo guarda um `java.time.LocalDate`, então o passo óbvio é pôr um no DTO também:

```kotlin
// app/src/main/java/com/example/planner/data/SessionDto.kt
package com.example.planner.data

import java.time.LocalDate
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SessionDto(
    val id: Long,
    @SerialName("course_id") val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)
```

Desta vez o plugin está presente, e ele recusa em tempo de compilação:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "^e: |^BUILD"
e: file:///home/ana/planner/app/src/main/java/com/example/planner/data/SessionDto.kt:12:15 Serializer was not found for type 'LocalDate'. To use a context serializer as the fallback, explicitly annotate type or property with '@Contextual'.
BUILD FAILED in 3s
```

**A kotlinx.serialization conhece os tipos do Kotlin e os seus próprios, e `LocalDate` é do Java.**
O plugin precisa escrever código que leia um campo `LocalDate`, não tem serializador para essa
classe, e diz isso nomeando o arquivo e a linha. A cura é um serializador seu: um objeto que diz como
um `LocalDate` é escrito como primitivo e lido de volta.

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/data/LocalDateSerializer.kt", "parts": [{"code": "// app/src/main/java/com/example/planner/data/LocalDateSerializer.kt\npackage com.example.planner.data\n\nimport java.time.LocalDate\nimport kotlinx.serialization.KSerializer\nimport kotlinx.serialization.descriptors.PrimitiveKind\nimport kotlinx.serialization.descriptors.PrimitiveSerialDescriptor\nimport kotlinx.serialization.encoding.Decoder\nimport kotlinx.serialization.encoding.Encoder"}, {"code": "object LocalDateSerializer : KSerializer<LocalDate> {\n    override val descriptor =\n        PrimitiveSerialDescriptor(\"java.time.LocalDate\", PrimitiveKind.STRING)", "note": "O descritor diz que forma o valor tem no fio: uma string. O nome só precisa ser único entre os serializadores do app."}, {"code": "    override fun serialize(encoder: Encoder, value: LocalDate) =\n        encoder.encodeString(value.toString())", "note": "Escrita: `LocalDate.toString()` é ISO 8601, `2026-10-27`, que é o que o servidor manda."}, {"code": "    override fun deserialize(decoder: Decoder): LocalDate =\n        LocalDate.parse(decoder.decodeString())\n}", "note": "Leitura: `LocalDate.parse` aceita exatamente essa forma e lança exceção para qualquer outra, então uma data malformada é um erro e nunca uma data errada."}]}
```

E o DTO o nomeia na única propriedade que precisa dele:

```kotlin
// app/src/main/java/com/example/planner/data/SessionDto.kt
package com.example.planner.data

import java.time.LocalDate
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SessionDto(
    val id: Long,
    @SerialName("course_id") val courseId: String,
    @Serializable(with = LocalDateSerializer::class) val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)
```

## A função entre os dois tipos

A última peça é o mapeamento da seção 02, do DTO para o modelo, e ele mora ao lado do DTO porque é o
único lugar que conhece os dois:

```kotlin
// app/src/main/java/com/example/planner/data/Mapping.kt
package com.example.planner.data

fun SessionDto.toDomain() = StudySession(
    id = id,
    courseId = courseId,
    date = date,
    minutes = minutes,
    done = done,
)
```

Parece simples demais para valer a pena hoje, porque as duas classes ainda têm os mesmos campos. Na
primeira vez em que o servidor renomear `minutes` para `duration_min` ou mandar a data como
timestamp, esta função e o DTO mudam e nada mais muda.

```kotlin
// app/src/test/java/com/example/planner/data/DatesTest.kt
package com.example.planner.data

import java.time.DayOfWeek
import org.junit.Test

class DatesTest {
    @Test
    fun aDateIsADate() {
        val text = """{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45}"""
        val session = plannerJson.decodeFromString<SessionDto>(text).toDomain()
        println(session)
        println("${session.date.dayOfWeek}, week starts ${session.date.with(DayOfWeek.MONDAY)}")
        try {
            plannerJson.decodeFromString<SessionDto>(text.replace("2026-10-27", "27/10/2026"))
        } catch (e: Exception) {
            println("${e::class.simpleName}: ${e.message}")
        }
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*DatesTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD"
    StudySession(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
    TUESDAY, week starts 2026-10-26
    JsonDecodingException: Deserialization failed because of 'Text '27/10/2026' could not be parsed at index 0' exception in the decoder at path: $.date
    JSON input: {"id": 7, "course_id": "android", "date": "27/10/2026", "minutes": 45}
DatesTest > aDateIsADate PASSED
BUILD SUCCESSFUL in 6s
```

A data da sessão é um `LocalDate` de verdade: sabe que é uma terça e qual segunda começa a sua
semana, que é a conta de que o total da semana precisa. A última linha alimenta o mesmo JSON com a
data noutro formato, e **o serializador a recusa** em vez de guardar algo errado, com a própria
mensagem do parser. Uma falha que dá para ler vale mais que um total da semana errado em silêncio.
