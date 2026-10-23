---
title: Seis crenças, seis experimentos
version: 1
---

O mal-entendido raramente se apresenta como teoria. Ele aparece como um método que devia mudar algo e
não mudou, ou um que não devia e mudou. **Cada um dos seis experimentos abaixo testa uma crença que
alguém tem**, e cada resultado decorre da frase da seção 03: tudo é passado por valor, e para um
objeto o valor é uma referência. Em `~/byvalue/myths`:

```java
// Myths.java
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class Myths {
    static void shout(String s) {
        s = s.toUpperCase();
    }

    static void increment(Integer n) {
        n++;
    }

    static void swap(String a, String b) {
        String t = a;
        a = b;
        b = t;
    }

    static void zero(int[] numbers) {
        numbers[0] = 0;
    }

    static void forget(List<String> list) {
        list = new ArrayList<>();
    }

    static void empty(List<String> list) {
        list.clear();
    }

    public static void main(String[] args) {
        String name = "ana";
        shout(name);
        System.out.println("1 " + name);

        Integer count = 5;
        increment(count);
        System.out.println("2 " + count);

        String first = "A";
        String second = "B";
        swap(first, second);
        System.out.println("3 " + first + second);

        int[] numbers = {7, 8, 9};
        zero(numbers);
        System.out.println("4 " + Arrays.toString(numbers));

        List<String> titles = new ArrayList<>(List.of("Dom Casmurro"));
        forget(titles);
        System.out.println("5 " + titles);
        empty(titles);
        System.out.println("6 " + titles);
    }
}
```

```
ana@vm:~/byvalue/myths$ javac Myths.java && java Myths
1 ana
2 5
3 AB
4 [0, 8, 9]
5 [Dom Casmurro]
6 []
```

Linha por linha, com a crença que cada uma testa:

| linha | a crença | o que aconteceu, e por quê |
|---|---|---|
| `1 ana` | "uma String é um objeto, então o `shout` a muda" | o `toUpperCase` devolve uma string **nova** (lição 7), e o `s = …` aponta a cópia do `shout` para ela. A string de quem chamou nunca mudou, porque nenhuma string muda |
| `2 5` | "o `Integer` é um objeto, então o `n++` chega a quem chamou" | o `Integer` também é imutável. O `n++` desembrulha, soma e embrulha um `Integer` **novo**, e depois reatribui o `n`, que é a cópia do `increment` |
| `3 AB` | "objetos são passados por referência, então trocar dois de lugar funciona" | o teste decisivo. Por referência, `first` e `second` teriam trocado. O `swap` trocou as suas duas cópias |
| `4 [0, 8, 9]` | "um array é copiado quando é passado" | um array é um objeto, e só a referência foi copiada. O `numbers[0] = 0` escreveu no único array que as duas setas alcançam |
| `5 [Dom Casmurro]` | "o `forget` esvazia a lista de quem chamou" | o `list = new ArrayList<>()` apontou de novo a cópia, como o `replace` da seção 03 |
| `6 []` | "um método não consegue mudar a lista de quem chamou" | o `empty` chamou um método **no objeto**, pela cópia da seta, e o objeto mudou |

**As linhas 1, 2, 3 e 5 são atribuições a um parâmetro, e nenhuma chegou a quem chamou. As linhas 4 e
6 passaram pela referência para mudar o objeto, e as duas conseguiram.** É só isso: atribuir a um
parâmetro muda uma cópia; chamar um método nele, ou escrever num campo ou num elemento dele, muda o
objeto para o qual as duas cópias apontam.

## Por que strings e wrappers parecem exceções

`String` e `Integer` parecem quebrar a regra, no sentido contrário: são objetos, e mesmo assim nenhum
método parece conseguir mudá-los. A regra é a mesma; o que muda é a classe. **Eles são imutáveis, então
não existe método que os mude**, e o único jeito de ter uma string diferente é uma string nova. Um
método que recebe uma só consegue apontar de novo a própria cópia, que quem chamou nunca vê. Um
`StringBuilder` é mutável, e a seção 05 tem um método que muda um pelo parâmetro.

## Por que o nome importa

"O Java passa objetos por referência" não é uma simplificação inofensiva. Linguagens que passam por
referência de verdade têm sintaxe para isso, `ref` no C# e `&` no C++, e nelas um método `swap`
funciona. Um programador que acredita que o Java faz o mesmo escreve o método `forget` acima
esperando que ele limpe a lista de quem chamou, e ganha a linha 5. **O Java não tem sintaxe de
passagem por referência porque não tem passagem por referência.** Quando um método precisa dar algo
novo a quem chamou, ele o devolve, e essa é a seção 05.
