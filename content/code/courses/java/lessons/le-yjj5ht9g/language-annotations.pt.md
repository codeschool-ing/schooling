---
title: As anotações que a própria linguagem lê
version: 1
---

Uma anotação é um nome com um `@` na frente, escrito acima de uma declaração: `@Override` acima de um
método, `@Deprecated` acima de uma classe. **Sozinha, uma anotação não faz absolutamente nada.** É um
rótulo, e alguém precisa lê-lo: o compilador, uma ferramenta, ou um framework com o programa rodando.
Esta seção trata do punhado que o compilador lê, que transforma um engano que compilaria num que não
compila.

## `@Override`: diga o que você quis dizer

A lição 24 apresentou o `@Override` como o rótulo de um método que sobrescreve um da superclasse. Aqui
está o caso para o qual ele existe, um `toString` com uma letra na caixa errada:

```java
// Book.java
public class Book {
    private final String title;

    public Book(String title) {
        this.title = title;
    }

    @Override
    public String tostring() {
        return "Book[" + title + "]";
    }
}
```

```
ana@vm:~/annot$ javac Book.java
Book.java:9: error: method does not override or implement a method from a supertype
    @Override
    ^
1 error
```

Sem a anotação, isso compila. `tostring` é um método novo perfeitamente legal, ninguém o chama, e
imprimir um `Book` mostra `Book@` e um código hash, como na lição 12, sem pista nenhuma do motivo.
**O `@Override` transforma uma intenção em algo que o compilador consegue conferir**: este método
substitui um de cima, e se esse método não existe, recuse. Ponha-o em todo método que você pretende
sobrescrever, `equals`, `hashCode` e `toString` inclusive.

## `@Deprecated`: diga que um método está de saída

Uma biblioteca não pode apagar um método no dia em que acha um jeito melhor, porque o código de outras
pessoas o chama. Ela o marca, e o compilador avisa cada chamador. Duas formas, uma mais forte que a
outra:

```java
// OldDesk.java
public class OldDesk {
    @Deprecated(since = "2.0", forRemoval = true)
    public static void lendBook(String isbn) {
        System.out.println("lent " + isbn);
    }

    @Deprecated
    public static void returnBook(String isbn) {
        System.out.println("returned " + isbn);
    }
}
```

```java
// Counter.java
public class Counter {
    public static void main(String[] args) {
        OldDesk.lendBook("978-0-13-468599-1");
        OldDesk.returnBook("978-0-13-468599-1");
    }
}
```

```
ana@vm:~/annot$ javac OldDesk.java Counter.java
Counter.java:4: warning: [removal] lendBook(String) in OldDesk has been deprecated and marked for removal
        OldDesk.lendBook("978-0-13-468599-1");
               ^
Note: Counter.java uses or overrides a deprecated API.
Note: Recompile with -Xlint:deprecation for details.
1 warning
ana@vm:~/annot$ javac -Xlint:deprecation Counter.java
Counter.java:4: warning: [removal] lendBook(String) in OldDesk has been deprecated and marked for removal
        OldDesk.lendBook("978-0-13-468599-1");
               ^
Counter.java:5: warning: [deprecation] returnBook(String) in OldDesk has been deprecated
        OldDesk.returnBook("978-0-13-468599-1");
               ^
2 warnings
ana@vm:~/annot$ java Counter
lent 978-0-13-468599-1
returned 978-0-13-468599-1
```

As duas formas são tratadas de jeitos diferentes, e a diferença é a questão:

| anotação | o que o `javac` diz por padrão | significado |
|---|---|---|
| `@Deprecated` | uma `Note:` de duas linhas para o arquivo inteiro | existe um jeito melhor; este fica |
| `@Deprecated(forRemoval = true)` | um `warning: [removal]` em cada chamada | isto vai ser apagado numa versão futura |

O primeiro `javac` avisou na linha 4 e só anotou que algo no arquivo estava obsoleto; o
`-Xlint:deprecation` pediu os detalhes e trouxe a linha 5 também. O `since = "2.0"` registra a versão
da biblioteca que tornou o método obsoleto, para quem ler a documentação. **E o programa rodou mesmo
assim**: um método obsoleto funciona exatamente como antes. O aviso é sobre a próxima versão, e por
isso é fácil de ignorar e caro de ter ignorado. O próprio JDK marca métodos assim, e o `finalize` da
lição 19 é um deles.

## `@SuppressWarnings`: diga que você leu o aviso

```java
// Quiet.java
public class Quiet {
    @SuppressWarnings("removal")
    public static void main(String[] args) {
        OldDesk.lendBook("978-0-13-468599-1");
    }
}
```

```
ana@vm:~/annot$ javac Quiet.java
```

Silêncio. O `@SuppressWarnings("removal")` diz ao compilador que o autor deste método viu o aviso de
remoção e decidiu. **Ponha-o na menor declaração que precisa dele**, um método e não uma classe, para
ele não esconder o próximo aviso que ninguém viu ainda, e acrescente um comentário com o motivo quando
o motivo não for óbvio.

## `@FunctionalInterface`: diga que uma interface tem um método

Uma interface com exatamente um método abstrato pode ser implementada por um lambda, que é o assunto
do `java-functional`. O `@FunctionalInterface` declara essa intenção, e o compilador cobra a interface
por ela:

```java
// Rule.java
@FunctionalInterface
public interface Rule {
    boolean allows(String memberId);

    String describe();
}
```

```
ana@vm:~/annot$ javac Rule.java
Rule.java:2: error: Unexpected @FunctionalInterface annotation
@FunctionalInterface
^
  Rule is not a functional interface
    multiple non-overriding abstract methods found in interface Rule
1 error
```

O `describe()` é um segundo método abstrato, então um lambda não conseguiria mais implementar o `Rule`,
e o compilador diz isso na interface em vez de em cada lambda que quebraria depois.

A última das próprias da linguagem, **`@SafeVarargs`**, é uma promessa, num método com parâmetro
varargs genérico, `T... items`, de que ele não faz nada inseguro com o array que o Java monta para ele.
Ela silencia um aviso sobre generics que a lição 35 explica, e como toda promessa ao compilador vale só
o que vale o método por trás dela.
