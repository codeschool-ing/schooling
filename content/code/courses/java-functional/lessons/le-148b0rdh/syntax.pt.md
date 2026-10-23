---
title: As formas que um lambda assume
version: 1
---

**Um lambda é uma lista de parâmetros, uma seta e um corpo.** Todas as outras regras dizem quanto
disso pode ser omitido. Este programa escreve as formas que você vai encontrar, uma por linha, cada
uma guardada numa variável cujo tipo diz o que ela recebe e devolve:

```schooling-example
{
  "language": "java",
  "file": "Shapes.java",
  "parts": [
    {
      "code": "// Shapes.java: the forms a lambda can take\nimport java.util.function.BiFunction;\nimport java.util.function.BinaryOperator;\nimport java.util.function.Function;\nimport java.util.function.Predicate;\n\npublic class Shapes {\n    public static void main(String[] args) {",
      "note": "Os tipos da esquerda vêm todos de `java.util.function`, o assunto da aula 2. Por enquanto, leia cada um como uma descrição: o que entra, o que sai."
    },
    {
      "code": "        Runnable hello = () -> System.out.println(\"no parameters\");",
      "note": "Sem parâmetros: parênteses vazios, que não podem ser omitidos."
    },
    {
      "code": "        Function<String, Integer> length = s -> s.length();",
      "note": "Um parâmetro: os parênteses são opcionais, e o tipo é deduzido de `Function<String, Integer>`."
    },
    {
      "code": "        BinaryOperator<Integer> add = (a, b) -> a + b;",
      "note": "Dois ou mais parâmetros precisam de parênteses. Um corpo de expressão é devolvido sem `return`."
    },
    {
      "code": "        BiFunction<String, Integer, String> repeat = (String s, Integer n) -> s.repeat(n);",
      "note": "Os tipos podem ser escritos, e então precisam ser escritos para todos os parâmetros."
    },
    {
      "code": "        Predicate<String> blank = (var s) -> s.isBlank();",
      "note": "`var` também serve como tipo de parâmetro. Ele existe para que se possa pôr uma anotação num parâmetro sem escrever o tipo."
    },
    {
      "code": "        Function<Integer, String> describe = n -> {\n            if (n < 0) {\n                return \"negative\";\n            }\n            return n % 2 == 0 ? \"even\" : \"odd\";\n        };",
      "note": "Um corpo de bloco é Java comum entre chaves, com `return` onde sai um valor e um ponto e vírgula depois da chave de fechamento, porque o conjunto todo é uma instrução só."
    },
    {
      "code": "\n        hello.run();\n        System.out.println(length.apply(\"lambda\"));\n        System.out.println(add.apply(2, 3));\n        System.out.println(repeat.apply(\"ab\", 3));\n        System.out.println(blank.test(\"   \"));\n        System.out.println(describe.apply(7) + \" \" + describe.apply(-2));\n    }\n}\n",
      "note": "Definir um lambda não executa nada. Cada um roda quando o método da sua interface é chamado: `run`, `apply` ou `test`."
    }
  ],
  "output": "no parameters\n6\n5\nababab\ntrue\nodd negative"
}
```

Nada no programa imprimiu até as chamadas do fim. **Escrever um lambda cria um objeto; chamar o
método da interface executa o corpo**, tantas vezes quantas for chamado. Esse intervalo entre
definir e executar é o que faz a Stream API da aula 6 funcionar, e o motivo de a aula 9 poder rodar o
mesmo lambda em quatro processadores ao mesmo tempo.

## O tipo vem de onde ele está escrito

Um lambda não tem tipo próprio. **Ele assume o tipo do lugar onde está escrito**, que a
especificação chama de **tipo-alvo**: a variável a que é atribuído, o parâmetro como o qual é
passado, o valor que um método devolve. Sem alvo, não há de onde deduzir:

```java
// NoTarget.java: two lambdas with nowhere to take a type from
public class NoTarget {
    public static void main(String[] args) {
        var twice = (Integer x) -> x * 2;
        Object task = () -> System.out.println("hi");
    }
}
```

```
ana@vm:~/fp/lambdas$ javac -d out NoTarget.java
NoTarget.java:4: error: cannot infer type for local variable twice
        var twice = (Integer x) -> x * 2;
            ^
  (lambda expression needs an explicit target-type)
NoTarget.java:5: error: incompatible types: Object is not a functional interface
        Object task = () -> System.out.println("hi");
                      ^
2 errors
```

`var` pede ao compilador que tire o tipo do lado direito, e o lambda pede para tirar o seu do lado
esquerdo: cada um espera pelo outro. `Object` é um tipo, mas não um com um único método a
implementar, então o lambda não tem no que se transformar. Os dois erros dizem isso com as próprias
palavras, e os dois têm o mesmo remédio: **escreva a interface que o lambda deve ser**.

## Curto e longo são o mesmo lambda

| escrito | significa |
|---|---|
| `s -> s.length()` | um parâmetro, tipo deduzido, a expressão devolvida |
| `(s) -> s.length()` | o mesmo, com parênteses opcionais |
| `(String s) -> s.length()` | o mesmo, com o tipo escrito |
| `(String s) -> { return s.length(); }` | o mesmo, como bloco |

Escreva a forma mais curta que continue legível. Um bloco com um único `return` é quase sempre a
forma de expressão com mais ruído, e **um lambda com mais de algumas linhas é um método que ainda
não ganhou nome**: a aula 3 mostra como passar o próprio método, e isso se lê melhor que vinte
linhas dentro de uma lista de argumentos.
