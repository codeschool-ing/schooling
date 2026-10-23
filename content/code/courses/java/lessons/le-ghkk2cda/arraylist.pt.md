---
title: Uma lista que cresce
version: 1
---

Os arrays da lição 9 ficam fixos no tamanho com que são criados: `new String[3]` guarda três títulos,
hoje e para sempre. A maioria das coleções de um programa não sabe o tamanho de antemão. Os
empréstimos de um membro, os resultados de uma busca, as linhas de um arquivo: cada um cresce enquanto
o programa roda. **O `ArrayList` é uma lista que cresce conforme você acrescenta coisas**, e é a
coleção que a maior parte do código Java usa primeiro.

Ele mora em `java.util` e é usado pela interface `List`, que a lição 32 compara com os outros tipos.
Em `~/lists`:

```java
// Lists.java
import java.util.ArrayList;
import java.util.List;

public class Lists {
    public static void main(String[] args) {
        List<String> titles = new ArrayList<>();
        titles.add("Dom Casmurro");
        titles.add("Iracema");
        titles.add(0, "O Cortiço");
        System.out.println(titles + ", size " + titles.size());
        System.out.println(titles.get(1));

        titles.set(1, "Memórias Póstumas");
        titles.remove("Iracema");
        System.out.println(titles + ", contains Iracema: " + titles.contains("Iracema"));

        List<Integer> pages = new ArrayList<>(List.of(10, 20, 30, 1));
        pages.remove(1);
        System.out.println(pages);
        pages.remove(Integer.valueOf(1));
        System.out.println(pages);

        System.out.println(titles.get(5));
    }
}
```

```
ana@vm:~/lists$ javac Lists.java && java Lists
[O Cortiço, Dom Casmurro, Iracema], size 3
Dom Casmurro
[O Cortiço, Memórias Póstumas], contains Iracema: false
[10, 30, 1]
[10, 30]
Exception in thread "main" java.lang.IndexOutOfBoundsException: Index 5 out of bounds for length 2
	at java.base/jdk.internal.util.Preconditions.outOfBounds(Preconditions.java:100)
	at java.base/jdk.internal.util.Preconditions.outOfBoundsCheckIndex(Preconditions.java:106)
	at java.base/jdk.internal.util.Preconditions.checkIndex(Preconditions.java:302)
	at java.base/java.util.Objects.checkIndex(Objects.java:365)
	at java.base/java.util.ArrayList.get(ArrayList.java:428)
	at Lists.main(Lists.java:24)
```

Os métodos do dia a dia, como a saída os mostra:

| método | o que fez aqui |
|---|---|
| `add(x)` | acrescentou no fim |
| `add(0, x)` | inseriu *O Cortiço* no índice 0, empurrando os outros |
| `size()` | 3: quantos elementos há, onde um array tem `length` |
| `get(i)` | o elemento no índice `i`, contado a partir de 0 como num array |
| `set(i, x)` | substituiu o elemento em `i` |
| `remove(x)`, `contains(x)` | acharam o elemento com `equals` (lição 24), e o removeram ou disseram que estava lá |

Uma lista se imprime de forma legível, `[O Cortiço, Dom Casmurro, Iracema]`, onde um array precisa do
`Arrays.toString` (lição 9). **E um índice ruim continua sendo exceção**: `get(5)` numa lista de dois
encerrou o programa com `IndexOutOfBoundsException`, citando o índice e o comprimento, a mesma recusa
que um array dá.

## A armadilha numa lista de números

`List<Integer> pages` guardava `[10, 20, 30, 1]`, e `pages.remove(1)` removeu o **20**, não o 1. A
`List` tem dois métodos chamados `remove`: `remove(int index)` e `remove(Object o)`. Diante do literal
`1`, um `int`, o compilador escolhe aquele cujo parâmetro já é `int`, o índice, sem embrulhá-lo antes.
A lição 24 chamou essa regra de sobrecarga, e aqui ela morde: o código se lê como "remova o número 1" e
quer dizer "remova o que estiver no índice 1".

**`pages.remove(Integer.valueOf(1))` passa um objeto**, então o compilador escolhe o `remove(Object)`,
e a segunda linha mostra o 1 sumindo. Com uma `List<String>` a questão nem aparece, porque uma string
não pode ser confundida com um índice. Com uma lista de `Integer`, escreva qual dos dois você quer.

## Listas guardam objetos

`List<int>` não compila; o argumento de tipo precisa ser uma classe. `List<Integer>` guarda objetos
`Integer`, e `pages.add(5)` embrulha o 5 num deles, como a lição 4 descreveu. Para alguns milhares de
números isso não custa nada que valha medir. Para milhões custa memória, porque cada número vira um
objeto com cabeçalho próprio, enquanto um `int[]` guarda quatro bytes por número, lado a lado. A seção
04 volta a isso na hora de escolher.
