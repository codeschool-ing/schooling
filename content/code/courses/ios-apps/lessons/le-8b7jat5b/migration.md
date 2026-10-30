---
title: Migration, for the store that already exists
version: 1
---

**The first version of the app writes a store, and every later version opens that store on somebody's
phone.** Change a record class and the file on the phone no longer matches the code. Apple's
documentation for `ModelContainer` says what happens next: as the schema evolves, the container performs
automatic migrations, and when the changes between two versions exceed what an automatic migration can
do, the app provides a `SchemaMigrationPlan` to take part. Nothing in this section was run: it follows
Apple's documentation for `VersionedSchema`, `SchemaMigrationPlan` and `MigrationStage`, read on 30
October 2026.

## What an automatic migration covers

Apple's documentation for `MigrationStage.lightweight` does not list which changes qualify. The ones
this course relies on it for are the conservative three: adding a property with a default value,
removing a property, and renaming one when the new property says what it used to be called. That last
needs `originalName`:

```swift
// SessionRecord, version 2: `minutes` was called `length` in version 1
@Attribute(originalName: "length") var minutes: Int
```

Without `originalName`, a rename reads as one property removed and another added, and every session's
minutes are lost on the first launch of the new version. **It is the commonest way a migration loses
data, and it does so without an error**: the store opens, the app works, and every number is zero.

## Versions written down

For anything beyond that, the schema's history is written down as versions. Each is a `VersionedSchema`
holding the record classes as they were:

```swift
// PlannerSchema.swift
import SwiftData

enum PlannerSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [CourseRecord.self, SessionRecord.self] }

    @Model final class CourseRecord { /* as shipped in 1.0 */ }
    @Model final class SessionRecord { /* as shipped in 1.0 */ }
}

enum PlannerSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [CourseRecord.self, SessionRecord.self] }

    @Model final class CourseRecord { /* as it is now */ }
    @Model final class SessionRecord { /* as it is now */ }
}

typealias CourseRecord = PlannerSchemaV2.CourseRecord
typealias SessionRecord = PlannerSchemaV2.SessionRecord
```

The comments stand for the full classes, which are section 02's with whatever changed between the two.
**The old classes stay in the code for as long as a phone might still have that store**, which, for an
app on the App Store, is a long time: somebody who has not opened it for a year opens version 1's file
with version 5's code. The `typealias` lines are what the rest of the app writes, so screens never
mention a version.

## The plan

```swift
// PlannerMigrationPlan.swift
import SwiftData

enum PlannerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PlannerSchemaV1.self, PlannerSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [.custom(fromVersion: PlannerSchemaV1.self, toVersion: PlannerSchemaV2.self,
                 willMigrate: { context in
                     // version 2 makes sessionID unique: drop duplicates first
                     let all = try context.fetch(FetchDescriptor<PlannerSchemaV1.SessionRecord>())
                     var seen = Set<String>()
                     for record in all where !seen.insert(record.sessionID).inserted {
                         context.delete(record)
                     }
                     try context.save()
                 },
                 didMigrate: nil)]
    }
}
```

A stage is `lightweight`, the automatic kind, or `custom`, which runs code before and after. This one
is custom because version 2 adds `@Attribute(.unique)` to `sessionID`, and a store that already holds
two records with the same id, say from a sync that ran twice, cannot be given a unique constraint until
one of them goes. `willMigrate` runs against the old schema, with a context, before the change.

The container is then made with the plan, in place of section 03's one-line modifier:

```swift
// PlannerApp.swift, with a migration plan
let container = try ModelContainer(for: CourseRecord.self, SessionRecord.self,
                                   migrationPlan: PlannerMigrationPlan.self)
```

and handed to the scene with `.modelContainer(container)`. That initialiser throws, and the app has to
decide what a store that cannot be opened means; crashing at launch is the decision made by not
deciding.

**A migration is tested with a store from the old version**, which is a file kept for the purpose
from the build that shipped it. Lesson 20 is where that test goes, and it can only run on a Mac.
