---
title: Relações, e o que apagar um curso leva junto
version: 1
---

**Um curso tem muitas sessões e uma sessão pertence a um curso, e o SwiftData guarda essa ligação como
uma relação, e não como um id que você procura.** Os registros da seção 02 já a declaram: um
`CourseRecord` tem `sessions`, um `SessionRecord` tem `course`, e a macro `@Relationship` no primeiro diz
como os dois lados se pertencem. Esta seção trata do que essa linha decide. Nada aqui foi executado; ela
segue a documentação da Apple para `Relationship(_:deleteRule:…)` e o artigo dela sobre definir relações
de dados, lidos em 30 de outubro de 2026.

## Os dois lados, e qual é o inverso

```swift
// Records.swift, the two sides of one relationship
@Relationship(deleteRule: .cascade, inverse: \SessionRecord.course)
var sessions: [SessionRecord] = []        // in CourseRecord

var course: CourseRecord?                 // in SessionRecord
```

`inverse` cita a propriedade da outra classe que aponta de volta. O artigo da Apple mostra o mesmo padrão
com animais e a categoria deles: a categoria declara os seus animais com `@Relationship` e cita
`category` como inverso. **Com o inverso declarado, os dois lados são um fato só**: ponha
`record.course = course` e a sessão aparece em `course.sessions`, sem `append`.

`course` é opcional de propósito. Uma sessão é criada antes de ser ligada, como faz o `add` da seção 03,
e a documentação observa que, quando uma propriedade de relação é opcional, o SwiftData só impõe as
contagens mínima e máxima quando ela não é `nil`.

## A regra de exclusão

A regra diz o que acontece com o outro lado quando um registro é apagado. A documentação da Apple para
`Schema.Relationship.DeleteRule` lista quatro:

| regra | quando um curso é apagado |
|---|---|
| `.nullify`, a padrão | as sessões ficam, com `course` posto em `nil` |
| `.cascade` | as sessões são apagadas com ele |
| `.deny` | o curso não pode ser apagado enquanto tiver sessões |
| `.noAction` | nada é feito com as sessões, que continuam apontando para um curso que não existe mais |

**O planner usa `.cascade`, e o motivo é o que o estudante vê.** Uma sessão sem curso é uma sessão que
nenhuma tela mostra: o `CourseDetailView` lista as sessões de um curso, e o `value` da seção 02 devolve
`nil` para uma sem curso. Com a padrão, apagar um curso deixaria as sessões no armazenamento, invisíveis,
ainda contadas por qualquer coisa que some todos os registros, e ainda enviadas pela sincronização da
aula 14. O `.cascade` diz que as sessões de um curso fazem parte do curso.

A padrão é a que não perde nada, e é por isso que é a padrão. **A regra é uma decisão sobre os dados, não
um ajuste**: um app em que um curso é uma etiqueta em sessões independentes ia querer `.nullify`, e um
app em que apagar um curso com histórico devesse exigir um segundo passo ia querer `.deny`, e uma tela
que explique por quê.

## Uma relação não é uma chave estrangeira que você mantém

O servidor do planner e os valores da aula 1 ligam uma sessão ao seu curso por `courseID`, texto. Os
registros ligam por referência. Os dois estão certos no seu lugar: um id é o que atravessa uma rede e
sobrevive em outro telefone; uma referência é o que o armazenamento mantém consistente por você, com a
regra de exclusão acima, para que nenhum código seu tenha de achar e consertar as sessões de um curso
apagado. O `value` da seção 02 é onde um vira o outro.
