---
title: O !! que ninguém deveria escrever
version: 1
---

O `!!` converte uma `String?` em `String` por afirmação: diz ao compilador "isto não é null", e se
for, lança um `NullPointerException` na hora. **É o único operador que devolve exatamente o crash que
os dois tipos existem para eliminar**, e ele é escrito porque é o jeito mais curto de fazer uma recusa
sumir.

```kotlin
// Bang.kt
fun main() {
    val input = "forty"
    val minutes = input.toIntOrNull()!!
    println(minutes)
}
```

```
ana@vm:~/kt/l02$ kotlinc Bang.kt -include-runtime -d bang.jar && java -jar bang.jar
Exception in thread "main" java.lang.NullPointerException
	at BangKt.main(Bang.kt:4)
	at BangKt.main(Bang.kt)
```

O stack trace nomeia o arquivo e a linha, `Bang.kt:4`, o que é mais do que um `NullPointerException`
do Java vindo de uma chamada profunda costuma dar. Essa é toda a melhora. O programa quebrou do mesmo
jeito, e num celular um crash fecha o app na frente de quem o está usando.

## Por que ele é escrito mesmo assim

O compilador recusa `note.length` numa `String?`, e a mensagem lista duas soluções: `?.` e `!!.`. **A
segunda tem dois caracteres e faz o sublinhado vermelho sumir**, e esse é todo o motivo de ela se
espalhar. Cada `!!` é uma pequena aposta de que um valor está presente, feita por alguém com pressa,
e nada registra a aposta.

Revisões de código em times de Kotlin leem `!!` como leem um `catch` que não faz nada. É permitido, e
precisa de um motivo. Há alguns honestos:

- **um teste**, em que um crash com número de linha é exatamente a falha que você quer;
- **um valor que uma linha anterior tornou certo** de um jeito que o compilador não acompanha, por
  exemplo uma chave que você acabou de pôr num mapa e leu de volta. Mesmo aí, um `val` local com uma
  verificação costuma ser igualmente curto;
- **um programa rápido que você vai jogar fora**, que é a maioria dos programas de um curso e poucos
  dos programas de um app.

## O que escrever no lugar

Cada uma das outras três respostas diz algo que o `!!` não diz:

```kotlin
// NoBang.kt
fun main() {
    val input = "forty"
    val a = input.toIntOrNull() ?: 0
    val b = input.toIntOrNull() ?: error("minutes must be a number, got '$input'")
    println(a)
    println(b)
}
```

```
ana@vm:~/kt/l02$ kotlinc NoBang.kt -include-runtime -d nobang.jar && java -jar nobang.jar
Exception in thread "main" java.lang.IllegalStateException: minutes must be a number, got 'forty'
	at NoBangKt.main(NoBang.kt:5)
	at NoBangKt.main(NoBang.kt)
```

`error(…)` é uma função da biblioteca padrão que lança `IllegalStateException` com a mensagem que você
der. O programa para do mesmo jeito, como com `!!`, mas **a mensagem diz o que era esperado e o que
chegou**, que é do que precisa quem lê o log. Quando quebrar é o comportamento certo, faça um crash
com uma frase dentro.
