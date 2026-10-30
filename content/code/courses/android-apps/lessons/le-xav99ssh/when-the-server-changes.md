---
title: When the server sends something you did not expect
version: 1
---

**The server and the app are released on different days.** The server team adds a field on a
Tuesday; your app, published three weeks earlier and installed on phones you cannot update, meets it
on Wednesday. So the question for a JSON library is never only "does it read today's JSON". It is
what it does with tomorrow's: a key it has never heard of, a key that is missing, a `null` where a
number should be.

Four payloads, each one a thing a real server does, decoded by the same `SessionDto`:

```kotlin
// app/src/test/java/com/example/planner/data/ServerChangesTest.kt
package com.example.planner.data

import kotlinx.serialization.json.Json
import org.junit.Test

class ServerChangesTest {
    private fun attempt(json: Json, label: String, text: String) {
        val outcome = try {
            json.decodeFromString<SessionDto>(text).toString()
        } catch (e: Exception) {
            "${e::class.simpleName}: ${e.message?.lineSequence()?.first()}"
        }
        println("$label -> $outcome")
    }

    private val extraKey =
        """{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45, "room": "B2"}"""
    private val noDone =
        """{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45}"""
    private val noMinutes =
        """{"id": 7, "course_id": "android", "date": "2026-10-27"}"""
    private val nullMinutes =
        """{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": null}"""

    @Test
    fun strict() {
        attempt(Json, "extra key", extraKey)
        attempt(Json, "no done", noDone)
        attempt(Json, "no minutes", noMinutes)
        attempt(Json, "null minutes", nullMinutes)
    }

    @Test
    fun lenient() {
        val json = Json { ignoreUnknownKeys = true }
        attempt(json, "extra key", extraKey)
        attempt(json, "null minutes", nullMinutes)
    }

    @Test
    fun coerced() {
        val json = Json { coerceInputValues = true }
        attempt(json, "null minutes", nullMinutes)
        attempt(json, "null done", noDone.replace("45}", "45, \"done\": null}"))
    }
}
```

`attempt` decodes one payload and prints either the object or the exception's class and the
first line of its message. Run only this class with `--tests`:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*ServerChangesTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD"
    extra key -> JsonDecodingException: Unexpected JSON token at offset 72: Encountered an unknown key 'room' at path: $
    no done -> SessionDto(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
    no minutes -> MissingFieldException: Field 'minutes' is required for type with serial name 'com.example.planner.data.SessionDto', but it was missing at path: $
    null minutes -> JsonDecodingException: Unexpected JSON token at offset 67: Unexpected symbol 'n' in numeric literal at path: $.minutes
ServerChangesTest > strict PASSED
    extra key -> SessionDto(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
    null minutes -> JsonDecodingException: Unexpected JSON token at offset 67: Unexpected symbol 'n' in numeric literal at path: $.minutes
ServerChangesTest > lenient PASSED
    null minutes -> JsonDecodingException: Unexpected JSON token at offset 67: Unexpected symbol 'n' in numeric literal at path: $.minutes
    null done -> SessionDto(id=7, courseId=android, date=2026-10-27, minutes=45, done=false)
ServerChangesTest > coerced PASSED
BUILD SUCCESSFUL in 6s
```

Read the four strict lines one at a time, because each is a different policy.

**An unknown key is an error by default.** The server added `room`, and the default `Json` refused
the whole session. That default is deliberate on JetBrains' side, since a key you do not know about
can be a key you misspelled, and it is the wrong default for an app on a phone. **Mobile clients
almost always set `ignoreUnknownKeys = true`**, and the second test shows the same payload read
cleanly once it is. The server can now add fields without breaking every installed copy of the app.

**A missing key with a default takes the default.** `done` was absent and became `false`, because
the DTO says `= false`. That is the right place for a default: in the type that describes the wire,
where the next person to read it sees what the app assumes.

**A missing key without one is a `MissingFieldException`.** There is no sensible number of minutes
to invent, so the DTO has no default, and the error names the field. That is the outcome you want:
loud, early, and naming the exact thing the server got wrong.

**`null` for a non-null type is an error too, and `ignoreUnknownKeys` does not change it.** The
lenient test shows `null minutes` still failing. The library has a separate setting for this,
`coerceInputValues = true`, and the third test shows what it does: a `null` for `done`, which has a
default, becomes `false`, and a `null` for `minutes`, which has none, still fails. That is the
behaviour you want. A session with no length is not a session, and no setting should invent one.

## Configure one `Json`, and share it

Every setting above belongs to an instance of `Json`, and two parts of an app that build their own
will disagree. Make one, with the settings the app needs, and use it everywhere: in section 07 it
is the one Retrofit's converter gets.

```kotlin
// app/src/main/java/com/example/planner/data/PlannerJson.kt
package com.example.planner.data

import kotlinx.serialization.json.Json

val plannerJson = Json {
    ignoreUnknownKeys = true
}
```
