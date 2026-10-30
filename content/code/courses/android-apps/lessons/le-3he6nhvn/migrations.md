---
title: Migrations, on a database you cannot log into
version: 1
---

**A phone that installed version 1 of the app has a database file in version 1's shape, and the
update has to change it without losing a row.** You cannot reach that file. It is in the private
storage of somebody else's phone, it holds their study history, and the update arrives while they
sleep. A **migration** is the code that turns schema 1 into schema 2 on that phone, once, the
first time the new app opens the database. `mobile-offline`, the course after this one, gives its
lesson 5 to the general problem; this section is how Room does it.

The change is small. A session gets an optional note:

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
    val note: String? = null,
)

fun SessionEntity.toDomain() = StudySession(id, courseId, date, minutes, done)
fun StudySession.toEntity() = SessionEntity(id, courseId, date, minutes, done)
```

**A new column with no default must be nullable, or have a default the migration supplies**,
because every row already on the phone needs a value for it. `note: String? = null` is the easy
case. The database's version goes up by one, and it learns about the migration:

```kotlin
// app/src/main/java/com/example/planner/data/PlannerDatabase.kt
package com.example.planner.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(entities = [CourseEntity::class, SessionEntity::class], version = 2)
@TypeConverters(Converters::class)
abstract class PlannerDatabase : RoomDatabase() {
    abstract fun courses(): CourseDao
    abstract fun sessions(): SessionDao
}

val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE sessions ADD COLUMN note TEXT")
    }
}

fun plannerDatabase(context: Context): PlannerDatabase =
    Room.databaseBuilder(context, PlannerDatabase::class.java, "planner.db")
        .addMigrations(MIGRATION_1_2)
        .build()
```

`plannerDatabase` is how the app will open its real file, `planner.db`, from lesson 16 on: Room
reads the version stored in the file, sees 1, finds a migration from 1 to 2 and runs it before any
query. Build the project, and Room writes the second schema beside the first:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^(w|e): |^BUILD"
BUILD SUCCESSFUL in 20s
ana@vm:~/planner$ find app/schemas -type f | sort
app/schemas/com.example.planner.data.PlannerDatabase/1.json
app/schemas/com.example.planner.data.PlannerDatabase/2.json
ana@vm:~/planner$ grep -o "\"createSql\": \"CREATE TABLE[^\"]*course_id[^\"]*" app/schemas/com.example.planner.data.PlannerDatabase/2.json
"createSql": "CREATE TABLE IF NOT EXISTS `${TABLE_NAME}` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `course_id` TEXT NOT NULL, `date` TEXT NOT NULL, `minutes` INTEGER NOT NULL, `done` INTEGER NOT NULL, `note` TEXT, FOREIGN KEY(`course_id`) REFERENCES `courses`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE )
```

The second file's `sessions` ends in `` `note` TEXT `` with no `NOT NULL`, which is how a nullable
property is declared. **The two JSON files are why section 04 said the schemas belong in version
control.** Room has no
other way to know what version 1 looked like once version 2 is the code, and its test helper builds
an old database from exactly these files.

## Testing the migration you cannot watch happen

`MigrationTestHelper`, from `room-testing`, creates a database at an old version from its schema
file, lets you put rows in it with plain SQL, runs your migrations, and then **checks that the
result matches the new schema exactly**. Three tests: the migration as written, no migration at all,
and a migration that runs and is wrong.

```kotlin
// app/src/test/java/com/example/planner/data/MigrationTest.kt
package com.example.planner.data

import androidx.room.migration.Migration
import androidx.room.testing.MigrationTestHelper
import androidx.sqlite.db.SupportSQLiteDatabase
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class MigrationTest {
    @get:Rule
    val helper = MigrationTestHelper(
        InstrumentationRegistry.getInstrumentation(),
        PlannerDatabase::class.java,
    )

    private fun versionOne(name: String) = helper.createDatabase(name, 1).use { db ->
        db.execSQL("INSERT INTO courses VALUES ('android', 'Android Apps')")
        db.execSQL("INSERT INTO sessions (course_id, date, minutes, done) VALUES ('android', '2026-10-27', 45, 1)")
    }

    private fun attempt(label: String, block: () -> Unit) = try {
        block()
    } catch (e: Throwable) {
        println("$label -> ${e::class.simpleName}: ${e.message?.lineSequence()?.first()}")
    }

    @Test
    fun oneToTwo() {
        versionOne("planner-a")
        val db = helper.runMigrationsAndValidate("planner-a", 2, true, MIGRATION_1_2)
        db.query("SELECT id, course_id, date, minutes, done, note FROM sessions").use { row ->
            while (row.moveToNext()) {
                println((0 until row.columnCount).joinToString { "${row.getColumnName(it)}=${row.getString(it)}" })
            }
        }
    }

    @Test
    fun noMigration() = attempt("no migration") {
        versionOne("planner-b")
        helper.runMigrationsAndValidate("planner-b", 2, true)
    }

    @Test
    fun wrongMigration() = attempt("wrong migration") {
        versionOne("planner-c")
        val wrong = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE sessions ADD COLUMN note TEXT NOT NULL DEFAULT ''")
            }
        }
        helper.runMigrationsAndValidate("planner-c", 2, true, wrong)
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests "*MigrationTest" 2>&1 | grep -E "^    |PASSED|FAILED|^BUILD"
    wrong migration -> IllegalStateException: Migration didn't properly handle:  sessions
MigrationTest > wrongMigration PASSED
    no migration -> IllegalStateException: A migration from 1 to 2 was required but not found. Please provide the necessary Migration path via RoomDatabase.Builder.addMigration(...) or allow for destructive migrations via one of the RoomDatabase.Builder.fallbackToDestructiveMigration* functions.
MigrationTest > noMigration PASSED
    id=1, course_id=android, date=2026-10-27, minutes=45, done=1, note=null
MigrationTest > oneToTwo PASSED
BUILD SUCCESSFUL in 29s
```

**The row written under version 1 survived the migration**, with its id, its date and its `done`,
and with `note` empty, which is what `null` means for a row that was there before notes existed.

**Without a migration, Room refuses to open the file at all.** The message says a migration from 1
to 2 was required, and it is the message an app crashes with on every phone that updates, at the
first query. The tempting cure, `fallbackToDestructiveMigration()`, makes Room delete the database
and start empty instead. For a cache that is a defensible choice; for somebody's study history it
is deleting their data during an update.

**The wrong migration is the one only this test catches.** It ran without error and added the
column, as `NOT NULL` with a default where the entity says the column may be null. On a phone the
app would open, and the difference would surface later, as a crash or a query that behaves oddly.
`runMigrationsAndValidate` compared the migrated table with schema 2 column by column, and refused.

The lesson's five tests, together:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "PASSED|FAILED|^BUILD"
DaoTest > insertReadAndRefuse PASSED
FlowTest > theTotalFollowsTheTable PASSED
MigrationTest > wrongMigration PASSED
MigrationTest > noMigration PASSED
MigrationTest > oneToTwo PASSED
BUILD SUCCESSFUL in 21s
```

**Not run:** a real update on a real phone, from an installed version 1 to version 2. The test
above runs the same migration code against the same SQLite schema, which is as close as a
computer gets. Google's documentation also describes `AutoMigration`, which writes a migration like
this one for you when the change is as simple as a new nullable column.
