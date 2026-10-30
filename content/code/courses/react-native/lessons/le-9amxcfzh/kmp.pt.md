---
title: Kotlin Multiplatform
version: 1
---

**O Kotlin Multiplatform, da JetBrains, começa pela outra ponta.** Em vez de um framework para o app
inteiro, ele compartilha a parte que é igual nas duas plataformas, os modelos, as regras, a rede, o
armazenamento, como um módulo Kotlin, e deixa cada plataforma manter a própria interface.

A regra do total da semana do planner, compartilhada, seria Kotlin puro numa pasta `commonMain`:

```kotlin
data class Session(val id: String, val course: String, val date: String, val minutes: Int, val done: Boolean)

fun weekTotal(sessions: List<Session>, monday: String, nextMonday: String): Pair<Int, Int> {
    val week = sessions.filter { it.date >= monday && it.date < nextMonday }
    return week.filter { it.done }.sumOf { it.minutes } to week.sumOf { it.minutes }
}
```

*Escrito para comparar e não compilado.* O Android a chama como Kotlin comum; o iOS a chama a partir do
Swift, como um framework que o Kotlin/Native produziu. Onde as plataformas diferem, o `expect` declara algo
no código comum e o `actual` o fornece por plataforma, que é o `Platform.select` e os arquivos `.ios.ts` da
aula 6 levados para dentro do sistema de tipos.

**O que ele compra.** A interface de cada plataforma é totalmente nativa, Compose no Android e SwiftUI no
iOS, então ela é exatamente tão boa quanto a de um app nativo, porque é uma. A parte compartilhada pode ser
adotada um módulo por vez, num app que já existe, o que nenhum outro caminho permite com tanta suavidade.

**O que ele custa.** Duas interfaces continuam sendo duas interfaces: toda tela é escrita duas vezes, por
pessoas que conhecem Compose e SwiftUI. O **Compose Multiplatform** tira isso compartilhando as telas
também, desenhadas pelo próprio motor no iOS, o que traz de volta a troca do Flutter: uma interface, não a da
própria plataforma.
