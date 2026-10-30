---
title: Onde uma hierarquia de classes dá errado
version: 1
---

O primeiro desenho que a maioria das pessoas busca é uma árvore de classes: uma classe base com o
que todos compartilham, e uma subclasse para cada tipo de coisa. Funciona até alguma coisa pertencer a
dois galhos ao mesmo tempo. **Uma classe tem uma superclasse só, então um tipo que é duas coisas ao
mesmo tempo precisa escolher uma delas e copiar a outra.**

O planner tem sessões de estudo, que tomam tempo, e provas, que têm nota. Aí uma estudante pede um
simulado, que tem tempo e nota:

```swift
// Hierarchy.swift
class StudyItem {
    let title: String
    init(title: String) { self.title = title }
    var minutes: Int { 0 }
    var grade: Int? { nil }
}

class StudySession: StudyItem {
    let length: Int
    init(title: String, length: Int) {
        self.length = length
        super.init(title: title)
    }
    override var minutes: Int { length }
}

class Exam: StudyItem {
    let score: Int
    init(title: String, score: Int) {
        self.score = score
        super.init(title: title)
    }
    override var grade: Int? { score }
}

// timed and graded, and a class can have only one superclass
class MockExam: Exam {
    let length: Int
    init(title: String, score: Int, length: Int) {
        self.length = length
        super.init(title: title, score: score)
    }
}

let week: [StudyItem] = [
    StudySession(title: "Optionals", length: 45),
    Exam(title: "Swift basics", score: 80),
    MockExam(title: "Generics", score: 70, length: 60),
]
print("minutes this week:", week.map(\.minutes).reduce(0, +))
```

```
ana@vm:~/sw/l10$ swift Hierarchy.swift
minutes this week: 45
```

A semana teve 45 minutos de estudo e um simulado de 60 minutos, e o total diz 45. Nada deixou de
compilar e nada quebrou. `MockExam` herdou `minutes` de `StudyItem`, onde vale `0`, porque está sob
`Exam` e não sob `StudySession`, e ninguém se lembrou de sobrescrever.

## Três coisas deram errado de uma vez

- **A classe base responde por todos.** `StudyItem` teve de declarar `minutes` e `grade` para o array
  poder perguntar a todo item, e teve de dar um valor a eles, então deu um errado: `0` minutos para
  uma prova é um palpite vestido de fato. Toda subclasse herda o palpite.
- **O segundo pai é copiado.** `MockExam` declara `length` de novo, porque o código que trata da
  duração vive em `StudySession` e uma classe não herda de duas classes.
- **O compilador não ajuda.** Sobrescrever é opcional, então uma subclasse que esquece é um programa
  correto com um número errado dentro, o pior tipo de defeito: o estouro da aula 1 pelo menos parava
  o programa.

Hierarquias também só crescem para baixo. Uma leitura sem minutos e sem nota ganha os dois mesmo
assim, e no dia em que o planner precisar de uma propriedade "tem prazo", ela vai para a classe base,
onde todo item responde a ela, tenha prazo ou não.

## A pergunta a fazer no lugar

A árvore perguntou "o que um simulado **é**?", e essa pergunta tem uma resposta por classe. A
alternativa pergunta "o que ele **sabe fazer**?": ele toma tempo, e tem nota. São duas capacidades,
independentes uma da outra, e a aula 8 já tem a ferramenta para uma capacidade. A seção 03 reconstrói
o planner com ela.
