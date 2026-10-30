---
title: Dates, and the serializer you write yourself
version: 1
---

**A date kept as a `String` is a date nobody can do arithmetic with.** The week's total needs to
know whether a session falls between Monday and Sunday. `"2026-10-27" < "2026-11-02"` happens to
work for this format, and stops working the day the server writes `27/10/2026`. The model holds a
`java.time.LocalDate`, so the obvious move is to put one in the DTO as well:

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

This time the plugin is present, and it refuses at compile time:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "^e: |^BUILD"
e: file:///home/ana/planner/app/src/main/java/com/example/planner/data/SessionDto.kt:12:15 Serializer was not found for type 'LocalDate'. To use a context serializer as the fallback, explicitly annotate type or property with '@Contextual'.
BUILD FAILED in 3s
```

**kotlinx.serialization knows Kotlin's types and its own, and `LocalDate` is Java's.** The plugin
has to write code that reads a `LocalDate` field, it has no serializer for that class, and it says
so naming the file and the line. The cure is a serializer of your own: an object that says how one
`LocalDate` is written as a primitive and read back.

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/data/LocalDateSerializer.kt", "parts": [
 {"code": "// app/src/main/java/com/example/planner/data/LocalDateSerializer.kt\npackage com.example.planner.data\n\nimport java.time.LocalDate\nimport kotlinx.serialization.KSerializer\nimport kotlinx.serialization.descriptors.PrimitiveKind\nimport kotlinx.serialization.descriptors.PrimitiveSerialDescriptor\nimport kotlinx.serialization.encoding.Decoder\nimport kotlinx.serialization.encoding.Encoder"},
 {"code": "object LocalDateSerializer : KSerializer<LocalDate> {\n    override val descriptor =\n        PrimitiveSerialDescriptor(\"java.time.LocalDate\", PrimitiveKind.STRING)", "note": "The descriptor says what shape the value has on the wire: one string. The name only has to be unique among the serializers of the app."},
 {"code": "    override fun serialize(encoder: Encoder, value: LocalDate) =\n        encoder.encodeString(value.toString())", "note": "Writing: `LocalDate.toString()` is ISO 8601, `2026-10-27`, which is what the server sends."},
 {"code": "    override fun deserialize(decoder: Decoder): LocalDate =\n        LocalDate.parse(decoder.decodeString())\n}", "note": "Reading: `LocalDate.parse` accepts exactly that form and throws on anything else, so a malformed date is an error and never a wrong date."}
]}
```

And the DTO names it on the one property that needs it:

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

## The function between the two types

The last piece is the mapping of section 02, from the DTO to the model, and it lives beside the
DTO because it is the one place that knows both:

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

It looks too simple to bother with today, because the two classes still have the same fields. The
first time the server renames `minutes` to `duration_min` or sends the date as a timestamp, this
function and the DTO change and nothing else does.

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

The session's date is a real `LocalDate`: it knows it is a Tuesday and which Monday starts its week,
which is the arithmetic the week's total needs. The last line feeds the same JSON with the date in a
different format, and **the serializer refuses it** rather than storing something wrong, with the
parser's own message. A failure you can read beats a week total that is quietly off.
