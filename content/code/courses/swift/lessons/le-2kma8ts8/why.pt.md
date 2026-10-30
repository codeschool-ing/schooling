---
title: Esperar sem parar
version: 1
---

Um app pede a um servidor os cursos de uma estudante, e a resposta leva 200 milissegundos para
chegar. **A imagem errada é um programa que fica parado esses 200 milissegundos.** Num celular esse
programa é uma tela que não rola, não responde a um toque e, depois de alguns segundos assim, é
encerrada pelo sistema. A imagem certa é um programa que pergunta, segue fazendo outro trabalho e
volta à resposta quando ela chega.

Durante a maior parte da vida do Swift, "voltar à resposta" significou um **completion handler**:
você passava à função uma closure, e a função a chamava depois, de onde quer que a resposta
aparecesse. A aula 3 mostrou closures que são guardadas depois que a chamada retorna, marcadas com
`@escaping`; um completion handler é exatamente isso. Aqui está o planner carregando um curso e
depois as sessões dele, escrito desse jeito:

```swift
// Callbacks.swift
import Dispatch

func loadCourse(named name: String, completion: @escaping (String) -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(200)) {
        completion(name)
    }
}

func loadMinutes(for course: String, completion: @escaping ([Int]) -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(200)) {
        completion([45, 30, 60])
    }
}

let finished = DispatchSemaphore(value: 0)
print("asking for the course")
loadCourse(named: "Swift") { course in
    print("got \(course), asking for its sessions")
    loadMinutes(for: course) { minutes in
        print("\(course): \(minutes.reduce(0, +)) minutes")
        finished.signal()
    }
}
print("the request is on its way")
finished.wait()
```

```
ana@vm:~/sw/l14$ swift Callbacks.swift
asking for the course
the request is on its way
got Swift, asking for its sessions
Swift: 135 minutes
```

O `DispatchQueue.global().asyncAfter` faz o papel da rede: roda a closure em outra thread daqui a 200
milissegundos. **Leia a saída contra o fonte, e a ordem é a primeira surpresa.** "the request is on
its way" é a última linha do programa e a segunda impressa, porque o `loadCourse` retornou na hora e
só prometeu chamar de volta. As duas linhas dentro das closures vieram depois, cada uma 200
milissegundos após a anterior. O semáforo no fim impede que o programa termine antes delas: o
`wait()` bloqueia até alguém chamar `signal()`, e sem ele o programa imprimiria duas linhas e sairia.

## O que completion handlers custam

O código funciona, e três coisas nele pioram à medida que o programa cresce:

- **A ordem na página não é a ordem no tempo.** Cada passo que espera empurra o seguinte uma closure
  mais para dentro, e uma sequência de cinco pedidos vira cinco níveis de indentação.
- **Nada obriga você a chamar a closure.** Uma função com um `return` antecipado num caminho de erro
  que esquece o `completion(…)` compila, e quem chamou espera para sempre.
- **Os erros não têm para onde ir.** Uma closure não consegue lançar um erro para quem chamou e já
  retornou, então todo handler ganha um segundo parâmetro para o erro, ou um `Result`, que a aula 12
  apresentou.

O Swift 5.5 trouxe um jeito de escrever o mesmo programa como uma sequência de linhas comuns, em que
o compilador, e não você, cuida do que acontece quando a resposta chega. A seção 03 é esse programa.
Os completion handlers não sumiram: bibliotecas mais antigas ainda os oferecem, e a aula 15 encontra
o `Dispatch` de novo.
