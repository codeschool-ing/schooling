---
title: Escolhendo, e duas listas que recusam
version: 1
---

Tanto um array quanto um `ArrayList` são espaços numerados na memória, então a escolha não é sobre
velocidade de leitura: `get(i)` e `array[i]` vão direto a um espaço. **É sobre o tamanho ser conhecido
e fixo, e sobre os elementos serem primitivos.**

| use | quando |
|---|---|
| um array, `int[]`, `double[]` | o tamanho é fixado na criação e os elementos são primitivos: os doze meses de um ano, os pixels de uma imagem, um milhão de leituras de um sensor |
| um `ArrayList` | todo o resto: o tamanho muda, ou não é conhecido de antemão, ou os elementos são objetos que outro código vai passar adiante como `List` |

O caso dos primitivos importa por causa do boxing da seção 02. Um `int[]` com um milhão de leituras é
um objeto com quatro milhões de bytes de números. Uma `List<Integer>` com as mesmas leituras é uma
lista com um milhão de referências para um milhão de objetos `Integer`, cada um com cabeçalho próprio.
Código que movimenta muitos números os guarda em arrays.

Todo o resto puxa para o outro lado. **Os métodos da biblioteca padrão e da maior parte do código que
você vai chamar recebem e devolvem `List`, não arrays**, uma lista pode crescer, e ela se imprime. A
lição 32 compara o `ArrayList` com os outros tipos de `List`, `Set` e `Map`.

## Duas listas com cara de comuns

Dois métodos montam uma `List` rapidinho, e nenhum dos dois monta um `ArrayList` que você possa fazer
crescer. Em `~/lists/views`:

```java
// Views.java
import java.util.Arrays;
import java.util.List;

public class Views {
    public static void main(String[] args) {
        String[] shelf = {"Dom Casmurro", "Iracema"};
        List<String> view = Arrays.asList(shelf);
        view.set(0, "O Cortiço");
        System.out.println(Arrays.toString(shelf));

        List<String> fixed = List.of("Dom Casmurro", "Iracema");
        try {
            fixed.set(0, "O Cortiço");
        } catch (UnsupportedOperationException e) {
            System.out.println("List.of refused set: " + e);
        }

        view.add("Memórias Póstumas");
    }
}
```

```
ana@vm:~/lists/views$ javac Views.java && java Views
[O Cortiço, Iracema]
List.of refused set: java.lang.UnsupportedOperationException
Exception in thread "main" java.lang.UnsupportedOperationException
	at java.base/java.util.AbstractList.add(AbstractList.java:155)
	at java.base/java.util.AbstractList.add(AbstractList.java:113)
	at Views.main(Views.java:19)
```

**O `Arrays.asList` não copia o array; ele o embrulha.** O `view.set(0, …)` escreveu direto em
`shelf`, e o array imprimiu *O Cortiço* embora ninguém tenha mexido nele diretamente. A lista é uma
visão do array, então pode mudar elementos e nunca pode mudar de tamanho: o `view.add` falhou na
última linha com `UnsupportedOperationException`, porque um array não cresce.

**O `List.of` monta uma lista que não pode ser mudada de jeito nenhum.** Nem o tamanho, nem os
elementos: o `set` foi recusado, como o `add` seria. É o que o `List.copyOf` da lição 29 também
devolve, e é a coisa certa a entregar quando quem chama deve ler e não escrever.

As duas parecem uma `List` qualquer, e o tipo não diz quais métodos vão funcionar. Essa é uma fraqueza
da interface `List`, que tem métodos para mudar uma lista quer aquela lista permita, quer não. **Quando
um método precisa de uma lista na qual possa acrescentar, ele faz uma**: `new
ArrayList<>(List.of(...))`, como o `pages` da seção 02 fez, dá uma lista comum que cresce com aqueles
elementos dentro.
