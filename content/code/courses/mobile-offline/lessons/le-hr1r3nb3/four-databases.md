---
title: Four databases, and the one under three of them
version: 1
---

**On a phone, the database is almost always SQLite, whatever the library on top of it is called.**
Android ships it, iOS ships it, and React Native reaches it through a library that calls the one the
platform shipped. Room, Core Data and SwiftData are ways of talking to SQLite in Kotlin and Swift.
Realm is the exception the title names, with an engine of its own.

That matters more than it looks. When a Room query is slow, the reason is an SQLite query plan.
When a SwiftData store grows a column, an SQLite table gets an `ALTER`. **Learning SQLite once
explains all three**, which is why the planner uses it directly, through `better-sqlite3`, and why
the rest of this lesson is about SQLite rather than about any one wrapper.

## The same session, four ways

*These listings were not run for this course; they follow the Room, SwiftData, Realm and Expo
SQLite documentation.*

**Room**, on Android, maps a Kotlin class to a table and checks every query in a DAO against the
schema when the app is compiled:

```kotlin
@Entity(tableName = "sessions")
data class Session(
    @PrimaryKey val id: String,
    val course: String,
    val date: String,
    val minutes: Int,
    val done: Boolean,
)

@Dao
interface SessionDao {
    @Query("SELECT * FROM sessions WHERE date >= :monday AND date < :nextMonday")
    fun week(monday: String, nextMonday: String): Flow<List<Session>>

    @Insert
    suspend fun add(session: Session)
}
```

**SwiftData**, on iOS 17 and later, makes a class persistent with one macro, and a SwiftUI view
reads it with `@Query`. Underneath it is Core Data, Apple's older framework, and underneath that,
an SQLite file:

```swift
@Model
final class Session {
    @Attribute(.unique) var id: String
    var course: String
    var date: String
    var minutes: Int
    var done: Bool

    init(id: String, course: String, date: String, minutes: Int, done: Bool = false) {
        self.id = id; self.course = course; self.date = date
        self.minutes = minutes; self.done = done
    }
}
```

**Realm** stores objects in its own file format, with its own query language, on Android, iOS and
React Native. In September 2024 MongoDB, which owns it, announced the end of Atlas Device Sync, the
service Realm synchronised through; the database itself continues as open source. That is a
lesson in its own right: the storage engine and the sync service were sold together, and only one
of them stayed.

```kotlin
class Session : RealmObject {
    @PrimaryKey var id: String = ""
    var course: String = ""
    var date: String = ""
    var minutes: Int = 0
    var done: Boolean = false
}
```

**React Native** has no database of its own. `expo-sqlite` opens the platform's SQLite and gives
the app SQL with promises:

```typescript
import * as SQLite from "expo-sqlite";

const db = await SQLite.openDatabaseAsync("planner.db");
const week = await db.getAllAsync(
  "SELECT * FROM sessions WHERE date >= ? AND date < ?",
  ["2026-10-19", "2026-10-26"],
);
```

| | engine | what you write | checked |
|---|---|---|---|
| Room | SQLite | Kotlin classes and SQL | at compile time |
| Core Data, SwiftData | SQLite | Swift classes and predicates | at compile time, in part |
| Realm | its own | objects and Realm's queries | when it runs |
| `expo-sqlite`, `better-sqlite3` | SQLite | SQL | when it runs |

The last row is the planner's, and it hides nothing: every table, every index and every query is
written out where you can read it.
