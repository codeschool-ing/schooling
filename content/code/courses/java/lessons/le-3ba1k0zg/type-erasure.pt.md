---
title: Apagamento de tipos, ou para onde os tipos vão
version: 1
---

Tudo nesta lição até aqui aconteceu no compilador. **Em tempo de execução, os argumentos de tipo
sumiram**: uma `List<String>` e uma `List<Integer>` são a mesma classe, e a JVM nunca fica sabendo o
que estava entre os colchetes. O Java escolheu isso em 2004 para que código genérico rodasse em JVMs
e bibliotecas anteriores aos generics, e a escolha tem consequências que dá para ver.

```java
// Erased.java
import java.util.ArrayList;
import java.util.List;

public class Erased {
    public static void main(String[] args) {
        List<String> titles = new ArrayList<>();
        List<Integer> years = new ArrayList<>();
        System.out.println(titles.getClass());
        System.out.println(titles.getClass() == years.getClass());
    }
}
```

```
ana@vm:~/generics$ java Erased.java
class java.util.ArrayList
true
ana@vm:~/generics$ javap -c Box
Compiled from "Box.java"
public class Box<T> {
  public Box();
    Code:
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return

  public void put(T);
    Code:
         0: aload_0
         1: aload_1
         2: putfield      #7                  // Field item:Ljava/lang/Object;
         5: return

  public T take();
    Code:
         0: aload_0
         1: getfield      #7                  // Field item:Ljava/lang/Object;
         4: areturn
}
ana@vm:~/generics$ javap -c UseBox | grep -A1 "Box.take"
        15: invokevirtual #42                 // Method Box.take:()Ljava/lang/Object;
        18: checkcast     #45                 // class java/lang/String
```

**`titles.getClass()` é `java.util.ArrayList`, sem `<String>`**, e as classes das duas listas são uma
só. Depois o `javap` mostra no que `Box<T>` se transformou: o campo `item` é guardado como
`Ljava/lang/Object;`, e o `put` e o `take` movem `Object`s. O `T` sobrevive na assinatura que o
`javap` imprime, como informação para o compilador, e em nenhuma das instruções.

Então para onde foi a verificação de tipo? Para quem chama. O último comando procurou no bytecode do
`UseBox` a chamada a `take`. A instrução logo depois dela é um `checkcast` para `String`: **o
compilador escreveu a conversão que o `Raw.java` precisou escrever à mão**, e a escreveu só onde já
tinha provado que ela daria certo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Apagamento de tipos. À esquerda, o que o javac confere: classe Box de T com um campo item do tipo T; Box de String box; box.put de Dune; String title igual a box.take. À direita, o que a JVM executa: classe Box com um campo item do tipo Object; put recebe um Object; take devolve um Object; no ponto da chamada, invokevirtual Box.take seguido de checkcast String. O argumento de tipo String é usado pelo compilador e depois apagado; a conversão que ele garante é escrita em quem chama.\"><defs><marker id=\"jv35-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o que o javac confere</text><text x=\"400\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o que a JVM executa</text><rect x=\"20\" y=\"36\" width=\"300\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"400\" y=\"36\" width=\"300\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">class Box&lt;T&gt; {</text><text x=\"58\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">T item;</text><text x=\"34\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">}</text><text x=\"34\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Box&lt;String&gt; box = new Box&lt;&gt;();</text><text x=\"34\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">box.put(&quot;Dune&quot;);</text><text x=\"34\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">String title = box.take();</text><text x=\"414\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">class Box {</text><text x=\"438\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Object item;</text><text x=\"414\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">}</text><text x=\"414\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">new Box  (sem argumento de tipo)</text><text x=\"414\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">invokevirtual Box.put(Object)</text><text x=\"414\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">invokevirtual Box.take()</text><text x=\"414\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">checkcast String</text><path d=\"M322 110 H396\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jv35-a)\"></path><text x=\"359\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">apagado</text><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o argumento de tipo é conferido, depois jogado fora;</text><text x=\"20\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a conversão que ele torna segura é escrita em quem chama</text></svg>", "caption": "Uma classe em tempo de execução, digam o que disserem os colchetes. O compilador cumpre a promessa inserindo a conversão em cada chamada."}
```

## O que o apagamento proíbe

Como `T` não existe em tempo de execução, nada que precise dele em tempo de execução compila:

```java
// Limits.java
import java.util.List;

public class Limits<T> {
    T fresh() {
        return new T();
    }

    static boolean isTitles(Object o) {
        return o instanceof List<String>;
    }
}
```

```
ana@vm:~/generics$ javac Limits.java
Limits.java:6: error: unexpected type
        return new T();
                   ^
  required: class
  found:    type parameter T
  where T is a type-variable:
    T extends Object declared in class Limits
Limits.java:10: error: Object cannot be safely cast to List<String>
        return o instanceof List<String>;
               ^
2 errors
```

- **`new T()`** precisa saber que classe criar, e em tempo de execução não há `T` a quem perguntar. O
  contorno comum é receber o meio de criar um, como uma `Class<T>` ou um `Supplier<T>` do
  `java-functional`.
- **`o instanceof List<String>`** teria de conferir o tipo dos elementos, e a lista não o carrega.
  `o instanceof List<?>` compila, porque só pergunta se `o` é uma lista.

O mesmo motivo proíbe `new T[10]` e um campo `static` do tipo `T`, e é por isso que dois métodos
`void f(List<String>)` e `void f(List<Integer>)` não podem morar na mesma classe: depois do
apagamento, as assinaturas são idênticas. **Nada disso limita o que um programa pode fazer**; limita o
que um programa pode perguntar em tempo de execução sobre um tipo que só conhecia em tempo de
compilação.
