---
title: O remember guarda um valor na composição
version: 1
---

**`remember { … }` roda a lambda na primeira vez que um composable chega àquela linha, e devolve o
mesmo resultado todas as vezes depois.** Onde ele guarda? Na composição, a árvore que a aula 3
desenhou, no nó do composable que o chamou. Isso tem duas consequências que explicam quase tudo o que
o `remember` faz e não faz.

**Cada ponto de chamada ganha o próprio valor.** Dois `RememberedCounter()` lado a lado são dois nós,
e cada um tem o seu estado lembrado; clicar num não mexe no outro. É o mesmo motivo pelo qual
`CourseRow` apareceu duas vezes na árvore da aula 3.

**O valor vive exatamente tanto quanto o nó.** Enquanto o composable fica na composição, o valor
sobrevive a toda recomposição. Quando o composable sai, porque um `if` deixou de chamá-lo ou o usuário
foi para outra tela, o nó é removido e o valor junto. Volte, e o `remember` roda a lambda de novo, do
zero. E a própria composição pertence à activity, então quando a rotação da aula 2 destrói a
activity, todo valor lembrado vai embora, que é a seção 04.

## Chaves: lembrar de novo quando uma entrada muda

Um valor lembrado pode depender de um parâmetro. Uma tela que mostra um curso pode lembrar um
formatador, uma lista ordenada ou um rascunho feito a partir daquele curso, e não pode manter o antigo
quando recebe outro curso. O `remember` aceita **chaves** para isso:

```kotlin
@Composable
fun CourseHeader(course: Course) {
    val initials = remember(course.id) { course.name.split(" ").map { it.first() }.joinToString("") }
    Text(initials)
}
```

Esse trecho ilustra a chamada e não foi compilado aqui. Com `course.id` como chave, a lambda roda de
novo sempre que o id for diferente da última vez, e é pulada caso contrário. Sem a chave, o cabeçalho
mostraria as iniciais do primeiro curso para todos os cursos seguintes, porque o `remember` não teria
motivo para rodar de novo.

**O `remember` é um cache, não um depósito.** Ele poupa trabalho e mantém um objeto estável entre as
execuções, e tudo o que precisa viver mais que o nó tem de morar em outro lugar. A seção 04 mostra o
primeiro lugar, o `rememberSaveable`; a aula 10 mostra o segundo, um `ViewModel`.
