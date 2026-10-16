---
title: O antipadrão get(), e onde o Optional não cabe
version: 1
---

**O `get()` abre a caixa e devolve o valor, e lança exceção quando a caixa está vazia.** Isso faz dele
o único método que traz de volta exatamente a falha que o `Optional` existia para tirar. Ele tem um
primo educado, o par `isPresent()` e depois `get()`, que é seguro e é verificação de `null` com
roupa nova:

```java
// Antipattern.java: get, the isPresent-get pair, and the version that needs neither
import java.util.Optional;

public class Antipattern {
    public static void main(String[] args) {
        Optional<Catalogue.Edition> found = Catalogue.find("Dom Casmurro");
        if (found.isPresent()) {
            System.out.println("checked: " + found.get().author());
        }
        System.out.println("chained: " + found.map(Catalogue.Edition::author).orElse("nobody"));

        Optional<Catalogue.Edition> missing = Catalogue.find("Moby-Dick");
        System.out.println(missing.get().author());
    }
}
```

```
ana@vm:~/fp/optional$ java Antipattern.java
checked: Machado de Assis
chained: Machado de Assis
Exception in thread "main" java.util.NoSuchElementException: No value present
	at java.base/java.util.Optional.get(Optional.java:143)
	at Antipattern.main(Antipattern.java:13)
```

A versão com verificação funciona, e são cinco linhas fazendo o que a versão encadeada faz numa só.
**O `get()` sem verificação falhou com `NoSuchElementException: No value present`**, na linha 13, o
que diz menos que a `NullPointerException` que ele substituiu: nem qual valor faltava. A própria
documentação do método recomenda `orElseThrow()` no lugar dele, que faz a mesma coisa e diz no nome
que pode lançar. Quando uma caixa vazia é mesmo um bug, escreva isso:
`find(title).orElseThrow(() -> new IllegalStateException("no edition called " + title))` falha com
uma mensagem com a qual alguém pode agir.

## Onde o `Optional` cabe

O `Optional` foi projetado para um trabalho: **o tipo de retorno de um método, quando o método pode
não ter resultado**. Ele serve mal em quase todo o resto:

| uso | por que não | em vez disso |
|---|---|---|
| um campo, `Optional<String> translator` | não é serializável, acrescenta um objeto por campo, e o próprio campo ainda pode ser `null` | um campo que aceita `null`, e um acessor que devolve `Optional.ofNullable(campo)` |
| um parâmetro, `void ship(Optional<Address> a)` | todo quem chama precisa embrulhar, e ainda pode passar `null` | uma sobrecarga sem o parâmetro, ou um parâmetro que aceita `null`, documentado como tal |
| um elemento de coleção, `List<Optional<Book>>` | uma lista pode simplesmente deixar de fora os que faltam | tire-os com `flatMap(Optional::stream)` |
| `Optional<List<Book>>` | "nenhum livro" já tem um valor: a lista vazia | devolva a lista vazia |

E uma regra sem exceções: **um método que devolve `Optional` nunca devolve `null`**. Quem chama e
recebe `null` onde um `Optional` foi prometido leva a `NullPointerException` que o tipo devia
descartar, do único lugar onde ninguém pensaria em conferir.
