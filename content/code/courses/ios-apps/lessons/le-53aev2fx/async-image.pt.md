---
title: AsyncImage, a imagem de uma linha
version: 1
---

**O SwiftUI mostra uma imagem a partir de uma URL numa linha, e essa linha esconde três decisões.** O
`AsyncImage` recebe uma URL, baixa, decodifica e desenha, com um marcador enquanto espera. Para uma
imagem numa tela, esse é o trabalho inteiro. Para uma lista de cinquenta capas de curso, ele faz três
escolhas por você: quão grande a imagem decodificada fica na memória, se os bytes ficam guardados para
a próxima vez, e o que acontece com um download cuja linha saiu da tela. Esta aula trata de fazer
essas escolhas de propósito.

O SwiftUI desta aula foi escrito a partir da documentação da Apple para `AsyncImage` e
`AsyncImagePhase`, lida em 30 de outubro de 2026, e **nada dele foi executado**. As decisões por baixo
dele são Swift puro e aritmética, e as seções 04 e 06 as rodam.

## A forma curta

A lista de cursos do planner mostra uma capa ao lado de cada curso. A versão mais curta:

```swift
// CourseRow.swift
import SwiftUI
import PlannerCore

struct CourseRow: View {
    let course: Course
    let cover: URL

    var body: some View {
        HStack {
            AsyncImage(url: cover) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 80, height: 80)
            .clipped()
            Text(course.title)
        }
    }
}
```

**Os modificadores vão na imagem dentro da closure, não no `AsyncImage`.** A documentação da Apple diz
isso com todas as letras: `resizable` é um modificador de `Image`, e o `AsyncImage` não é uma `Image`,
então a closure entrega uma para você modificar. Sem o `resizable`, a imagem é desenhada no próprio
tamanho em pixels e o frame corta a parte dela que cai dentro.

## O que ele faz com os bytes

A documentação da Apple diz que o `AsyncImage` baixa com o `URLSession` compartilhado. No iOS 27 em
diante ele também guarda os dados baixados em cache do jeito que o HTTP permite, num cache que o
sistema cria, e uma hierarquia de views pode entregar a ele uma sessão própria com o modificador
`asyncImageURLSession`. **No iOS 17, que este curso tem como alvo, nenhum dos dois é prometido**: uma
capa que sai da tela e volta pode ser baixada de novo. A seção 06 constrói um cache que o app
controla, que se comporta igual em toda versão.

O que ele nunca faz é encolher a imagem. O `AsyncImage` decodifica a imagem no tamanho que o arquivo
tem, e a seção 04 mostra quanto isso custa.
