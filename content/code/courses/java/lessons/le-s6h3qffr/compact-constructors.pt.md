---
title: O construtor compacto, e até onde vai a imutabilidade
version: 1
---

Um record aceita o que lhe derem. `new Isbn("banana")` compilaria e rodaria, e o valor ruim viajaria
pelo programa até algo bem longe tropeçar nele. **O lugar de recusar dados ruins é o construtor**, e
um record deixa você acrescentar código ao que o compilador escreve, numa forma curta chamada
**construtor compacto**:

```java
// Checked.java
record Isbn(String value) {
    Isbn {
        value = value.replace("-", "").strip();
        if (value.length() != 13) {
            throw new IllegalArgumentException("an ISBN-13 has 13 digits, not " + value.length());
        }
    }
}

public class Checked {
    public static void main(String[] args) {
        System.out.println(new Isbn(" 978-85-359-0277-1 "));
        System.out.println(new Isbn("978-85-359"));
    }
}
```

O construtor compacto é o nome do record e um bloco, sem lista de parâmetros, porque os parâmetros
são os componentes. **Ele roda antes de os campos serem atribuídos**, então pode fazer duas coisas.
Pode **normalizar**: `value = value.replace("-", "").strip()` reatribui o *parâmetro*, e o campo
recebe o valor arrumado quando o bloco termina. E pode **validar**, lançando uma exceção antes de um
record ruim chegar a existir. Você nunca escreve `this.value = value`; o compilador acrescenta isso no
fim.

```
ana@vm:~/records/compact$ javac Checked.java && java Checked
Isbn[value=9788535902771]
Exception in thread "main" java.lang.IllegalArgumentException: an ISBN-13 has 13 digits, not 8
	at Isbn.<init>(Checked.java:6)
	at Checked.main(Checked.java:14)
```

O primeiro ISBN chegou com hífens e espaços e foi guardado como treze dígitos. O segundo foi recusado
no construtor, linha 6, e nenhum `Isbn` com oito dígitos chegou a ser criado. **Todo `Isbn` do
programa agora é válido por construção**: um método que recebe um não precisa conferi-lo de novo, e
esse é o motivo de pôr a conferência no tipo, e não em cada método que o usa.

## Imutável vai um nível só

A seção 02 disse que os campos de um record não podem ser reatribuídos. **Isso não diz nada sobre os
objetos para os quais os campos apontam.** Um componente do tipo `List<String>` é uma referência final
a uma lista, e a lição 16 mostrou que uma referência final a uma lista ainda deixa qualquer um mudar a
lista. Duas estantes, uma descuidada e uma cuidadosa:

```java
// Shelves.java
import java.util.ArrayList;
import java.util.List;

record Shelf(String name, List<String> titles) {
}

record SafeShelf(String name, List<String> titles) {
    SafeShelf {
        titles = List.copyOf(titles);
    }
}

public class Shelves {
    public static void main(String[] args) {
        List<String> titles = new ArrayList<>(List.of("Dom Casmurro"));
        Shelf shelf = new Shelf("A", titles);
        SafeShelf safe = new SafeShelf("A", titles);

        titles.add("Iracema");
        System.out.println(shelf);
        System.out.println(safe);

        safe.titles().add("O Cortiço");
    }
}
```

```
ana@vm:~/records/compact$ javac Shelves.java && java Shelves
Shelf[name=A, titles=[Dom Casmurro, Iracema]]
SafeShelf[name=A, titles=[Dom Casmurro]]
Exception in thread "main" java.lang.UnsupportedOperationException
	at java.base/java.util.ImmutableCollections.uoe(ImmutableCollections.java:159)
	at java.base/java.util.ImmutableCollections$AbstractImmutableCollection.add(ImmutableCollections.java:164)
	at Shelves.main(Shelves.java:24)
```

**O `Shelf` mudou depois de construído.** O construtor dele guardou a própria lista de quem chamou,
então o `titles.add("Iracema")` do `main` chegou dentro do record, e um valor que duas partes do
programa achavam compartilhar virou outra coisa em silêncio. O `SafeShelf` copiou a lista no
construtor compacto com `List.copyOf`, que faz uma cópia não modificável. O `add` posterior de quem
chamou não chegou nela, e quando o `main` tentou acrescentar pelo acessor, a cópia recusou com
`UnsupportedOperationException` (a lição 31 reencontra essa exceção).

**Um record é tão imutável quanto os seus componentes.** Strings, números, outros records e enums já
são imutáveis. Uma lista, um mapa, um array ou um objeto comum mutável precisam de uma cópia na
entrada, e o construtor compacto é onde ela fica.
