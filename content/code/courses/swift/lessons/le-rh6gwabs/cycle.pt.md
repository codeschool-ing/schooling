---
title: O ciclo de retenção
version: 1
---

Um planner tem cursos, e cada curso tem sessões de estudo. É natural deixar um curso segurar suas
sessões e deixar cada sessão conhecer seu curso, para que uma tela mostrando uma sessão possa
imprimir o nome do curso. **Escrito com duas propriedades comuns, isso são dois objetos segurando um
ao outro, e nenhum dos dois é liberado nunca.**

```swift
// Cycle.swift
final class Course {
    let name: String
    var sessions: [StudySession] = []
    init(name: String) { self.name = name; print("\(name): course created") }
    deinit { print("\(name): course freed") }
}

final class StudySession {
    let minutes: Int
    var course: Course?
    init(minutes: Int) { self.minutes = minutes }
    deinit { print("\(minutes)-minute session freed") }
}

func plan() {
    let swift = Course(name: "Swift")
    let session = StudySession(minutes: 45)
    swift.sessions.append(session)
    session.course = swift
    print("plan() is returning")
}

plan()
print("the program goes on")
```

```
ana@vm:~/sw/l11$ swift Cycle.swift
Swift: course created
plan() is returning
the program goes on
```

**Faltam duas linhas de `deinit`, e nada mais avisa.** O programa imprimiu o que mandaram, rodou até
o fim e saiu sem erro. Dentro de `plan()`, o nome local `swift` segurava o curso e `session` segurava
a sessão. Quando `plan()` retornou, os dois nomes sumiram e a contagem de cada objeto caiu um, mas não
chegou a zero: o curso ainda é segurado pela propriedade `course` da sessão, e a sessão ainda é
segurada pelo array `sessions` do curso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 175\" role=\"img\" data-fig=\"l11-cycle\" aria-label=\"Dois diagramas lado a lado. À esquerda, um ciclo de retenção: uma caixa Course e uma caixa StudySession, uma seta forte do curso para a sessão por sessions, e uma seta forte de volta da sessão para o curso. Setas tracejadas dos nomes locais de plan estão cortadas, porque plan retornou. Legenda: um mantém o outro vivo, o deinit nunca roda. À direita, as mesmas duas caixas, mas a seta de volta da sessão para o curso é tracejada e marcada weak; o curso é liberado, e depois a sessão.\"><defs><marker id=\"l11-cycle-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-cycle-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l11-cycle-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">um ciclo de retenção</text><text x=\"180\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">plan() retornou: os dois nomes locais sumiram</text><rect x=\"25\" y=\"70\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Course</text><rect x=\"215\" y=\"70\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"280\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">StudySession</text><path d=\"M145 82 L213 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-cycle-ah-phosphor)\"></path><text x=\"179\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sessions</text><path d=\"M215 100 L147 100\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-cycle-ah-amber)\"></path><text x=\"179\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">course (forte)</text><text x=\"180\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">um mantém o outro vivo: o deinit nunca roda</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">weak o quebra</text><text x=\"540\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">plan() retornou: os dois nomes locais sumiram</text><rect x=\"385\" y=\"70\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"445\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Course</text><rect x=\"575\" y=\"70\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">StudySession</text><path d=\"M505 82 L573 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-cycle-ah-phosphor)\"></path><text x=\"539\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sessions</text><path d=\"M575 100 L507 100\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l11-cycle-ah-wire)\"></path><text x=\"539\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">course (weak)</text><text x=\"540\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o curso é liberado, e depois a sessão</text></svg>", "caption": "À esquerda, o Cycle.swift depois que plan() retorna: os dois objetos apontam um para o outro, então nenhuma contagem chega a zero e nada é liberado. À direita, o Weak.swift: a seta de volta para o curso é fraca e não conta, então o curso sai primeiro e a sessão vai em seguida."}
```

Isso é um **ciclo de retenção**: um laço de referências fortes sem nada de fora apontando para
dentro. Nenhuma linha do programa consegue alcançar algum dos dois objetos de novo, porque as únicas
referências a eles são as de um para o outro. E o ARC libera um objeto quando a contagem é zero, não
quando ele fica inalcançável, então os dois ficam na memória até o processo terminar.

## Por que um vazamento tão pequeno importa

Cem e poucos bytes não são nada, e a seção 07 os mede: 112. O vazamento nunca é do tamanho dos
primeiros dois objetos. Num app, o objeto num ciclo é uma tela com tudo o que ela segura: o curso, as
sessões, as imagens que carregou e um timer que iniciou. Abra essa tela vinte vezes numa sessão de uso
e há vinte cópias na memória, cada uma ainda rodando o seu timer. Num celular, o sistema encerra um
app que usa memória demais, e quem o está usando vê um app que se fecha sozinho.

**O ciclo não precisa de erro em nenhuma linha.** Cada propriedade, lida sozinha, está certa: um curso
tem sessões, uma sessão pertence a um curso. O que está errado é o par, e é por isso que o compilador
não avisa. A seção 04 mostra a palavra que corrige, e a seção 07 mostra como achar um ciclo quando
você não o viu sendo escrito.

Alguns programas nunca vazam assim: um ciclo precisa de pelo menos duas instâncias de classe, ou de
uma instância de classe e uma closure (seção 06), então structs segurando structs não formam um.
