---
title: Quando um lambda se lê melhor
version: 1
---

**Uma referência é melhor quando nomeia o que acontece; um lambda é melhor quando precisa mostrar o
que acontece.** `String::toUpperCase` diz tudo no nome. `s -> s.substring(2)` não vira referência de
jeito nenhum, porque passa um valor que o ponto de chamada escolheu, e uma referência só repassa os
argumentos que recebe.

## O compilador não consegue escolher

Algumas referências são recusadas porque se encaixam de mais de um jeito:

```java
// Ambiguous.java: a reference that matches two methods
import java.util.function.Function;

public class Ambiguous {
    public static void main(String[] args) {
        Function<Integer, String> show = Integer::toString;
        System.out.println(show.apply(7));
    }
}
```

```
ana@vm:~/fp/references$ javac -d out Ambiguous.java
Ambiguous.java:6: error: incompatible types: invalid method reference
        Function<Integer, String> show = Integer::toString;
                                         ^
    reference to toString is ambiguous
      both method toString(int) in Integer and method toString() in Integer match
1 error
```

`Integer` tem um `toString(int)` estático e um `toString()` de instância. Lida como estática, a
referência passa o argumento a `toString(int)`; lida como não ligada, chama `toString()` no
argumento. As duas servem para `Function<Integer, String>`, e **o compilador se recusa a adivinhar**.
O lambda diz qual: `n -> Integer.toString(n)`, ou `n -> n.toString()`. Uma referência que precisa de
um comentário para explicar qual método quer dizer é um lambda esperando para ser escrito.

## Um guia curto

| o lambda | como referência? |
|---|---|
| `s -> s.length()` | `String::length`, mais claro |
| `x -> Math.abs(x)` | `Math::abs`, mais claro |
| `() -> new HashMap<>()` | `HashMap::new`, mais claro |
| `s -> s.substring(2)` | nenhuma: o `2` não é um argumento |
| `b -> b.author().name()` | nenhuma: duas chamadas seguidas |
| `n -> n % 2 == 0` | nenhuma: não é chamada de método |
| `x -> helper.check(x, LIMIT)` | nenhuma, a não ser que `check` mude para receber um argumento |

**Quando a lógica é longa o bastante para precisar de nome, dê um nome a ela**: escreva um método
privado e passe uma referência a ele, `this::isWorthShipping` ou `Rules::isWorthShipping`. É o passo
que a seção 05 da aula 1 prometeu, e é o que transforma um lambda de vinte linhas numa lista de
argumentos em uma linha legível com um método que você pode testar sozinho.
