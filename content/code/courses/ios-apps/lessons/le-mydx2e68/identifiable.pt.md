---
title: Identifiable, e para que serve um id
version: 1
---

**O SwiftUI guarda o estado de uma linha, a sua animação e o seu lugar na tela pela identidade da
linha, e num `ForEach` a identidade é o id do elemento.** Quando a coleção muda, o SwiftUI compara os
ids antes e depois: um id novo é uma linha inserida, um id que sumiu é uma linha removida, um id em
outro lugar é uma linha movida. Todo o resto da linha é só conteúdo a redesenhar.

O `Identifiable` é um protocolo de um requisito só, da biblioteca padrão do Swift e não do SwiftUI,
então ele é conferido no Linux como qualquer outra coisa:

```swift
public protocol Identifiable<ID> {
    associatedtype ID: Hashable
    var id: ID { get }
}
```

A aula 1 fez o `Course` e o `StudySession` adotarem o protocolo dando a cada um um `let id: String`.
**Três propriedades fazem um id servir para este trabalho**, e os ids do planner têm as três:

- **estável**: o mesmo elemento tem o mesmo id enquanto existir. `let`, e não `var`, diz isso.
- **único** na coleção: o artigo da Apple sobre stacks roláveis diz que cada elemento sobre o qual um
  `ForEach` itera *tem de ser identificável de forma única*, porque duas linhas com um id são uma linha
  só para o SwiftUI, e qual delas guarda o estado não é algo em que se apoiar.
- **dos dados, não da tela**: o id veio com a sessão, da pessoa que a criou ou, a partir da aula 12, do
  servidor.

Para uma coleção cujos elementos não são `Identifiable`, o `ForEach` recebe o id como um key path:

```swift
ForEach(model.plan.courses, id: \.title) { course in Text(course.title) }
```

Isso compila, e é um bug esperando dois cursos com o mesmo título, ou uma renomeação, que a aula 1
seção 05 chamou de motivo de os ids existirem. **`id: \.self` num array de strings é a mesma aposta**,
e ela perde no momento em que a lista tem duas strings iguais.

A pior escolha comum nem está nessa lista: a posição. A seção 04 mostra o que ela faz.
