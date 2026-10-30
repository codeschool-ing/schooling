---
title: Entidades: uma classe que é uma tabela
version: 1
---

**Uma entidade é uma data class com `@Entity`, e cada propriedade vira uma coluna.** O Room dá à
tabela e às colunas os nomes da classe e das propriedades, a não ser que você diga outra coisa, e
para uma tabela que outro código vai consultar à mão vale dizer: SQL se escreve em `snake_case` por
convenção, e o servidor do planner fala assim também.

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

Quatro decisões estão nesse arquivo, e cada uma é uma linha.

**`@PrimaryKey(autoGenerate = true)` com padrão `0`** deixa o SQLite escolher o id. Insira uma sessão
com `id = 0` e o banco lhe dá o próximo número, que o insert devolve. Um curso mantém o id que já
tem, `kotlin` ou `sql`, porque esse id vem de outro lugar.

**A chave estrangeira** diz que toda sessão pertence a um curso que existe. Insira uma de um curso que
não está em `courses` e o SQLite recusa; apague um curso e o `CASCADE` apaga as sessões dele junto.
Sem ela, um curso apagado deixa para trás sessões que nenhuma tela mostra e que todo total continua
contando.

**Os dois índices** são para as duas perguntas que o app faz: as sessões de um curso, e as sessões
entre duas datas. O Room avisa no build se uma coluna de chave estrangeira não tem índice, porque
cada exclusão de curso varreria então a tabela de sessões inteira.

**Duas funções pequenas mapeiam a entidade para o modelo e de volta**, pelo motivo que a aula 14 deu
para o DTO: a tabela tem o formato do SQLite, o modelo o do app, e o mapeamento é o único lugar que
conhece os dois.

## Uma coluna para a qual o SQLite não tem tipo

O SQLite guarda texto, inteiros, reais e blobs, e nada mais. Um `Boolean` vira um inteiro, 0 ou 1,
sem ninguém pedir. Um `LocalDate` não tem tipo de coluna nenhum, e o Room diz isso na primeira vez
em que o projeto é compilado, que é onde a próxima seção começa.
