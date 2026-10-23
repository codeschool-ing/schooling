---
title: Random é uma fórmula
version: 1
---

**O `java.util.Random` não produz acaso; produz uma sequência calculada a partir de um número inicial, a
semente.** Cada número vem do anterior pela mesma conta, então a mesma semente dá sempre a mesma sequência:

```java
// Dice.java: java.util.Random is a formula, and the same seed gives the same numbers
import java.util.Random;
import java.util.stream.Collectors;

public class Dice {
    public static void main(String[] args) {
        System.out.println("seed 2026: " + rolls(new Random(2026)));
        System.out.println("seed 2026: " + rolls(new Random(2026)));
        System.out.println("no seed:   " + rolls(new Random()));
    }

    static String rolls(Random random) {
        return random.ints(10, 1, 7).mapToObj(String::valueOf).collect(Collectors.joining(" "));
    }
}
```

```
ana@vm:~/fp/secrets$ java Dice.java
seed 2026: 6 5 2 1 4 5 6 5 5 1
seed 2026: 6 5 2 1 4 5 6 5 5 1
no seed:   5 3 4 4 5 2 1 2 5 1
```

## Onde isso ajuda e onde não

As duas execuções com semente rolaram os mesmos dez dados, e **vão rolá-los de novo em toda máquina, a cada
execução**. É exatamente o que precisam uma simulação, um teste ou um jogo que quer repetir uma fase. Sem
semente, o `Random` escolheu uma a partir do relógio e de um contador, e os resultados foram outros, mas só
porque o ponto de partida foi; a conta depois dele é a mesma.

Essa conta é o problema para qualquer coisa secreta. O `Random` guarda 48 bits de estado, e cada número que
ele devolve entrega parte desse estado, então **quem vê alguns dos seus resultados consegue calcular o
resto, os de antes e os de depois**. Um link de troca de senha, um identificador de sessão ou um código de
cupom feito com `Random` é um código cujos vizinhos podem ser calculados por qualquer um que tenha recebido
um.

| classe | números vindos de | usar para |
|---|---|---|
| `Random` | uma fórmula e uma semente | simulações, testes, jogos que repetem |
| `ThreadLocalRandom` | o mesmo tipo de fórmula, uma por thread | o mesmo, a partir de muitas threads ao mesmo tempo |
| `SecureRandom` | a fonte de aleatoriedade do sistema operacional | tudo o que não pode ser adivinhado |

O `ThreadLocalRandom.current()` é o `Random` feito para as aulas 11 a 18: cada thread tem o seu, então as
threads não esperam umas pelas outras. Ele é igualmente previsível. **Nenhum dos dois é fonte de segredos**;
a próxima seção é.
