---
title: O problema do null
version: 1
---

**Um método que pode não achar nada precisa dizer isso de algum jeito, e durante a maior parte da
história do Java ele disse devolvendo `null`.** Nada na assinatura do método avisava quem chamava.
`Edition findOrNull(String title)` e um método que nunca devolve `null` parecem exatamente iguais,
então quem chama ou confere todo resultado, o que ninguém faz, ou descobre em tempo de execução, em
algum ponto mais adiante.

Esta aula trabalha com um pequeno catálogo de edições, algumas delas traduções. Salve-o em
`~/fp/optional`:

```java
// Catalogue.java: four editions, two of them translations, and two ways to look one up
import java.util.List;
import java.util.Optional;

public class Catalogue {
    public record Edition(String title, String author, String translator, long priceCents) {}

    static final List<Edition> EDITIONS = List.of(
            new Edition("Dom Casmurro", "Machado de Assis", null, 3490),
            new Edition("The Posthumous Memoirs of Brás Cubas", "Machado de Assis",
                    "Margaret Jull Costa and Robin Patterson", 5290),
            new Edition("Grande Sertão: Veredas", "João Guimarães Rosa", null, 7990),
            new Edition("The Devil to Pay in the Backlands", "João Guimarães Rosa",
                    "James L. Taylor and Harriet de Onís", 6490));

    static Edition findOrNull(String title) {
        for (Edition e : EDITIONS) {
            if (e.title().equals(title)) {
                return e;
            }
        }
        return null;
    }

    static Optional<Edition> find(String title) {
        return EDITIONS.stream().filter(e -> e.title().equals(title)).findFirst();
    }
}
```

`translator` é `null` nas duas edições no português original, e esse é o valor honesto do campo: não
há tradutor. Agora, alguém que chama e esquece:

```java
// NullTrouble.java: a null that travels before it fails
public class NullTrouble {
    public static void main(String[] args) {
        Catalogue.Edition edition = Catalogue.findOrNull("Dom Casmurro");
        String translator = edition.translator();
        System.out.println("translated by " + translator.toUpperCase());
    }
}
```

```
ana@vm:~/fp/optional$ java NullTrouble.java
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "String.toUpperCase()" because "<local2>" is null
	at NullTrouble.main(NullTrouble.java:6)
```

## Onde falhou, e onde estava o erro

O programa falhou na linha 6, ao chamar `toUpperCase()`. O erro foi a suposição, duas linhas antes,
de que toda edição tem tradutor. **Um `null` falha onde é usado, não de onde veio**, e em código real
esses dois pontos podem estar a uma dúzia de métodos e dois módulos de distância.

A mensagem é melhor do que era: desde o Java 15 a JVM diz por padrão qual expressão era `null`, e não
só a linha. Aqui ela diz `"<local2>"`, a variável no slot 2 do quadro do método, porque o modo de
arquivo-fonte compila sem a tabela de nomes locais. Compilada com `javac -g`, que a mantém, a mesma
falha dá o nome da variável:

```
ana@vm:~/fp/optional$ javac -g -d out Catalogue.java NullTrouble.java
ana@vm:~/fp/optional$ java -cp out NullTrouble
Exception in thread "main" java.lang.NullPointerException: Cannot invoke "String.toUpperCase()" because "translator" is null
	at NullTrouble.main(NullTrouble.java:6)
```

O Maven compila com essa tabela por padrão, então num projeto a mensagem sai como a segunda. De
qualquer jeito, continua sendo uma falha em tempo de execução, descoberta por quem passou por ali
primeiro.

A mesma armadilha espera atrás de `findOrNull`: peça um título que o catálogo não tem, e o próprio
`edition` é `null`, e a falha sobe uma linha. Nenhum dos dois tipos de retorno disse que nada era uma
resposta possível. A próxima seção é o tipo que diz.
