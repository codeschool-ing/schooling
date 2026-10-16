---
title: Criando um Optional
version: 1
---

**`Optional<T>` é um contêiner que guarda um valor do tipo `T` ou nada.** Um método que devolve
`Optional<Edition>` diz na assinatura que pode não achar edição nenhuma, e o compilador obriga quem
chama a lidar com a caixa antes de chegar ao valor dentro dela. `Catalogue.find` devolve um;
`findFirst`, `max` e `reduce`, nas aulas 6 a 8, devolveram um pelo mesmo motivo.

Três métodos de fábrica criam um:

```java
// Making.java: of, ofNullable and empty, and the one that refuses null
import java.util.Optional;

public class Making {
    public static void main(String[] args) {
        Optional<String> some = Optional.of("Machado de Assis");
        Optional<String> none = Optional.empty();
        Optional<String> maybe = Optional.ofNullable(Catalogue.findOrNull("Dom Casmurro").translator());
        System.out.println(some + " " + none + " " + maybe);
        System.out.println(some.isPresent() + " " + none.isEmpty());

        System.out.println(Catalogue.find("Dom Casmurro"));
        System.out.println(Catalogue.find("Moby-Dick"));

        Optional<String> broken = Optional.of(Catalogue.findOrNull("Dom Casmurro").translator());
    }
}
```

```
ana@vm:~/fp/optional$ java Making.java
Optional[Machado de Assis] Optional.empty Optional.empty
true true
Optional[Edition[title=Dom Casmurro, author=Machado de Assis, translator=null, priceCents=3490]]
Optional.empty
Exception in thread "main" java.lang.NullPointerException
	at java.base/java.util.Objects.requireNonNull(Objects.java:220)
	at java.base/java.util.Optional.of(Optional.java:113)
	at Making.main(Making.java:15)
```

| fábrica | dá | use quando |
|---|---|---|
| `Optional.of(valor)` | uma caixa com `valor`; **lança exceção** se `valor` for `null` | você sabe que o valor está lá |
| `Optional.ofNullable(valor)` | uma caixa com `valor`, ou uma caixa vazia se ele for `null` | o valor vem de código que usa `null` para dizer nada |
| `Optional.empty()` | uma caixa vazia | não há nada a devolver |

O `ofNullable` é a ponte do código antigo para o novo: o campo do tradutor ainda guarda `null`, e o
`ofNullable` transformou isso em `Optional.empty`. **O `of` recusa `null` de propósito.** A última
linha o chamou com o mesmo `null`, e ele falhou na hora, na linha 15, dentro de
`Objects.requireNonNull`. É o lugar certo para falhar: quem escreveu `of` estava dizendo "isto nunca é
`null`", e o programa parou no momento em que isso se mostrou falso.

`Catalogue.find("Moby-Dick")` imprimiu `Optional.empty`. Quem chama não aprende nada novo com o
valor, mas aprende tudo com o tipo: nunca houve um jeito de ler o resultado de `find` como uma edição
sem antes decidir o que fazer quando não há nenhuma.
