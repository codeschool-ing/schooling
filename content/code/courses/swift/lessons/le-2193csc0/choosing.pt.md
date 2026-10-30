---
title: Qual dos dois escrever
version: 1
---

A documentação da Apple tem um artigo sobre exatamente esta pergunta, "Choosing Between Structures
and Classes", e a primeira recomendação dele é a que este curso segue: **use uma struct por
padrão.** Os motivos são os que as seções anteriores mediram. Uma struct é copiada, então o código
que segura uma não pode ser surpreendido pela mudança de outra pessoa. Uma struct `let` não muda de
jeito nenhum. O `==` vem do compilador. E o copy-on-write torna as cópias baratas.

O artigo dá três motivos para usar uma classe em vez disso:

- **quando a identidade importa**: o valor é uma coisa só no mundo, e toda parte do programa
  precisa ver a mesma. Um arquivo aberto, uma conexão de rede, o único repositório de onde as telas
  de um app leem;
- **quando o Objective-C precisa chamá-lo**, porque os frameworks mais antigos da Apple só entendem
  classes. Isso é assunto do `ios-apps`, não deste curso;
- **quando herança é o modelo certo**, o que a aula 10 argumenta ser mais raro do que parece.

## Um de cada, juntos

O planner de estudos guarda as sessões como valores e o lugar onde elas ficam como uma única
instância compartilhada. Duas "telas", cada uma uma struct, seguram o mesmo repositório:

```swift
// Choosing.swift
struct StudySession {
    var course: String
    var minutes: Int
}
final class PlannerStore {
    var sessions: [StudySession] = []
}
struct WeekScreen {
    let store: PlannerStore
    func show() { print("week:", store.sessions.map(\.minutes)) }
}
struct AddScreen {
    let store: PlannerStore
    func add(_ session: StudySession) { store.sessions.append(session) }
}
let store = PlannerStore()
let week = WeekScreen(store: store)
let add = AddScreen(store: store)
add.add(StudySession(course: "Swift", minutes: 45))
add.add(StudySession(course: "Swift", minutes: 30))
week.show()
var edited = store.sessions[0]
edited.minutes = 90
week.show()
```

```
ana@vm:~/sw/l05$ swift Choosing.swift
week: [45, 30]
week: [45, 30]
```

**As duas telas viram as duas sessões, porque há um repositório só.** `AddScreen.add` não é
`mutating` e é chamado num `let`, e mesmo assim mudou o repositório: a tela guarda uma referência, e a
referência não mudou. Tirar `store.sessions[0]` para `edited` copiou a sessão, então pôr os minutos
dela em 90 não mudou nada que as telas consigam ver. Para mudar uma sessão guardada, o código precisa
escrever o valor de volta, e esse é o momento que quem lê consegue ver. `\.minutes` é um key path, um
jeito de nomear uma propriedade, e `map(\.minutes)` a lê de cada sessão.

Esse formato, **valores para os dados e uma referência para o lugar onde eles moram**, é o formato
sobre o qual os apps em SwiftUI são construídos, e o `ios-apps` o constrói. A aula 15 troca o
`PlannerStore` de classe para ator, porque uma instância compartilhada que duas tarefas mudam ao
mesmo tempo tem um problema que esta aula ainda não encontrou.
