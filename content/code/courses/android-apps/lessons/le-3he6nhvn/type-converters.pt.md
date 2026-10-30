---
title: Conversores de tipo, para o que o SQLite não guarda
version: 1
---

**Uma classe de banco lista as entidades e a versão, e isso basta para compilar.** Os DAOs chegam na
seção 05; este ainda não tem nenhum:

```kotlin
// app/src/main/java/com/example/planner/data/PlannerDatabase.kt
package com.example.planner.data

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(entities = [CourseEntity::class, SessionEntity::class], version = 1)
abstract class PlannerDatabase : RoomDatabase()
```

Compile, e o KSP lê as entidades pela primeira vez:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^e: |^BUILD"
e: [ksp] /home/ana/planner/app/src/main/java/com/example/planner/data/Entities.kt:32: Cannot figure out how to save this property into database. You can consider adding a type converter for it.
BUILD FAILED in 26s
```

**O Room não consegue guardar um `LocalDate`, e diz isso no arquivo e na linha da propriedade.** Ele
também aponta a saída, um **conversor de tipo**: um par de funções que transformam o tipo num que o
SQLite tem, e de volta.

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

**Texto em ISO 8601, `2026-10-27`, e não um número de dias ou de milissegundos.** A escolha importa
mais do que parece. Datas ISO ordenadas como texto ficam na mesma ordem que as datas, então
`ORDER BY date` e `WHERE date BETWEEN :from AND :to` funcionam na coluna como ela é; e quem abrir o
arquivo com uma ferramenta de SQLite lê uma data, e não `20388`. O custo são alguns bytes por linha,
o que para as sessões de um planner é nada.

O banco nomeia os conversores uma vez, e toda entidade e todo parâmetro de consulta dele podem então
usar um `LocalDate`:

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

O build passa, e escreveu algo que você não pediu:

```
ana@vm:~/planner$ find app/schemas -type f
app/schemas/com.example.planner.data.PlannerDatabase/1.json
ana@vm:~/planner$ grep -o "\"createSql\": \"CREATE TABLE[^\"]*course_id[^\"]*" app/schemas/com.example.planner.data.PlannerDatabase/1.json
"createSql": "CREATE TABLE IF NOT EXISTS `${TABLE_NAME}` (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `course_id` TEXT NOT NULL, `date` TEXT NOT NULL, `minutes` INTEGER NOT NULL, `done` INTEGER NOT NULL, FOREIGN KEY(`course_id`) REFERENCES `courses`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE )
```

**Esse é o schema da versão 1, em JSON, no diretório que o arquivo de build nomeou.** Ele registra o
`CREATE TABLE` exato que o Room vai rodar, coluna por coluna, com `${TABLE_NAME}` onde entra o nome;
`date` é `TEXT`, a escolha do conversor, e `done` é um `INTEGER`. O arquivo vai para o controle de
versão. A seção 07 explica por quê: é o único registro de como era o banco nos celulares que
instalaram a versão 1.
