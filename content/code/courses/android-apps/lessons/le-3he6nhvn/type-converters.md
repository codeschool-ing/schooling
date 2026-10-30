---
title: Type converters, for what SQLite cannot store
version: 1
---

**A database class lists its entities and its version, and that is enough to build.** The DAOs
come in section 05; this one has none yet:

```kotlin
// app/src/main/java/com/example/planner/data/PlannerDatabase.kt
package com.example.planner.data

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(entities = [CourseEntity::class, SessionEntity::class], version = 1)
abstract class PlannerDatabase : RoomDatabase()
```

Build it, and KSP reads the entities for the first time:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^e: |^BUILD"
e: [ksp] /home/ana/planner/app/src/main/java/com/example/planner/data/Entities.kt:32: Cannot figure out how to save this property into database. You can consider adding a type converter for it.
BUILD FAILED in 26s
```

**Room cannot store a `LocalDate`, and says so at the file and line of the property.** It also
names the way out, a **type converter**: a pair of functions that turn the type into one SQLite
has, and back again.

```kotlin
// app/src/main/java/com/example/planner/data/Converters.kt
package com.example.planner.data

import androidx.room.TypeConverter
import java.time.LocalDate

class Converters {
    @TypeConverter
    fun dateToText(date: LocalDate): String = date.toString()

    @TypeConverter
    fun textToDate(text: String): LocalDate = LocalDate.parse(text)
}
```

**Text in ISO 8601, `2026-10-27`, and not a number of days or milliseconds.** The choice matters
more than it looks. ISO dates sort as text in the same order as dates, so `ORDER BY date` and
`WHERE date BETWEEN :from AND :to` work on the column as it is; and anybody who opens the file with
a SQLite tool reads a date rather than `20388`. The cost is a few bytes per row, which for a
planner's sessions is nothing.

The database names the converters once, and every entity and every query parameter in it can then
use a `LocalDate`:

```kotlin
// app/src/main/java/com/example/planner/data/PlannerDatabase.kt
package com.example.planner.data

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters

@Database(entities = [CourseEntity::class, SessionEntity::class], version = 1)
@TypeConverters(Converters::class)
abstract class PlannerDatabase : RoomDatabase()
```

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^(w|e): |^BUILD"
BUILD SUCCESSFUL in 16s
```

The build passes, and it has written something you did not ask for:

```
ana@vm:~/planner$ find app/schemas -type f
app/schemas/com.example.planner.data.PlannerDatabase/1.json
ana@vm:~/planner$ grep -o "\"createSql\": \"CREATE TABLE[^\"]*course_id[^\"]*" app/schemas/com.example.planner.data.PlannerDatabase/1.json
"createSql": "CREATE TABLE IF NOT EXISTS `${TABLE_NAME}` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `course_id` TEXT NOT NULL, `date` TEXT NOT NULL, `minutes` INTEGER NOT NULL, `done` INTEGER NOT NULL, FOREIGN KEY(`course_id`) REFERENCES `courses`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE )
```

**That is the schema of version 1, as JSON, in the directory the build file named.** It records the
exact `CREATE TABLE` Room will run, column by column, with `${TABLE_NAME}` where the name goes;
`date` is `TEXT`, the converter's choice, and `done` is an `INTEGER`. The file belongs in version
control. Section 07
explains why: it is the only record of what the database looked like on the phones that installed
version 1.
