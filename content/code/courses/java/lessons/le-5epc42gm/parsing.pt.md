---
title: De texto para número, e de volta
version: 1
---

Tudo o que entra num programa vindo de fora chega como texto: a linha de comando, um arquivo, um
formulário numa página web. `args[0]` com `"21"` é uma `String` de dois caracteres, não o número 21, e
nenhum cast transforma um no outro, porque um cast converte entre tipos numéricos e uma `String` não é
um deles. **A conversão é uma chamada de método, e pode falhar**, porque a maioria das strings não é
número.

```java
// Copies.java
public class Copies {
    public static void main(String[] args) {
        int copies = Integer.parseInt(args[0]);
        System.out.println(copies * 2);
    }
}
```

```
ana@vm:~/convert$ javac Copies.java Price.java
ana@vm:~/convert$ java Copies 21
42
ana@vm:~/convert$ java Copies "21 "
Exception in thread "main" java.lang.NumberFormatException: For input string: "21 "
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:565)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at Copies.main(Copies.java:4)
ana@vm:~/convert$ java Copies twenty; echo $?
Exception in thread "main" java.lang.NumberFormatException: For input string: "twenty"
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:565)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at Copies.main(Copies.java:4)
1
```

O `Integer.parseInt` leu `"21"` e devolveu o `int` 21. Com qualquer outra coisa, lançou um
`NumberFormatException` com o texto exato entre aspas, que vale a pena ler com atenção: a segunda
execução falhou com `"21 "`, e a única diferença é um espaço no fim que não dava para ver na linha de
comando. **O `parseInt` aceita dígitos e um sinal opcional, e nada mais, nem um espaço.** A última
linha do rastro de pilha nomeia a linha do seu código que pediu, `Copies.java:4`, e as linhas acima
dela estão dentro do JDK.

## Decimais, e a vírgula

O `Double.parseDouble` é a mesma coisa para um `double`, com duas diferenças que dá para ver aqui:

```java
// Price.java
public class Price {
    public static void main(String[] args) {
        double price = Double.parseDouble(args[0]);
        System.out.println(price * 2);
        String text = String.valueOf(price);
        System.out.println(text + 1);
    }
}
```

```
ana@vm:~/convert$ java Price 39.90
79.8
39.91
ana@vm:~/convert$ java Price " 39.90 "
79.8
39.91
ana@vm:~/convert$ java Price 39,90
Exception in thread "main" java.lang.NumberFormatException: For input string: "39,90"
	at java.base/jdk.internal.math.FloatingDecimal.check(FloatingDecimal.java:2324)
	at java.base/jdk.internal.math.FloatingDecimal.readJavaFormatString(FloatingDecimal.java:1969)
	at java.base/jdk.internal.math.FloatingDecimal.parseDouble(FloatingDecimal.java:110)
	at java.base/java.lang.Double.parseDouble(Double.java:971)
	at Price.main(Price.java:4)
```

Ele aceitou `" 39.90 "` com espaços em volta, onde o `parseInt` recusou `"21 "`: os dois métodos
foram escritos com regras diferentes, e o hábito a tirar daí é chamar `strip()` na entrada antes de
convertê-la, que a lição 7 mostra. E recusou `39,90`. **Os métodos de conversão do Java sempre leem o
ponto como separador decimal**, seja qual for a língua configurada no computador. Um usuário
brasileiro digitando um preço com vírgula, como faria em qualquer formulário em português, recebe uma
exceção, e a lição 7 mostra como se formata e se converte para um locale.

A outra direção é o `String.valueOf`, ou juntar com `+` a uma `String`. `String.valueOf(39.9)` é
`"39.9"`, e `text + 1` juntou um `1` a ela como texto, `39.91`, que é a regra da seção 04 de novo:
quando um dos lados é `String`, `+` quer dizer juntar.

| de | para | como | quando falha |
|---|---|---|---|
| `String` | `int` | `Integer.parseInt(s)` | não são dígitos, um espaço, grande demais: `NumberFormatException` |
| `String` | `long` | `Long.parseLong(s)` | o mesmo |
| `String` | `double` | `Double.parseDouble(s)` | não é número, uma vírgula: `NumberFormatException` |
| qualquer valor | `String` | `String.valueOf(x)` ou `"" + x` | nunca |
