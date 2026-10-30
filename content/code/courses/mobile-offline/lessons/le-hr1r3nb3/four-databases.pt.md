---
title: Quatro bancos, e o que está por baixo de três deles
version: 1
---

**Num celular, o banco de dados é quase sempre o SQLite, seja qual for o nome da biblioteca por
cima dele.** O Android o traz, o iOS o traz, e o React Native o alcança por uma biblioteca que
chama o que a plataforma trouxe. Room, Core Data e SwiftData são jeitos de falar com o SQLite em
Kotlin e em Swift. O Realm é a única exceção do título desta aula: um motor próprio.

Isso importa mais do que parece. Quando uma consulta do Room está lenta, o motivo é um plano de
consulta do SQLite. Quando um armazenamento do SwiftData ganha uma coluna, uma tabela do SQLite
recebe um `ALTER`. **Aprender o SQLite uma vez explica os três**, e é por isso que o planner o usa
diretamente, pelo `better-sqlite3`, e que o resto desta aula é sobre o SQLite e não sobre um
invólucro em particular.

## A mesma sessão, de quatro jeitos

*Estas listagens não foram rodadas para este curso; elas seguem a documentação do Room, do
SwiftData, do Realm e do Expo SQLite.*

O **Room**, no Android, mapeia uma classe Kotlin para uma tabela e confere cada consulta de um DAO
contra o esquema quando o app é compilado:

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

O **SwiftData**, no iOS 17 em diante, torna uma classe persistente com uma macro, e uma view do
SwiftUI a lê com `@Query`. Por baixo dele está o Core Data, o framework mais antigo da Apple, e por
baixo deste, um arquivo SQLite:

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

O **Realm** guarda objetos num formato de arquivo próprio, com linguagem de consulta própria, no
Android, no iOS e no React Native. Em setembro de 2024 a MongoDB, dona dele, anunciou o fim do
Atlas Device Sync, o serviço pelo qual o Realm sincronizava; o banco em si continua como código
aberto. Isso é uma lição por si só: o motor de armazenamento e o serviço de sincronização eram
vendidos juntos, e só um deles ficou.

```kotlin
class Session : RealmObject {
    @PrimaryKey var id: String = ""
    var course: String = ""
    var date: String = ""
    var minutes: Int = 0
    var done: Boolean = false
}
```

O **React Native** não tem banco próprio. O `expo-sqlite` abre o SQLite da plataforma e dá ao app
SQL com promises:

```typescript
import * as SQLite from "expo-sqlite";

const db = await SQLite.openDatabaseAsync("planner.db");
const week = await db.getAllAsync(
  "SELECT * FROM sessions WHERE date >= ? AND date < ?",
  ["2026-10-19", "2026-10-26"],
);
```

| | motor | o que você escreve | conferido |
|---|---|---|---|
| Room | SQLite | classes Kotlin e SQL | na compilação |
| Core Data, SwiftData | SQLite | classes Swift e predicados | na compilação, em parte |
| Realm | próprio | objetos e as consultas do Realm | quando roda |
| `expo-sqlite`, `better-sqlite3` | SQLite | SQL | quando roda |

A última linha é a do planner, e ela não esconde nada: cada tabela, cada índice e cada consulta
está escrito onde você pode ler.
