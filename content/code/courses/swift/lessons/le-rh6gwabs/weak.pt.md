---
title: weak, a referência que não conta
version: 1
---

A correção da seção 03 é decidir qual das duas referências é **dona** e qual só **aponta**. Um curso
é dono das suas sessões: quando o curso vai embora, as sessões vão junto. Uma sessão só precisa achar
o seu curso enquanto ele existe. **`weak` marca uma referência que não soma na contagem**, e o Swift a
põe em `nil` quando o objeto para o qual ela apontava é liberado.

```swift
// Weak.swift
final class Course {
    let name: String
    var sessions: [StudySession] = []
    init(name: String) { self.name = name }
    deinit { print("\(name): course freed") }
}

final class StudySession {
    let minutes: Int
    weak var course: Course?
    init(minutes: Int) { self.minutes = minutes }
    deinit { print("\(minutes)-minute session freed") }
}

var kept: StudySession?

func plan() {
    let swift = Course(name: "Swift")
    let session = StudySession(minutes: 45)
    swift.sessions.append(session)
    session.course = swift
    kept = session
    print("inside plan(): course is \(session.course?.name ?? "gone")")
}

plan()
print("after plan(): course is \(kept?.course?.name ?? "gone")")
kept = nil
print("the program goes on")
```

```
ana@vm:~/sw/l11$ swift Weak.swift
inside plan(): course is Swift
Swift: course freed
after plan(): course is gone
45-minute session freed
the program goes on
```

Uma palavra mudou na classe, `weak` antes de `var course`. Para mostrar o que o `weak` faz quando o
objeto dele sai, o programa mantém a sessão viva depois de `plan()` numa global, `kept`, que o
programa do ciclo não tinha.

Leia a saída em ordem. Dentro de `plan()` a sessão alcança o curso. Quando `plan()` retorna, o local
`swift` era a única referência forte ao curso, porque a referência da sessão não conta, então **o
curso é liberado na hora**, e com ele o array que segurava a sessão. A sessão sobrevive, segurada por
`kept`, e o `course` dela agora é `nil`: o `?? "gone"` imprimiu `gone`. Depois o `kept = nil` libera a
sessão também.

## Por que weak é sempre um var opcional

Uma referência fraca precisa poder virar `nil` sozinha, num momento que nenhuma linha do seu código
escolheu. Então ela tem de ser opcional, e tem de ser `var`: `weak let course: Course` não compila.
Todo uso passa então pelas ferramentas de opcionais da lição 2, `?.`, `if let`, `guard let`, e esse é
o ponto. **Código que segue uma referência fraca precisa dizer o que acontece quando o outro objeto
já foi.**

## Qual lado fica com o weak

A regra prática é a da posse: **o pai segura o filho com força e o filho aponta para o pai com
`weak`.** Um curso segura sessões; uma sessão aponta de volta com `weak`. Uma tela segura as partes
que desenha; uma parte que avisa a tela de um toque aponta de volta com `weak`. Nos frameworks da
Apple esse segundo formato tem nome, o delegate, e uma propriedade delegate é declarada `weak`
exatamente por isso.
