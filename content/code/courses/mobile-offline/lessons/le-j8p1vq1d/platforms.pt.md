---
title: Room, SwiftData e Realm, e o recurso destrutivo
version: 1
---

**Toda biblioteca de plataforma tem as mesmas duas peças do `migrations.ts`, um número de versão e
uma lista de passos, e toda uma delas também oferece um jeito de pular os passos apagando o
banco.** Essa saída é o assunto desta seção, porque num aparelho que guarda escritas offline ela
apaga a única cópia delas.

*Estas listagens não foram rodadas para este curso; elas seguem a documentação do Room, do
SwiftData e do Realm.*

O **Room** declara a versão na classe do banco, e cada passo como uma `Migration` de um número para
o seguinte. Mudanças simples podem ser uma `AutoMigration`, que o Room deduz dos arquivos de esquema
que exporta na build:

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

O **SwiftData** descreve cada formato publicado como um `VersionedSchema`, e o caminho entre eles
como um `SchemaMigrationPlan` de estágios. Um estágio leve cobre o que o Core Data consegue deduzir,
como uma propriedade acrescentada; um estágio personalizado roda código antes e depois:

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

O **Realm** guarda um `schemaVersion` na configuração e um bloco de migração que vê cada objeto no
formato antigo e no novo:

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

## O recurso destrutivo

O Room tem `fallbackToDestructiveMigration()`: quando não encontra caminho da versão do arquivo até
a atual, ele remove todas as tabelas e começa vazio. A configuração do Realm tem
`deleteRealmIfMigrationNeeded`. Os dois são oferecidos para o desenvolvimento, onde o dado é de
teste, e os dois acabam indo para versões publicadas porque fazem um erro de migração sumir.

**Num aparelho que funciona offline, apagar o banco apaga tudo o que a pessoa escreveu e o servidor
não recebeu.** A aula 4 marcou essas linhas com `synced = 0` e se recusou a apagá-las por esse
motivo. Uma migração destrutiva não lê essa coluna. As sessões digitadas no trem hoje de manhã, a
anotação de ontem à noite, a marcação de uma sessão feita offline: perdidas, e nada em lugar nenhum
guarda uma cópia.

Se o app de fato não consegue migrar, a ordem segura é o contrário do que o recurso faz: **enviar o
que não foi enviado, depois reconstruir.** Leia as linhas que a caixa de saída da aula 8 ainda está
guardando, entregue-as, e só então comece de um arquivo vazio, que a aula 12 preenche a partir do
servidor. Onde nem ler é possível, guarde o arquivo antigo de lado em vez de apagá-lo; ele pode ser
a única evidência do que a pessoa perdeu.
