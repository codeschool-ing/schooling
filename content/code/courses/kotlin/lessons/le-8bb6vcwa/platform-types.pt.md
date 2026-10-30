---
title: Onde a proteção termina: os valores do Java
version: 1
---

Os dois tipos do Kotlin existem só no Kotlin. **Um valor que vem de código Java não tem `?` nem a
falta dele**, porque o Java nunca escreveu isso. O próprio Android é quase todo Java, e muito do que
um programa Kotlin chama num computador também é, então essa fronteira é cruzada o tempo todo.

O meio-termo do Kotlin é um terceiro tipo que você lê mas nunca escreve: o **tipo de plataforma**. Um
método Java que devolve `String` dá ao Kotlin uma `String!`, que quer dizer "uma string, e ninguém
sabe se ela pode ser null". O compilador então deixa você tratá-la de qualquer um dos dois jeitos, e
não verifica nada.

`System.getenv` é Java. Ele devolve o valor de uma variável de ambiente, ou `null` quando a variável
não está definida:

```kotlin
// Platform.kt
fun main() {
    val home = System.getenv("STUDY_HOME")
    println("STUDY_HOME has ${home.length} characters")
}
```

```
ana@vm:~/kt/l02$ kotlinc Platform.kt -include-runtime -d platform.jar
ana@vm:~/kt/l02$ STUDY_HOME=/home/ana/study java -jar platform.jar
STUDY_HOME has 15 characters
ana@vm:~/kt/l02$ java -jar platform.jar
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "String.length()" because "home" is null
	at PlatformKt.main(Platform.kt:4)
	at PlatformKt.main(Platform.kt)
```

**Compilou sem uma palavra, e a segunda execução quebrou.** `home` foi inferido com o tipo de
plataforma, então `home.length` foi permitido exatamente como seria em Java, e falhou exatamente como
falharia em Java. A mensagem é a da própria JVM, nomeando o método Java que foi chamado sobre nada.

## Decida na fronteira

A solução é dar ao valor um tipo Kotlin assim que ele chega, e escolher o honesto. A variável pode
não estar definida, então o tipo dela é `String?`, e o compilador volta a mandar:

```kotlin
// PlatformFixed.kt
fun main() {
    val home: String? = System.getenv("STUDY_HOME")
    val dir = home ?: "~/study"
    println("studying in $dir")
}
```

```
ana@vm:~/kt/l02$ kotlinc PlatformFixed.kt -include-runtime -d platformfixed.jar
ana@vm:~/kt/l02$ STUDY_HOME=/home/ana/study java -jar platformfixed.jar
studying in /home/ana/study
ana@vm:~/kt/l02$ java -jar platformfixed.jar
studying in ~/study
```

**Escreva o tipo em todo valor que vem do Java**, e deixe-o anulável a menos que a documentação do
Java prometa o contrário. Declarar `String` também é permitido, e o Kotlin então insere uma
verificação naquela mesma linha:

```kotlin
// PlatformStrict.kt
fun main() {
    val home: String = System.getenv("STUDY_HOME")
    println("studying in $home")
}
```

```
ana@vm:~/kt/l02$ kotlinc PlatformStrict.kt -include-runtime -d platformstrict.jar && java -jar platformstrict.jar
Exception in thread "main" java.lang.NullPointerException: getenv(...) must not be null
	at PlatformStrictKt.main(PlatformStrict.kt:3)
	at PlatformStrictKt.main(PlatformStrict.kt)
```

Um `null` agora falha na fronteira, com uma mensagem que nomeia a chamada de onde veio, em vez de
três chamadas depois, na primeira linha que o usou. Isso é melhor que o tipo de plataforma e pior que
`String?`, que não falha nunca.

## Anotações fecham parte da brecha

Bibliotecas Java que se importam com isso marcam os métodos com anotações como `@Nullable` e
`@NonNull`, e o compilador Kotlin as lê: um método anotado dá uma `String?` ou uma `String` de
verdade, e não um tipo de plataforma. As bibliotecas do próprio Android são anotadas assim, e é por
isso que boa parte do `android-apps` encontra tipos anuláveis de verdade e não tipos com `!`. Uma
biblioteca sem anotações é onde o crash antigo ainda mora, e o hábito acima é o que o mantém do lado
de fora.
