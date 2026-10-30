---
title: O R8, e o retrace
version: 1
---

**O R8 é por onde todo build de release Android passa, e ele roda em qualquer bytecode Java, não só
no de um app Android.** Isso torna possível vê-lo trabalhar no seu computador sem o sistema de build
do Android: um programa pequeno compilado pelo JDK, encolhido pelo R8, rodado até quebrar, e a pilha
dele lida de volta com o **retrace**, a ferramenta que vem dentro do R8 para isso. O programa é em
Java porque o JDK da lição 1 o compila sem mais nada instalado; o R8 enxerga bytecode, e Kotlin
compila para o mesmo bytecode, então ele trata uma classe Kotlin do mesmo jeito.

O R8 é publicado no repositório Maven do Google como um jar. Baixe uma vez:

```sh
curl -fL -o ~/android/r8.jar https://dl.google.com/dl/android/maven2/com/android/tools/r8/8.13.25/r8-8.13.25.jar
```

## O programa

Crie uma pasta `~/planner/jvm/src/planner` e salve isto como `Week.java` dentro dela:

```java
// Week.java: the same bug as week.ts, in the language R8 reads
package planner;

import java.util.List;
import java.util.Map;

public class Week {
    record Session(String course, int minutes) {}

    static int totalFor(Map<String, List<Session>> byCourse, String course) {
        int total = 0;
        for (Session s : byCourse.get(course)) {
            total += s.minutes();
        }
        return total;
    }

    public static void main(String[] args) {
        Map<String, List<Session>> byCourse = Map.of("spanish", List.of(new Session("spanish", 30), new Session("spanish", 45)));
        System.out.println("spanish " + totalFor(byCourse, "spanish"));
        System.out.println("guitar " + totalFor(byCourse, "guitar"));
    }
}
```

O R8 precisa saber o que deve sobreviver com o próprio nome. Num app, o Gradle fornece a maior parte
disso a partir do plugin do Android; aqui são duas linhas. Salve isto em `~/planner/jvm` como
`rules.pro`:

```
-keep class planner.Week { public static void main(java.lang.String[]); }
-keepattributes SourceFile,LineNumberTable
```

A primeira mantém o ponto de entrada; todo o resto pode ser renomeado, embutido ou removido. A
segunda mantém os números de linha, sem os quais nenhum retrace diria qual linha, e é a configuração
que todo release Android deveria ter.

## Compilar, encolher, quebrar

```
ana@dev:~/planner/jvm$ javac -d classes src/planner/Week.java && jar --create --file week.jar -C classes .
ana@dev:~/planner/jvm$ java -cp ~/android/r8.jar com.android.tools.r8.R8 --release --classfile --lib /usr/lib/jvm/java-21-openjdk-amd64 --pg-conf rules.pro --pg-map-output mapping.txt --output shrunk.jar week.jar
ana@dev:~/planner/jvm$ ls -l week.jar shrunk.jar; unzip -Z1 shrunk.jar
-rw-r--r-- 1 ana ana 2105 Oct 30 15:55 shrunk.jar
-rw-r--r-- 1 ana ana 2232 Oct 30 15:55 week.jar
META-INF/MANIFEST.MF
planner/Week.class
planner/a.class
ana@dev:~/planner/jvm$ java -cp shrunk.jar planner.Week 2> trace.txt; cat trace.txt
spanish 75
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "java.util.List.iterator()" because the return value of "java.util.Map.get(Object)" is null
	at planner.Week.main(r8-map-id-6bbc4a2bb4d026e05f8d405853da754fac38238bac9da0705077d66fa4cc4b9e:7)
```

**O jar encolhido tem uma classe chamada `a`**, que era `Week$Session`. E a pilha dele é mais curta
que a original: **um quadro em vez de dois**, em `main`, numa linha 7 que não existe em `Week.java`,
num arquivo com o nome do identificador do mapeamento. O R8 embutiu `totalFor` dentro de `main`, então
o método onde está o bug sumiu da pilha.

## Lendo de volta

```
ana@dev:~/planner/jvm$ java -cp ~/android/r8.jar com.android.tools.r8.retrace.Retrace mapping.txt trace.txt
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "java.util.List.iterator()" because the return value of "java.util.Map.get(Object)" is null
	at planner.Week.totalFor(Week.java:12)
	at planner.Week.main(Week.java:21)
ana@dev:~/planner/jvm$ java -cp week.jar planner.Week 2>&1 | tail -n 3
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "java.util.List.iterator()" because the return value of "java.util.Map.get(Object)" is null
	at planner.Week.totalFor(Week.java:12)
	at planner.Week.main(Week.java:21)
```

**O retrace devolveu o quadro que o inlining tirou**, `totalFor` na linha 12, o `for` sobre uma lista
que é `null`, chamado da linha 21. O último comando roda o jar que nunca foi encolhido, e a pilha dele
são os mesmos dois quadros: o retrace devolveu exatamente o que o R8 tirou. O arquivo de mapeamento
diz como: cada faixa de linhas do método encolhido aponta de volta para as linhas dos métodos que
foram dobrados dentro dele. Esse é o arquivo que o release precisa guardar e enviar, lição 12; com o
mapeamento de outro build, o mesmo comando imprimiria bobagens com toda a confiança.
