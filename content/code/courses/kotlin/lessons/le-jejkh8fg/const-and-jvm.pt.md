---
title: const, @JvmStatic, e o que o Java vê
version: 1
---

Um companion object é um objeto de verdade, detalhe que o código Kotlin nunca nota e o código Java
sempre nota. O `javap`, que o JDK instalou na lição 1, imprime o que uma classe compilada declara.
Compile o `Companion.kt` da seção 03 num diretório de arquivos de classe e pergunte a ele:

```
ana@vm:~/kt/l10$ kotlinc Companion.kt -d classes
ana@vm:~/kt/l10$ ls classes
CompanionKt.class
META-INF
Session$Companion.class
Session.class
ana@vm:~/kt/l10$ javap -cp classes Session
Compiled from "Companion.kt"
public final class Session {
  public static final Session$Companion Companion;
  public static final int MAX_MINUTES;
  public final java.lang.String getCourse();
  public final int getMinutes();
  public static final int access$getCreated$cp();
  public static final void access$setCreated$cp(int);
  public Session(java.lang.String, int, kotlin.jvm.internal.DefaultConstructorMarker);
  static {};
}
ana@vm:~/kt/l10$ javap -cp classes 'Session$Companion'
Compiled from "Companion.kt"
public final class Session$Companion {
  public final Session of(java.lang.String, int);
  public final Session parse(java.lang.String);
  public final int getCount();
  public Session$Companion(kotlin.jvm.internal.DefaultConstructorMarker);
}
```

A classe `Session` guarda um **campo estático chamado `Companion`**, a única instância do companion,
do tipo `Session$Companion`. Toda função mora nessa classe interna, não em `Session`. Do Java, portanto,
`Session.of("Kotlin", 45)` não compila; tem de ser `Session.Companion.of(…)`.

`MAX_MINUTES` é a exceção: é um `public static final int` direto em `Session`. **`const val` é um valor
conhecido quando o programa é compilado**, um número, uma `String` ou um `Boolean` escrito como
literal, e o compilador o copia para cada lugar que o usa, como o Java faz com uma constante
`static final`. Um `val` comum num companion é uma propriedade, lida por um getter.

## Fazendo a chamada no Java parecer a do Kotlin

O `@JvmStatic` numa função do companion pede ao compilador que ponha também um método estático na
classe de fora, que repassa para o companion:

```kotlin
// Static.kt
class Session private constructor(val course: String, val minutes: Int) {
    companion object {
        @JvmStatic
        fun of(course: String, minutes: Int): Session = Session(course, minutes)
    }
}
```

```
ana@vm:~/kt/l10$ kotlinc Static.kt -d static
ana@vm:~/kt/l10$ javap -cp static Session
Compiled from "Static.kt"
public final class Session {
  public static final Session$Companion Companion;
  public final java.lang.String getCourse();
  public final int getMinutes();
  public static final Session of(java.lang.String, int);
  public Session(java.lang.String, int, kotlin.jvm.internal.DefaultConstructorMarker);
  static {};
}
```

`Session` agora declara `public static Session of(…)` ela mesma, então o Java escreve `Session.of(…)`.
**Do Kotlin, nada mudou.** Essa é a regra de todas as anotações `@Jvm…`: elas mudam só o que a JVM, e
portanto o Java, enxerga. Escreva-as numa biblioteca que um código Java chama, e deixe-as de fora no
resto.

## As regras do `const`

`const val` é permitido no nível superior de um arquivo, num `object` e num companion, e só para um
primitivo ou uma `String` inicializados com um valor que o compilador calcula. `const val TODAY =
LocalDate.now()` é recusado, porque o valor só é conhecido quando o programa roda; um `val` comum é a
declaração certa para ele.
