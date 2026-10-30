---
title: Salvar, salvamento automático e desfazer
version: 1
---

**No SwiftData uma mudança é feita num contexto e guardada por um save, e num app SwiftUI quase sempre
não é você quem chama o save.** A documentação da Apple para `ModelContext.autosaveEnabled` diz que,
quando ele está ligado, o contexto chama `save()` depois de mudanças nos registros que conhece, e também
"em vários momentos do ciclo de vida de janelas, cenas, views e sheets". A propriedade é `false` por
padrão, e o SwiftData a põe em `true` no `mainContext` do contêiner, que é o contexto que o modificador
da seção 03 põe no ambiente. Nada nesta seção foi executado; ela segue essa documentação, lida em 30 de
outubro de 2026.

## Quando chamar `save()` mesmo assim

O salvamento automático roda em momentos que o SwiftData escolhe. Dois momentos do planner valem não ser
deixados para ele:

- **antes de algo sair do app.** A aula 14 envia sessões novas ao servidor; ela deve enviar o que está
  guardado, então salva primeiro e lê depois.
- **depois de trabalho fora do contexto principal.** Um contexto que você mesmo cria, para uma importação
  fora do main actor, não salva sozinho a não ser que mandem, e as mudanças dele só chegam ao
  armazenamento quando ele salva.

```swift
// Saving before a sync
do {
    if context.hasChanges { try context.save() }
} catch {
    syncError = error      // shown on the screen: lesson 12's error state
}
```

A documentação da Apple para `save()` sugere conferir `hasChanges` antes, "do contrário o SwiftData pode
fazer trabalho desnecessário". E `save()` lança erros: um disco cheio ou uma restrição quebrada é um erro
que a tela tem de mostrar. **Um `try?` aqui seria um save que falha sem dizer nada**, e o estudante
descobriria na semana seguinte que as sessões que acrescentou nunca foram guardadas.

## Desfazer

Desfazer não vem ligado. A documentação da Apple para `ModelContext.undoManager` diz que o valor padrão
é `nil`, e que atribuir um `UndoManager` liga o desfazer no contexto. O modificador do SwiftUI pega o
caminho curto:

```swift
// PlannerApp.swift, with undo
WindowGroup {
    CourseListView()
}
.modelContainer(for: [CourseRecord.self, SessionRecord.self], isUndoEnabled: true)
```

A documentação desse parâmetro diz para usar o `undoManager` do ambiente da cena para gerenciar o
desfazer. Uma tela o lê com `@Environment(\.undoManager)` e oferece um botão Desfazer depois de uma
exclusão.

**Desfazer é a resposta mais gentil a um gesto errado.** Um diálogo de confirmação antes de toda exclusão
treina as pessoas a tocar em "Apagar" sem ler; um Desfazer depois da exclusão custa um toque só para quem
precisa. No planner, apagar uma sessão ganha Desfazer, e apagar um curso, que leva em cascata todas as
sessões dele, ganha confirmação e Desfazer.

A documentação acrescenta um custo: o desfazer registra cada mudança, então para uma importação de muitos
registros de uma vez ela sugere pôr `undoManager` em `nil` durante a operação.
