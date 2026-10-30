---
title: What arrives over the wire, and the type it becomes
version: 1
---

**A server sends text, and the app needs objects.** Somewhere between the bytes Retrofit received
in lesson 13 and the `StudySession` a screen draws, a string like the one below has to become a
Kotlin value, field by field, with every field checked. That step is **deserialisation**, the
reverse is **serialisation**, and this lesson is about doing both without writing the parsing
yourself.

This is one study session as the planner's server sends it:

```json
{"id": 7, "course_id": "android", "date": "2026-10-27", "minutes": 45, "done": false}
```

Three things in it do not match the model the app uses. The server writes `course_id` in snake
case where Kotlin writes `courseId`; the date is a string, where the app wants a `LocalDate` it can
compare and add days to; and nothing promises that tomorrow's server will not add a sixth key. Each
of those is a section of this lesson.

## Two types, on purpose

The model is the one every lesson of this course uses:

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

**The JSON does not go straight into `StudySession`.** It goes into a second class shaped like the
JSON, a **DTO**, for *data transfer object*, and a small function turns one into the other. That
looks like duplication and is the opposite: the DTO changes when the server changes, the model
changes when the app changes, and the function between them is the one place that knows both. A
screen that read the DTO directly would break on the day the server renamed a field, and so would
every test of it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A study session travels from left to right. The server sends JSON text with course_id in snake case and the date as a string. A serialisation library turns it into a SessionDto, the same fields with the same names. A function called toDomain turns the DTO into a StudySession, with courseId and a LocalDate. The screens only ever see the StudySession. A change on the server stops at the DTO and the function.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"200\" fill=\"var(--ink)\"></rect><rect x=\"20\" y=\"50\" width=\"190\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"115\" y=\"74\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">JSON text</text><text x=\"115\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"course_id\"</text><text x=\"115\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"2026-10-27\"</text><rect x=\"265\" y=\"50\" width=\"190\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"360\" y=\"74\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">SessionDto</text><text x=\"360\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">shaped like the server</text><text x=\"360\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">changes when it changes</text><rect x=\"510\" y=\"50\" width=\"190\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"605\" y=\"74\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">StudySession</text><text x=\"605\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">shaped like the app</text><text x=\"605\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what every screen reads</text><line x1=\"212\" y1=\"90\" x2=\"262\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"457\" y1=\"90\" x2=\"507\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"237\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the library</text><text x=\"482\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">toDomain()</text><text x=\"360\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a change on the server stops here, at the DTO and the function</text></svg>", "caption": "The JSON is read into a DTO shaped like the server, and one function turns it into the model the screens use."}
```

## Two libraries that do the same job

This lesson does the job twice, with the two libraries an Android codebase is most likely to have:

- **kotlinx.serialization**, from JetBrains, the people who make Kotlin. A compiler plugin writes
  the code that reads and writes each class while your code compiles, so nothing is looked up by
  reflection when the app runs.
- **Moshi**, from Square, the company behind Retrofit and OkHttp. It reads and writes through
  adapters, and with its code generator, run by KSP, those adapters are generated at build time too.

New code in this course uses kotlinx.serialization, because it is Kotlin's own and lesson 9's
type-safe routes already depend on its plugin. Moshi gets section 06 because a great deal of
existing Android code uses it, and the two disagree about one default that matters.
