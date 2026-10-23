---
title: Quando nenhuma serve
version: 1
---

**Nenhuma das 43 interfaces pode lançar uma exceção checada**, e esse é o motivo mais comum para
escrever a sua. Ler um arquivo é o caso típico. `Files.readString` declara `throws IOException`, e
`Function.apply` não declara nada:

```java
// Checked.java: a Function whose body can throw IOException
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.function.Function;

public class Checked {
    public static void main(String[] args) {
        Function<Path, String> read = p -> Files.readString(p);
        System.out.println(read.apply(Path.of("notes.txt")));
    }
}
```

```
ana@vm:~/fp/interfaces$ javac -d out Checked.java
Checked.java:8: error: unreported exception IOException; must be caught or declared to be thrown
        Function<Path, String> read = p -> Files.readString(p);
                                                           ^
1 error
```

**O corpo de um lambda é o método que ele implementa**, então obedece à cláusula `throws` desse
método, e `apply` não tem nenhuma. A exceção checada não tem para onde ir: não pode escapar de
`apply`, e a cláusula `throws` do próprio `main` não ajudaria, porque o corpo não roda dentro do
`main`. Ele roda quando alguém chama `apply`, o que pode ser em qualquer lugar.

## Uma interface que diz que pode falhar

O conserto é uma interface cujo único método declara a exceção:

```schooling-example
{
  "language": "java",
  "file": "OwnInterface.java",
  "parts": [
    {
      "code": "// OwnInterface.java: a function that is allowed to fail with IOException\nimport java.io.IOException;\nimport java.io.UncheckedIOException;\nimport java.nio.file.Files;\nimport java.nio.file.Path;\nimport java.util.function.Function;\n\n@FunctionalInterface\ninterface IOFunction<T, R> {\n    R apply(T t) throws IOException;",
      "note": "A mesma forma de `Function<T, R>`, com uma diferença: `apply` pode lançar `IOException`, então um lambda cujo corpo a lança agora compila."
    },
    {
      "code": "\n    static <T, R> Function<T, R> unchecked(IOFunction<T, R> f) {\n        return t -> {\n            try {\n                return f.apply(t);\n            } catch (IOException e) {\n                throw new UncheckedIOException(e);\n            }\n        };\n    }\n}",
      "note": "Uma ponte de volta para a `Function` padrão, para uma API que só aceita essa. A exceção checada é embrulhada numa `UncheckedIOException`, que guarda a original como causa em vez de perdê-la."
    },
    {
      "code": "\npublic class OwnInterface {\n    public static void main(String[] args) throws IOException {\n        IOFunction<Path, String> read = p -> Files.readString(p);\n        System.out.print(read.apply(Path.of(\"notes.txt\")));",
      "note": "Chamada diretamente, a exceção continua checada, e o `main` a declara. Esta é a versão honesta: o compilador ainda obriga alguém a decidir o que um arquivo ausente significa."
    },
    {
      "code": "\n        Function<Path, String> lenient = IOFunction.unchecked(read);\n        try {\n            lenient.apply(Path.of(\"missing.txt\"));\n        } catch (UncheckedIOException e) {\n            System.out.println(\"failed: \" + e.getCause());\n        }\n    }\n}\n",
      "note": "Pela ponte, a falha chega como exceção não checada e é capturada aqui. A mensagem veio da `IOException` original, guardada como causa."
    }
  ]
}
```

Crie primeiro o arquivo que ele lê, depois rode:

```
ana@vm:~/fp/interfaces$ printf 'Lumen opens at nine on weekdays.\n' > notes.txt
ana@vm:~/fp/interfaces$ java OwnInterface.java
Lumen opens at nine on weekdays.
failed: java.nio.file.NoSuchFileException: missing.txt
```

**Embrulhar não é esconder.** A segunda chamada falhou, e o programa disse isso, com o nome do
arquivo e a exceção que o JDK lançou. Errado seria uma ponte que capturasse a `IOException` e
devolvesse `null` ou uma string vazia, de modo que um arquivo ausente fosse lido como um arquivo
vazio; a aula 10 mostra o que o `null` custa mais adiante.

## Quando escrever uma

| situação | use |
|---|---|
| a forma está no `java.util.function` e nada lança exceção | a interface padrão |
| o corpo lança uma exceção checada que você quer que quem chama trate | a sua, com `throws` |
| a forma serve, mas um nome diria mais, como o `PriceRule` disse | a sua, com `@FunctionalInterface` |
| mais de duas entradas | um record que as agrupe, ou uma interface sua |

Um nome não é enfeite. `PriceRule` numa assinatura de método diz a quem lê para que serve o lambda;
`Function<Long, Long>` só diz os tipos dele.
