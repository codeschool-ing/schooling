---
title: O que um lambda substitui
version: 1
---

**Um lambda é um jeito de entregar um pedaço de comportamento a um método sem escrever uma classe em
volta dele.** Antes do Java 8, lançado em 2014, o único jeito de dar ao `sort` uma regra para
comparar duas coisas era um objeto cuja classe tivesse um método `compare`, e o jeito mais curto de
escrever um era uma classe anônima (aula 17 do `java`). Aqui está a mesma ordenação escrita dos dois
jeitos:

```java
// BeforeLambdas.java: one sort, written the way Java 7 wrote it and the way Java 8 does
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public class BeforeLambdas {
    public static void main(String[] args) {
        List<String> titles = new ArrayList<>(List.of("Dune", "Emma", "Ulysses", "It", "Beloved"));
        titles.sort(new Comparator<String>() {
            @Override
            public int compare(String a, String b) {
                return Integer.compare(a.length(), b.length());
            }
        });
        System.out.println("anonymous class: " + titles);

        List<String> again = new ArrayList<>(List.of("Dune", "Emma", "Ulysses", "It", "Beloved"));
        again.sort((a, b) -> Integer.compare(a.length(), b.length()));
        System.out.println("lambda:          " + again);
    }
}
```

```
ana@vm:~/fp/lambdas$ java BeforeLambdas.java
anonymous class: [It, Dune, Emma, Ulysses, Beloved]
lambda:          [It, Dune, Emma, Ulysses, Beloved]
```

As duas linhas de saída são idênticas, e também a única linha que decide a ordem:
`Integer.compare(a.length(), b.length())`. **Todo o resto da classe anônima era cerimônia**: o
`new`, o nome da interface, o tipo genérico, o `@Override`, a assinatura do método e as chaves dele.
O lambda guarda os parâmetros, uma seta e o corpo. O compilador deduz o resto pelo lugar onde o
lambda está escrito, porque `sort` quer um `Comparator<String>` e essa interface tem exatamente um
método a implementar. A aula 2 dá nome a esse tipo de interface.

Leia a saída procurando mais uma coisa: `Dune` e `Emma` têm o mesmo tamanho e ficaram na ordem em
que foram dados. `List.sort` é **estável**, então elementos que comparam como iguais mantêm seus
lugares.

## Não é uma classe anônima mais curta

É tentador ler a seta como uma abreviação que o compilador expande de volta numa classe anônima. Os
arquivos de classe dizem outra coisa:

```
ana@vm:~/fp/lambdas$ javac -d out BeforeLambdas.java
ana@vm:~/fp/lambdas$ ls out
BeforeLambdas$1.class
BeforeLambdas.class
ana@vm:~/fp/lambdas$ javap -p out/BeforeLambdas.class
Compiled from "BeforeLambdas.java"
public class BeforeLambdas {
  public BeforeLambdas();
  public static void main(java.lang.String[]);
  private static int lambda$main$0(java.lang.String, java.lang.String);
}
ana@vm:~/fp/lambdas$ javap -c -p out/BeforeLambdas.class | grep invokedynamic
        41: invokedynamic #47,  0             // InvokeDynamic #0:makeConcatWithConstants:(Ljava/lang/String;)Ljava/lang/String;
        71: invokedynamic #57,  0             // InvokeDynamic #1:compare:()Ljava/util/Comparator;
        88: invokedynamic #61,  0             // InvokeDynamic #2:makeConcatWithConstants:(Ljava/lang/String;)Ljava/lang/String;
```

**A classe anônima virou um arquivo só dela, `BeforeLambdas$1.class`. O lambda, não.** O `javap`
lista o que há dentro da classe, e o corpo do lambda está lá como um método privado estático que o
compilador chamou de `lambda$main$0`. Onde o lambda é usado, o bytecode diz `invokedynamic`: uma
instrução que pede à JVM, na primeira vez que roda, para construir um objeto que implementa
`Comparator` em volta desse método. É o do meio dos três, o que diz
`compare:()Ljava/util/Comparator;`. Os outros dois são os dois `+` que juntam strings nas linhas de
`println`, que o compilador também transforma em `invokedynamic` desde o Java 9: a instrução é um
jeito geral de deixar a JVM decidir como construir algo, e os lambdas foram o primeiro grande
cliente dela.

Daí saem três consequências, e o resto desta aula e a próxima tratam delas:

- **um lambda é um objeto de um tipo de interface**, construído em tempo de execução, então pode ser
  guardado numa variável, passado e devolvido como qualquer outro objeto;
- **ele não tem identidade própria em que valha a pena confiar**: nenhum nome de classe que você
  escolheu, nenhum campo e nenhum `this` próprio que signifique algo, o que a seção 06 mostra;
- **ele custa menos que uma classe anônima**: nenhum arquivo extra para carregar, e um lambda que não
  usa nada do que está em volta é construído uma vez e reaproveitado.

## O que ele substituiu, na prática

Classes anônimas estavam em todo lugar onde uma biblioteca queria comportamento: um `Comparator`
para ordenar, um `Runnable` para uma thread, um listener para um botão. Todos continuam lá, com as
mesmas interfaces, e todos agora aceitam um lambda. Nada foi tirado da linguagem para abrir espaço; o
que mudou é que **passar uma regra ficou tão curto quanto passar um valor**, e as APIs passaram a ser
escritas para receber regras em todo lugar. A Stream API das aulas 6 a 9 é a maior delas, e seria
ilegível com classes anônimas.
