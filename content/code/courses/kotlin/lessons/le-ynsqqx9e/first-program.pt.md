---
title: O primeiro programa, e o que o kotlinc fez dele
version: 1
---

Um programa Kotlin começa numa função chamada `main`. Ela não precisa morar dentro de uma classe, não
recebe argumentos a menos que você peça, e não devolve nada. Crie uma pasta para os programas desta
lição, `~/kt/l01`, e salve isto como `Hello.kt` nela:

```kotlin
// Hello.kt
fun main() {
    println("Hello, Kotlin")
}
```

`fun` declara uma função. O `println` imprime uma linha, e vem da biblioteca padrão do Kotlin, que
todo arquivo Kotlin usa sem import. Não há ponto e vírgula: o Kotlin termina uma instrução no fim da
linha, e só aceita ponto e vírgula onde duas instruções dividem uma linha.

## Compile, depois execute

O `kotlinc` compila o arquivo. `-d hello.jar` diz onde pôr o resultado, e `-include-runtime` diz para
pôr a biblioteca padrão do Kotlin no mesmo arquivo. Depois o `java`, o programa que o JDK instalou,
executa:

```
ana@vm:~/kt/l01$ kotlinc Hello.kt -include-runtime -d hello.jar
ana@vm:~/kt/l01$ ls -lh hello.jar
-rw-r--r-- 1 ana ana 5.5M Oct 30 03:01 hello.jar
ana@vm:~/kt/l01$ java -jar hello.jar
Hello, Kotlin
```

O compilador levou alguns segundos e não imprimiu nada, que é a cara do sucesso. **O jar tem 5,5 MB
para um programa de três linhas**, e quase tudo isso é a biblioteca padrão. É o preço de um jar que
roda em qualquer lugar onde haja uma JVM, sem mais nada instalado.

## O que o jar contém

Um jar é um arquivo zip. Deixe o runtime de fora e olhe dentro:

```
ana@vm:~/kt/l01$ kotlinc Hello.kt -d small.jar
ana@vm:~/kt/l01$ ls -lh small.jar
-rw-r--r-- 1 ana ana 1020 Oct 30 03:01 small.jar
ana@vm:~/kt/l01$ unzip -l small.jar
Archive:  small.jar
  Length      Date    Time    Name
---------  ---------- -----   ----
       76  1979-12-31 21:00   META-INF/MANIFEST.MF
      636  1979-12-31 21:00   HelloKt.class
       37  1979-12-31 21:00   META-INF/main.kotlin_module
---------                     -------
      749                     3 files
ana@vm:~/kt/l01$ java -jar small.jar
Hello, Kotlin
```

O programa virou uma classe, `HelloKt`: o Kotlin põe as funções de `Hello.kt` que estão fora de
qualquer classe numa classe com o nome do arquivo. E este jar pequeno, de cerca de um kilobyte,
rodou com o `java` puro, uma surpresa que vale explicar. O `println` é uma das funções **inline** da
biblioteca padrão: o compilador copiou o corpo dela, uma chamada ao `System.out.println` do próprio
Java, para dentro do `HelloKt`, então nada da biblioteca do Kotlin é necessário em tempo de execução.
A lição 4 diz para que serve o `inline`.

A maior parte da biblioteca não é inline. Duas linhas que usam uma lista bastam para precisar dela:

```kotlin
// Courses.kt
fun main() {
    val courses = listOf("Kotlin", "Android")
    println(courses.joinToString(" then "))
}
```

```
ana@vm:~/kt/l01$ kotlinc Courses.kt -d courses-small.jar
ana@vm:~/kt/l01$ java -jar courses-small.jar 2>&1 | head -2
Exception in thread "main" java.lang.NoClassDefFoundError: kotlin/collections/CollectionsKt
	at CoursesKt.main(Courses.kt:3)
ana@vm:~/kt/l01$ kotlin courses-small.jar 2>&1 | head -2
Exception in thread "main" java.lang.NoClassDefFoundError: kotlin/collections/CollectionsKt
	at CoursesKt.main(Courses.kt:3)
ana@vm:~/kt/l01$ kotlin -cp courses-small.jar CoursesKt
Kotlin then Android
ana@vm:~/kt/l01$ java -cp courses-small.jar:$HOME/.local/share/kotlinc/lib/kotlin-stdlib.jar CoursesKt
Kotlin then Android
```

`NoClassDefFoundError: kotlin/collections/CollectionsKt` é a JVM dizendo que foi procurar a classe
que contém o `listOf` e não achou nada. **A solução é o class path, não o código.** O executor
`kotlin` que veio com o compilador não salva um jar entregue inteiro, e falha do mesmo jeito que o
`java`. Recebendo o jar como class path e a classe por onde começar, ele acrescenta a biblioteca
padrão ao class path por você, e o mesmo jar pequeno roda. Ou diga isso você mesmo ao `java`, com um
`-cp` que nomeia os dois jars, separados por dois-pontos.

Este curso usa `-include-runtime` e `java -jar` do começo ao fim, porque um arquivo que carrega a
própria biblioteca é uma coisa a menos para dar errado. O `android-apps` nunca vê nenhum dos dois: o
Gradle empacota a biblioteca padrão dentro do app.

## Quando o compilador recusa

Boa parte do que este curso ensina é o que o compilador se recusa a deixar passar, então vale ler
uma recusa agora. Um erro de digitação:

```kotlin
// Typo.kt
fun main() {
    printn("Hello, Kotlin")
}
```

```
ana@vm:~/kt/l01$ kotlinc Typo.kt -include-runtime -d typo.jar; echo $?
Typo.kt:3:5: error: unresolved reference 'printn'.
    printn("Hello, Kotlin")
    ^^^^^^
1
ana@vm:~/kt/l01$ ls typo.jar
ls: cannot access 'typo.jar': No such file or directory
```

**A mensagem começa com o arquivo, a linha e a coluna**, `Typo.kt:3:5`, depois o tipo, `error`,
depois o motivo, e depois a própria linha com o nome sublinhado. Linha 3, porque o comentário com o
nome do arquivo é a linha 1. Uma referência não resolvida é um nome que o compilador não achou em
lugar nenhum onde procurou. O `1` é o código de saída do `kotlinc`, e o `ls` confirma o resto: **um
arquivo com erro não produz jar nenhum**, e não um jar com a parte quebrada de fora.
