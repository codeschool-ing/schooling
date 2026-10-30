---
title: Room, SwiftData and Realm, and the destructive fallback
version: 1
---

**Every platform library has the same two pieces as `migrations.ts`, a version number and a list
of steps, and every one of them also offers a way to skip the steps by deleting the database.**
That way out is what this section is about, because on a device that keeps offline writes it
deletes the one copy of them.

*These listings were not run for this course; they follow the Room, SwiftData and Realm
documentation.*

**Room** declares the version on the database class, and each step as a `Migration` from one number
to the next. Simple changes can be an `AutoMigration`, which Room works out from the schema files it
exports at build time:

```kotlin
val MIGRATION_3_4 = object : Migration(3, 4) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE sessions ADD COLUMN done_at TEXT")
        db.execSQL("UPDATE sessions SET done_at = date WHERE done = 1")
    }
}

@Database(
    entities = [Course::class, Session::class],
    version = 4,
    autoMigrations = [AutoMigration(from = 1, to = 2)],
)
abstract class PlannerDatabase : RoomDatabase()

val db = Room.databaseBuilder(context, PlannerDatabase::class.java, "planner.db")
    .addMigrations(MIGRATION_2_3, MIGRATION_3_4)
    .build()
```

**SwiftData** describes each shipped shape as a `VersionedSchema`, and the path between them as a
`SchemaMigrationPlan` of stages. A lightweight stage covers what Core Data can infer, such as an
added property; a custom stage runs code before and after:

```swift
enum PlannerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PlannerSchemaV1.self, PlannerSchemaV2.self]
    }
    static var stages: [MigrationStage] { [v1toV2] }

    static let v1toV2 = MigrationStage.lightweight(
        fromVersion: PlannerSchemaV1.self, toVersion: PlannerSchemaV2.self)
}

let container = try ModelContainer(
    for: PlannerSchemaV2.Session.self, migrationPlan: PlannerMigrationPlan.self)
```

**Realm** keeps a `schemaVersion` on its configuration and a migration block that sees each object
in its old and new shape:

```swift
let config = Realm.Configuration(
    schemaVersion: 4,
    migrationBlock: { migration, oldSchemaVersion in
        if oldSchemaVersion < 4 {
            migration.enumerateObjects(ofType: "Session") { old, new in
                new?["doneAt"] = (old?["done"] as? Bool == true) ? old?["date"] : nil
            }
        }
    })
```

## The destructive fallback

Room has `fallbackToDestructiveMigration()`: when it finds no path from the file's version to the
current one, it drops every table and starts empty. Realm's configuration has
`deleteRealmIfMigrationNeeded`. Both are offered for development, where the data is test data, and
both find their way into releases because they make a migration error disappear.

**On a device that works offline, deleting the database deletes everything the person wrote and the
server has not received.** Lesson 4 marked those rows `synced = 0` and refused to prune them for that
reason. A destructive migration does not read that column. The sessions typed on the train this
morning, the note added last night, the tick on a session done offline: gone, and nothing anywhere
holds a copy.

If the app truly cannot migrate, the safe order is the reverse of what the fallback does: **send
what is unsent, then rebuild.** Read the rows the outbox of lesson 8 is still holding, deliver them,
and only then start from an empty file, which lesson 12 fills from the server. Where even reading is
impossible, keep the old file aside rather than deleting it; it may be the only evidence of what
the person lost.
