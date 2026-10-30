---
title: Entities: a class that is a table
version: 1
---

**An entity is a data class with `@Entity` on it, and every property becomes a column.** Room
names the table and the columns after the class and its properties unless you say otherwise, and
for a table other code will query by hand, saying otherwise is worth it: SQL is written in
`snake_case` by convention, and the planner's server speaks it too.

```kotlin
// app/src/main/java/com/example/planner/data/Entities.kt
package com.example.planner.data

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.time.LocalDate

@Entity(tableName = "courses")
data class CourseEntity(
    @PrimaryKey val id: String,
    val name: String,
)

@Entity(
    tableName = "sessions",
    foreignKeys = [
        ForeignKey(
            entity = CourseEntity::class,
            parentColumns = ["id"],
            childColumns = ["course_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index("course_id"), Index("date")],
)
data class SessionEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    @ColumnInfo(name = "course_id") val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)

fun SessionEntity.toDomain() = StudySession(id, courseId, date, minutes, done)
fun StudySession.toEntity() = SessionEntity(id, courseId, date, minutes, done)
```

Four decisions are in that file, and each one is a line.

**`@PrimaryKey(autoGenerate = true)` with a default of `0`** lets SQLite choose the id. Insert a
session with `id = 0` and the database gives it the next number, which the insert returns. A course
keeps the id it already has, `kotlin` or `sql`, because that id comes from somewhere else.

**The foreign key** says every session belongs to a course that exists. Insert one for a course
that is not in `courses` and SQLite refuses; delete a course and `CASCADE` deletes its sessions
with it. Without it, a deleted course leaves sessions behind that no screen can show and every
total still counts.

**The two indices** are for the two questions the app asks: the sessions of one course, and the
sessions between two dates. Room warns at build time if a foreign key column has no index, because
every delete of a course would then scan the whole sessions table.

**Two small functions map the entity to the model and back**, for the reason lesson 14 gave the DTO:
the table is shaped for SQLite, the model for the app, and the mapping is the one place that knows
both.

## A column SQLite has no type for

SQLite stores text, integers, reals and blobs, and nothing else. A `Boolean` becomes an integer, 0
or 1, without being asked. A `LocalDate` has no column type at all, and Room says so the first time the
project is built, which is where the next section starts.
