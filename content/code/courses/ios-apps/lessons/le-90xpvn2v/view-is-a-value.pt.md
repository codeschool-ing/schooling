---
title: Uma view é uma descrição, não uma coisa na tela
version: 1
---

**Uma view SwiftUI é um valor pequeno que descreve parte da tela, e não é essa parte da tela.** A
`CourseListView` da aula 2 é uma `struct` com um array dentro e um `body`. Criar uma aloca alguns
bytes e não desenha nada. O SwiftUI lê a descrição, calcula o que deve estar na tela, e guarda a coisa
de verdade, os pixels e os objetos da plataforma por trás deles, num lugar em que você nunca mexe.

A imagem que a maioria das pessoas traz de outros toolkits é a de uma view como um objeto que mora na
tela: você cria um rótulo uma vez, guarda uma referência a ele e depois muda o texto. **Aqui não há
nada a que guardar referência.** Um valor de view é criado, lido e jogado fora, e um novo é criado na
próxima vez que o SwiftUI precisar de uma descrição. Mudar o que a tela mostra quer dizer mudar os
dados de que a descrição é feita, nunca mexer na tela.

Este é o protocolo `View` como a documentação da Apple o apresenta, lida em 30 de outubro de 2026:

```swift
struct MyView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
```

Um requisito, `body`, que é uma propriedade computada: cada vez que é lida, ela roda e devolve uma
descrição nova. A seção 04 trata de quando o SwiftUI a lê, e a seção 05 conta.

## O que decorre de uma view ser um valor

- **Fazer uma view é barato, então o SwiftUI as faz à vontade.** Uma tela de cinquenta linhas cria
  cinquenta structs pequenas toda vez que é descrita de novo, e isso é o projeto funcionando como
  previsto.
- **Uma view não consegue lembrar nada numa propriedade armazenada comum.** Um `var count = 0` dentro
  de uma struct de view volta a zero toda vez que a struct é criada de novo, que é toda vez que o
  `body` do pai roda. O que uma view precisa lembrar vai num armazenamento que o SwiftUI guarda para
  ela, o `@State`, que é a aula 6.
- **Duas views com a mesma descrição são intercambiáveis.** É isso que deixa o SwiftUI comparar a
  descrição nova com a antiga e mudar só o que difere.

Como o `App`, um tipo que obedece a `View` na própria declaração roda no main actor, diz a
documentação da Apple para `View`, que é onde o desenho acontece. Nada nesta seção foi executado para o
curso; as partes desta aula que rodaram são as seções 03, 05, 06 e 07, que reconstroem os mecanismos
em Swift puro.
