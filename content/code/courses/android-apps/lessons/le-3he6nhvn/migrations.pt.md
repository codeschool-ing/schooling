---
title: Migrações, num banco em que você não consegue entrar
version: 1
---

**Um celular que instalou a versão 1 do app tem um arquivo de banco no formato da versão 1, e a
atualização precisa mudá-lo sem perder uma linha.** Você não alcança esse arquivo. Ele está no
armazenamento privado do celular de outra pessoa, guarda o histórico de estudo dela, e a atualização
chega enquanto ela dorme. Uma **migração** é o código que transforma o schema 1 no schema 2 naquele
celular, uma vez, na primeira vez em que o app novo abre o banco. O `mobile-offline`, o curso depois
deste, dedica a aula 5 ao problema em geral; esta seção é como o Room o resolve.

A mudança é pequena. Uma sessão ganha uma nota opcional:

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

**Uma coluna nova sem padrão precisa ser anulável, ou ter um padrão que a migração forneça**, porque
toda linha que já está no celular precisa de um valor para ela. `note: String? = null` é o caso
fácil. A versão do banco sobe um, e ele fica sabendo da migração:

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

`plannerDatabase` é como o app vai abrir o seu arquivo de verdade, `planner.db`, a partir da aula 16:
o Room lê a versão guardada no arquivo, vê 1, encontra uma migração de 1 para 2 e a roda antes de
qualquer consulta. Compile o projeto, e o Room escreve o segundo schema ao lado do primeiro:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^(w|e): |^BUILD"
BUILD SUCCESSFUL in 20s
ana@vm:~/planner$ find app/schemas -type f | sort
app/schemas/com.example.planner.data.PlannerDatabase/1.json
app/schemas/com.example.planner.data.PlannerDatabase/2.json
ana@vm:~/planner$ grep -o "\"createSql\": \"CREATE TABLE[^\"]*course_id[^\"]*" app/schemas/com.example.planner.data.PlannerDatabase/2.json
"createSql": "CREATE TABLE IF NOT EXISTS `${TABLE_NAME}` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `course_id` TEXT NOT NULL, `date` TEXT NOT NULL, `minutes` INTEGER NOT NULL, `done` INTEGER NOT NULL, `note` TEXT, FOREIGN KEY(`course_id`) REFERENCES `courses`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE )
```

O `sessions` do segundo arquivo termina em `` `note` TEXT `` sem `NOT NULL`, que é como se declara
uma propriedade anulável. **Os dois arquivos JSON são o motivo de a seção 04 dizer que os schemas vão
para o controle de versão.** O Room não tem outro jeito de saber como era a versão 1 depois que a
versão 2 é o código, e o ajudante de teste dele monta um banco antigo exatamente a partir desses
arquivos.

## Testando a migração que você não consegue ver acontecer

O `MigrationTestHelper`, do `room-testing`, cria um banco numa versão antiga a partir do arquivo de
schema, deixa você pôr linhas nele com SQL puro, roda as suas migrações e então **confere se o
resultado bate exatamente com o schema novo**. Três testes: a migração como foi escrita, nenhuma
migração, e uma migração que roda e está errada.

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

**A linha escrita na versão 1 sobreviveu à migração**, com o id, a data e o `done`, e com `note`
vazio, que é o que `null` significa para uma linha que existia antes de haver notas.

**Sem migração, o Room se recusa a abrir o arquivo.** A mensagem diz que era preciso uma migração de
1 para 2, e é a mensagem com que um app quebra em todo celular que atualiza, na primeira consulta. A
cura tentadora, `fallbackToDestructiveMigration()`, faz o Room apagar o banco e começar vazio. Para
um cache é uma escolha defensável; para o histórico de estudo de alguém é apagar os dados da pessoa
durante uma atualização.

**A migração errada é a que só este teste pega.** Ela rodou sem erro e acrescentou a coluna, como
`NOT NULL` com padrão, onde a entidade diz que a coluna pode ser nula. Num celular o app abriria, e a
diferença apareceria depois, como uma queda ou uma consulta que se comporta de um jeito estranho. O
`runMigrationsAndValidate` comparou a tabela migrada com o schema 2 coluna por coluna, e recusou.

Os cinco testes da aula, juntos:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "PASSED|FAILED|^BUILD"
DaoTest > insertReadAndRefuse PASSED
FlowTest > theTotalFollowsTheTable PASSED
MigrationTest > wrongMigration PASSED
MigrationTest > noMigration PASSED
MigrationTest > oneToTwo PASSED
BUILD SUCCESSFUL in 21s
```

**Não executado:** uma atualização de verdade num celular de verdade, de uma versão 1 instalada para
a versão 2. O teste acima roda o mesmo código de migração contra o mesmo schema SQLite, que é o mais
perto que um computador chega. A documentação do Google também descreve a `AutoMigration`, que
escreve uma migração como esta para você quando a mudança é simples como uma coluna nova anulável.
