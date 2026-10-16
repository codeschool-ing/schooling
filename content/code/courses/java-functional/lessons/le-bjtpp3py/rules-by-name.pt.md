---
title: Regras escolhidas pelo nome
version: 1
---

**Quando comportamento é valor, um conjunto de comportamentos é um mapa.** O padrão Strategy
clássico dá a cada regra de preço uma classe que implementa uma interface comum, e uma fábrica com um
`switch` para escolher uma. Com lambdas a interface já está no JDK, as classes encolhem para uma
linha cada, e o `switch` vira uma consulta:

```java
// Strategies.java: pricing rules in a map, chosen by name at run time
import java.util.Map;
import java.util.TreeMap;
import java.util.function.UnaryOperator;

public class Strategies {
    static UnaryOperator<Long> percentOff(int percent) {
        return cents -> cents - cents * percent / 100;
    }

    static final Map<String, UnaryOperator<Long>> RULES = new TreeMap<>(Map.of(
            "none", cents -> cents,
            "student", percentOff(15),
            "black-friday", percentOff(40),
            "free-shipping", cents -> cents >= 15000 ? cents : cents + 1500));

    public static void main(String[] args) {
        String name = args[0];
        long price = Long.parseLong(args[1]);
        UnaryOperator<Long> rule = RULES.get(name);
        if (rule == null) {
            System.err.println("no rule called " + name + "; the rules are " + RULES.keySet());
            System.exit(2);
        }
        System.out.println(name + ": " + price + " -> " + rule.apply(price));
    }
}
```

```
ana@vm:~/fp/higher-order$ java Strategies.java student 8990
student: 8990 -> 7642
ana@vm:~/fp/higher-order$ java Strategies.java black-friday 8990
black-friday: 8990 -> 5394
ana@vm:~/fp/higher-order$ java Strategies.java free-shipping 12000
free-shipping: 12000 -> 13500
ana@vm:~/fp/higher-order$ java Strategies.java free-shipping 15000
free-shipping: 15000 -> 15000
ana@vm:~/fp/higher-order$ java Strategies.java studnet 8990; echo $?
no rule called studnet; the rules are [black-friday, free-shipping, none, student]
2
```

Cada regra é uma entrada: um nome e um lambda, ou uma chamada de fábrica que devolve um.
**Acrescentar uma regra é acrescentar uma linha ao mapa**, sem classe nova e sem ramo novo num
`switch`. O `TreeMap` mantém os nomes ordenados, e só está lá para a lista na mensagem de erro ficar
legível.

## Um nome desconhecido é um erro, dito em voz alta

A última execução pediu uma regra que não existe. `RULES.get` devolveu `null`, e o programa **disse
isso, citou as regras que conhece e saiu com status 2**, o número que o `echo $?` imprimiu embaixo.
O atalho tentador é `RULES.getOrDefault(name, cents -> cents)`, que cobra o preço cheio por um erro
de digitação e imprime um número perfeitamente plausível. Ninguém notaria até um cliente notar. Um
valor padrão é certo quando o padrão é o que a pessoa quis dizer, e um nome de regra digitado errado
nunca quer dizer "nenhuma regra".

## Onde o padrão ainda precisa de classes

Um mapa de lambdas serve quando cada estratégia é **uma operação sem estado próprio**. Quando uma
estratégia precisa de vários métodos que andam juntos, de configuração, ou de um nome que apareça
nos logs, uma interface com algumas classes pequenas, ou um `enum` cujas constantes carregam cada
uma um lambda, se lê melhor. O teste é o mesmo da seção 05 da aula 3: se uma regra precisa de um
comentário para dizer o que faz, ela precisa de um nome, e uma classe ou uma constante de enum é um
nome.
