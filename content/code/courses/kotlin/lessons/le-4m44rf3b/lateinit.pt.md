---
title: lateinit, para um valor que chega depois da construção
version: 1
---

Toda propriedade até aqui recebeu o valor quando o objeto foi montado. Algumas não conseguem: no
Android, um objeto de tela é criado pelo sistema, e as views e serviços que ele usa chegam um momento
depois. **`lateinit var` declara uma propriedade não nula que pode ficar vazia até a primeira
atribuição**, sem torná-la anulável e responder `null` em cada uso.

```kotlin
// Late.kt
class Screen {
    lateinit var title: String

    fun show() = println("showing $title")

    fun ready() = this::title.isInitialized
}

fun main() {
    val s = Screen()
    println(s.ready())
    s.title = "Week 44"
    println(s.ready())
    s.show()
    Screen().show()
}
```

```
ana@vm:~/kt/l07$ kotlinc Late.kt -include-runtime -d late.jar && java -jar late.jar
false
true
showing Week 44
Exception in thread "main" kotlin.UninitializedPropertyAccessException: lateinit property title has not been initialized
	at Screen.getTitle(Late.kt:3)
	at Screen.show(Late.kt:5)
	at LateKt.main(Late.kt:16)
	at LateKt.main(Late.kt)
```

`title` é uma `String`, não uma `String?`, então `show` a usa sem verificação. O preço é a última
linha: **ler uma propriedade `lateinit` antes da atribuição lança
`UninitializedPropertyAccessException`**, com o nome da propriedade na mensagem. Isso é um crash, como
o `!!` da lição 2, e é a mesma aposta: a de que o valor vai estar lá quando for preciso.

`this::title.isInitialized` pergunta se a atribuição já aconteceu, o que de vez em quando é útil em
código de limpeza. Precisar disso com frequência é sinal de que a propriedade devia ser anulável.

## As regras

O `lateinit` só é permitido num `var`, porque precisa ser atribuído depois, e só para um tipo não nulo
que não seja primitivo como `Int` ou `Boolean`, porque esses não têm na JVM um estado vazio que
signifique "ainda não".

## Quando usar, e a alternativa

**Use `lateinit` quando algo fora da classe garante a atribuição antes de qualquer uso**, e a garantia
faz parte de como o framework funciona: o ciclo de vida do Android, o método de preparação de um
framework de teste na lição 18. Quando o valor pode ser calculado pela própria classe na primeira vez
em que é preciso, o `by lazy` da lição 11 é melhor: ele não é lido vazio, porque lê-lo é o que o
preenche.
