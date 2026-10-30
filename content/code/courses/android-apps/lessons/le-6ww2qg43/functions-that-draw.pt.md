---
title: Um composable é uma função que descreve, e não devolve nada
version: 1
---

**Um composable é uma função Kotlin marcada com `@Composable` que descreve uma parte da tela.** Ela
não devolve uma view, um widget nem nada; o tipo de retorno é `Unit`. O que ela faz é **emitir**: cada
composable que ela chama acrescenta um nó a uma árvore que o Compose mantém, e o Compose desenha essa
árvore. A função diz como a tela deve ficar para os valores que recebeu, e o Compose descobre o que
mudar na tela.

A imagem antiga, do sistema de `View` que a aula 2 mencionou, é a de objetos que você cria, guarda num
campo e depois manda mudar: `textView.setText("95 min")`. No Compose não há nada para guardar. Para
mostrar outro texto você chama a função de novo com outro valor, e esse é o mecanismo inteiro; a aula
5 é sobre quando o Compose faz essas chamadas.

O primeiro composable do planner mostra um curso e os minutos estudados nele nesta semana. Ele
precisa do modelo, que mora num arquivo próprio:

```kotlin
// app/src/main/java/com/example/planner/data/Course.kt
package com.example.planner.data

data class Course(val id: String, val name: String)

val sampleCourses = listOf(
    Course("kotlin", "Kotlin"),
    Course("android", "Android Apps"),
    Course("sql", "SQL Databases"),
)
```

E o composable, que a seção 04 mostra inteiro, com os imports e uma prévia:

```kotlin
@Composable
fun CourseRow(course: Course, minutesThisWeek: Int) {
    Column {
        Text(course.name, style = MaterialTheme.typography.titleMedium)
        Text(
            stringResource(R.string.minutes_this_week, minutesThisWeek),
            style = MaterialTheme.typography.bodySmall,
        )
    }
}
```

Três convenções aparecem em cinco linhas. **Um composable que emite tem nome de classe**, em
PascalCase, porque se lê como um substantivo: `CourseRow`, `Column`, `Text`. Um composable que
*devolve* um valor em vez de emitir, como `stringResource` aqui ou o `remember` da aula 4, tem nome de
função comum. E o texto vem do `strings.xml`, com `%1$d` onde entra o número, para que o `values-pt`
da aula 1 possa traduzi-lo.

## A anotação é um contrato que o compilador faz cumprir

`@Composable` não é enfeite. O plugin do compilador do Compose, `kotlin.compose` no arquivo de build,
reescreve toda função que o carrega para receber um parâmetro extra escondido, o **composer**, que é
como a função chega à árvore em que emite. Uma função comum não tem composer para repassar, então
chamar um composable a partir dela não tem como funcionar, e o compilador diz isso:

```kotlin
// app/src/main/java/com/example/planner/ui/Summary.kt
package com.example.planner.ui

import com.example.planner.data.Course

fun summary(course: Course): String {
    CourseRow(course, minutesThisWeek = 95)
    return course.name
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain compileDebugKotlin 2>&1 | grep -E "^e:|^BUILD"
e: file:///home/ana/planner/app/src/main/java/com/example/planner/ui/Summary.kt:6:5 Functions which invoke @Composable functions must be marked with the @Composable annotation
e: file:///home/ana/planner/app/src/main/java/com/example/planner/ui/Summary.kt:7:5 @Composable invocations can only happen from the context of a @Composable function
BUILD FAILED in 6s
```

Os dois erros são a mesma regra vista de dois lados: a função que chama um composable precisa ser
uma, e um composable só pode ser chamado de dentro de outro. **A correção nunca é acrescentar
`@Composable` a `summary`**: ela devolve uma string e não desenha nada, e torná-la composable faria
com que só pudesse ser chamada enquanto a tela está sendo composta. Uma função que calcula algo
continua uma função comum, e o composable a chama. O arquivo é apagado antes de seguir.
