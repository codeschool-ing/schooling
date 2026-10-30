---
title: Migração, para o armazenamento que já existe
version: 1
---

**A primeira versão do app escreve um armazenamento, e toda versão seguinte abre esse armazenamento no
telefone de alguém.** Mude uma classe de registro e o arquivo no telefone deixa de bater com o código. A
documentação da Apple para o `ModelContainer` diz o que acontece então: conforme o esquema evolui, o
contêiner faz migrações automáticas, e quando as mudanças entre duas versões passam do que uma migração
automática consegue fazer, o app fornece um `SchemaMigrationPlan` para participar. Nada nesta seção foi
executado: ela segue a documentação da Apple para `VersionedSchema`, `SchemaMigrationPlan` e
`MigrationStage`, lida em 30 de outubro de 2026.

## O que uma migração automática cobre

A documentação da Apple para `MigrationStage.lightweight` não lista quais mudanças se qualificam. As que
este curso confia a ela são as três conservadoras: acrescentar uma propriedade com valor padrão, remover
uma propriedade, e renomear uma quando a propriedade nova diz como se chamava antes. Essa última precisa
de `originalName`:

```swift
// SessionRecord, version 2: `minutes` was called `length` in version 1
@Attribute(originalName: "length") var minutes: Int
```

Sem `originalName`, uma renomeação é lida como uma propriedade removida e outra acrescentada, e os minutos
de todas as sessões se perdem na primeira abertura da versão nova. **É o jeito mais comum de uma migração
perder dados, e sem erro nenhum**: o armazenamento abre, o app funciona, e todo número é zero.

## Versões escritas

Para qualquer coisa além disso, a história do esquema é escrita como versões. Cada uma é um
`VersionedSchema` que guarda as classes de registro como elas eram:

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

Os comentários representam as classes inteiras, que são as da seção 02 com o que mudou entre as duas.
**As classes antigas ficam no código enquanto algum telefone puder ainda ter aquele armazenamento**, o que,
para um app na App Store, é muito tempo: alguém que não abre o app há um ano abre o arquivo da versão 1
com o código da versão 5. As linhas de `typealias` são o que o resto do app escreve, para que as telas
nunca citem uma versão.

## O plano

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

Uma etapa é `lightweight`, a automática, ou `custom`, que roda código antes e depois. Esta é custom porque
a versão 2 acrescenta `@Attribute(.unique)` ao `sessionID`, e um armazenamento que já tem dois registros
com o mesmo id, digamos de uma sincronização que rodou duas vezes, não pode receber uma restrição de
unicidade até um deles sair. O `willMigrate` roda contra o esquema antigo, com um contexto, antes da
mudança.

O contêiner é então criado com o plano, no lugar do modificador de uma linha da seção 03:

```swift
// PlannerApp.swift, with a migration plan
let container = try ModelContainer(for: CourseRecord.self, SessionRecord.self,
                                   migrationPlan: PlannerMigrationPlan.self)
```

e entregue à cena com `.modelContainer(container)`. Esse inicializador lança erros, e o app tem de decidir
o que significa um armazenamento que não abre; travar na abertura é a decisão tomada por não decidir.

**Uma migração é testada com um armazenamento da versão antiga**, que é um arquivo guardado de propósito
do build que foi publicado. A aula 20 é onde esse teste fica, e ele só roda num Mac.
