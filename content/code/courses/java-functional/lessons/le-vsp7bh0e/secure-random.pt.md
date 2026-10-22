---
title: SecureRandom
version: 1
---

**O `SecureRandom` é uma fonte de números que não podem ser previstos a partir dos anteriores, semeada pela
coleção de eventos imprevisíveis do próprio sistema operacional.** É a classe para todo segredo que um
programa gera: tokens, chaves, salts, os IVs da aula 25. O uso dele é o mesmo do `Random`, e aquilo para que
ele serve é outro:

```java
// Tokens.java: secrets made with SecureRandom, in the forms a program hands out
import java.security.SecureRandom;
import java.util.Base64;
import java.util.stream.Stream;

public class Tokens {
    static final SecureRandom RANDOM = new SecureRandom();

    public static void main(String[] args) {
        System.out.println("algorithm: " + RANDOM.getAlgorithm());

        String token = token();
        System.out.println("token:     " + token + " (" + token.length() + " characters)");
        System.out.println("code:      " + String.format("%06d", RANDOM.nextInt(1_000_000)));

        long distinct = Stream.generate(Tokens::token).limit(100_000).distinct().count();
        System.out.println("100,000 tokens, distinct: " + distinct);
    }

    static String token() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
```

```
ana@vm:~/fp/secrets$ java Tokens.java
algorithm: NativePRNG
token:     FdD5JXpnQFc97YDrzPhyb3AfxzpOCZlgCrdls2-psCI (43 characters)
code:      904090
100,000 tokens, distinct: 100000
```

## Um token, um código, e cem mil deles

No Linux o algoritmo padrão é o `NativePRNG`, que lê do dispositivo aleatório do kernel. **32 bytes
aleatórios são 256 bits**, mais do que qualquer um consegue adivinhar, e o Base64 na forma segura para URL,
sem padding, os escreve como 43 caracteres que cabem num link sem escape. Cem mil tokens saíram sem nenhuma
repetição, e esse é o resultado esperado: a chance de dois tokens de 256 bits serem iguais é pequena demais
para escrever.

O código de seis dígitos é a outra forma comum, e só tem um milhão de valores. Isso serve para um código
mandado por mensagem que expira em minutos e permite poucas tentativas, e é errado para todo o resto: **a
força de um segredo aleatório é o número de valores que ele poderia ter tido**, e um código curto toma
emprestada a sua segurança dos limites em volta dele.

Três hábitos mantêm o `SecureRandom` funcionando como deve. Faça um e compartilhe; ele é thread-safe, e o
campo acima é usado por toda chamada. Não lhe dê semente: um `setSeed` com valor fixo, em algumas
implementações, o deixa tão previsível quanto o `Random`. E não use o `SecureRandom.getInstanceStrong()` num
servidor sem ler o que ele faz, porque em alguns sistemas ele pode bloquear, esperando o sistema operacional
juntar mais aleatoriedade, no momento em que um usuário espera uma página.
