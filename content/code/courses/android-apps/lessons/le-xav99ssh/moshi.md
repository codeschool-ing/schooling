---
title: The same DTO with Moshi
version: 1
---

**Moshi solves the same problem with adapters instead of a compiler plugin.** An adapter is a
class that reads and writes one type, and Moshi finds the right one for each field. You can have it
build adapters by reflection when the app runs, or have a code generator write them while the
project builds; the generator is faster, catches mistakes at build time, and is what this section
uses. It runs on **KSP**, the Kotlin Symbol Processing tool, which the build file of section 03
already applies, with `ksp(libs.moshi.codegen)` naming the generator.

The DTO is the same shape with Moshi's annotations:

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

`@JsonClass(generateAdapter = true)` asks for a generated adapter, and `@Json(name = ...)` is
Moshi's `@SerialName`. A `LocalDate` needs help here as it did in section 05, and Moshi's form of
that help is shorter: any object with a `@ToJson` and a `@FromJson` method becomes an adapter when
it is added to the `Moshi` instance.

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

Three of the four answers match section 04. The fourth is the difference that matters:
**Moshi ignores an unknown key by default**, where kotlinx.serialization refuses one until you set
`ignoreUnknownKeys`. Neither default is wrong, and a team moving code from one library to the other
that does not know this ships an app that breaks on the server's next field.

The generated adapter is an ordinary Kotlin file in the build directory, and worth opening once:

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

**This is the code reflection would otherwise have worked out at run time**, every time the app
started. Reading it also settles what Moshi does with a missing key: the generated `fromJson` keeps a
local variable per field and throws `missingProperty` for one that is still `null` at the end.

## Which one, then

| | kotlinx.serialization | Moshi with codegen |
|---|---|---|
| how the code is written | a compiler plugin, inside the class | KSP, a separate generated adapter |
| an unknown key, by default | an error, until `ignoreUnknownKeys = true` | ignored |
| a `LocalDate` | a `KSerializer` named on the property | an object with `@ToJson` and `@FromJson` |
| also used by | Navigation's type-safe routes, Ktor | Retrofit's older examples, many existing apps |

**Use the one the codebase already has.** Two JSON libraries in one app means two sets of rules
about the same JSON, and the bug lives in the difference. For a new app this course picks
kotlinx.serialization, and section 07 plugs it into Retrofit.
