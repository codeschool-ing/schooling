---
title: Expressões `switch` e casamento de padrões
version: 1
---

O `switch` da seção 03 é uma instrução: ele faz coisas e não produz nada, e cada `case` continua no
seguinte. **Desde o Java 14 um `switch` também pode ser uma expressão que produz um valor, com uma
seta depois de cada `case` que executa só aquele caso.** Desde o Java 21 ele também consegue testar o
tipo de um objeto e desmontá-lo. As duas coisas estão no Java 25 e são o jeito de escrever código
novo:

```schooling-example
{
  "language": "java",
  "file": "Fees.java",
  "parts": [
    {
      "code": "public class Fees {\n    static int dailyFine(String kind) {\n        return switch (kind) {\n            case \"book\", \"magazine\" -> 50;\n            case \"dvd\" -> 100;",
      "note": "**Uma expressão `switch` produz um valor**, então pode ser devolvida ou atribuída. Cada caso com seta executa só o seu lado direito: não há queda nem `break`. Um `case` pode listar várias constantes, separadas por vírgulas."
    },
    {
      "code": "            default -> {\n                System.out.println(\"  unknown kind: \" + kind);\n                yield 0;\n            }\n        };\n    }",
      "note": "Um caso que precisa de mais de uma instrução leva um bloco, e **o `yield` dá o valor do bloco**. Um `return` sairia do método inteiro. O `;` depois da chave de fechamento termina a instrução `return`."
    },
    {
      "code": "\n    static String describe(Object o) {\n        return switch (o) {\n            case null -> \"nothing\";",
      "note": "Desde o Java 21 um `switch` aceita qualquer objeto, e **o `case null` trata o `null` diretamente**, em vez de lançar exceção, como fez o da seção 03."
    },
    {
      "code": "            case Integer i when i > 100 -> \"a large number, \" + i;\n            case Integer i -> \"a number, \" + i;\n            case String s -> \"text of length \" + s.length();",
      "note": "**Casamento de padrões** (pattern matching): `case Integer i` combina quando `o` é um `Integer` e o chama de `i`, já com o tipo `Integer`. O `when` acrescenta uma condição, chamada guarda. Os casos são testados de cima para baixo, então o que tem guarda vem primeiro."
    },
    {
      "code": "            default -> \"something else: \" + o.getClass().getSimpleName();\n        };\n    }",
      "note": "Todo o resto, aqui um `Double`. O `getClass().getSimpleName()` dá o nome da classe do objeto."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        System.out.println(dailyFine(\"book\") + \" \" + dailyFine(\"dvd\"));\n        System.out.println(dailyFine(\"map\"));\n        System.out.println(describe(7));\n        System.out.println(describe(250));\n        System.out.println(describe(\"Dom Casmurro\"));\n        System.out.println(describe(null));\n        System.out.println(describe(2.5));\n    }\n}"
    }
  ],
  "output": "50 100\n  unknown kind: map\n0\na number, 7\na large number, 250\ntext of length 12\nnothing\nsomething else: Double\n"
}
```

## O compilador confere que todo valor está coberto

Uma instrução `switch` pode cobrir só alguns valores, e os demais não fazem nada. **Uma expressão
`switch` precisa produzir um valor para toda entrada possível**, senão não teria o que devolver. Para
uma `String` existem infinitas entradas, então sem um `default` o compilador recusa:

```java
// NoDefault.java
public class NoDefault {
    static int dailyFine(String kind) {
        return switch (kind) {
            case "book", "magazine" -> 50;
            case "dvd" -> 100;
        };
    }

    public static void main(String[] args) {
        System.out.println(dailyFine("book"));
    }
}
```

```
ana@vm:~/cond$ javac NoDefault.java
NoDefault.java:4: error: the switch expression does not cover all possible input values
        return switch (kind) {
               ^
1 error
```

Essa verificação se chama **exaustividade**, e ela compensa mais quando o conjunto de valores é
fechado. Para um `enum` com três constantes, cobrir as três basta e nenhum `default` é necessário;
quando alguém acrescenta uma quarta, todo `switch` que a esqueceu para de compilar. A lição 28 mostra
isso num `enum` e a lição 29 numa família selada de records.

## A ordem dos padrões importa

Os casos são testados de cima para baixo, e o primeiro que combina ganha. Um padrão geral acima de um
mais específico tornaria o específico inalcançável, e o compilador recusa isso também:

```java
// Dominance.java
public class Dominance {
    static String describe(Object o) {
        return switch (o) {
            case Integer i -> "a number, " + i;
            case Integer i when i > 100 -> "a large number, " + i;
            default -> "something else";
        };
    }

    public static void main(String[] args) {
        System.out.println(describe(250));
    }
}
```

```
ana@vm:~/cond$ javac Dominance.java
Dominance.java:6: error: this case label is dominated by a preceding case label
            case Integer i when i > 100 -> "a large number, " + i;
                 ^
1 error
```

O `case Integer i` combina com todo `Integer`, então o caso com guarda abaixo dele nunca poderia ser
escolhido. Ele está **dominado** (dominated), na palavra do compilador. Ponha o caso com o `when`
primeiro, como faz o `Fees.java`.
