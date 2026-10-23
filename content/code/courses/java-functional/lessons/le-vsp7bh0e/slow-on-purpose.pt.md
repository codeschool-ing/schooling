---
title: Lento de propósito
version: 1
---

**Um servidor tem de conseguir conferir uma senha e não pode conseguir lê-la.** Então ele guarda algo
calculado a partir da senha, e quando alguém entra calcula a mesma coisa a partir do que foi digitado e
compara. Se o banco vazar, o atacante tem os valores guardados e nenhuma senha, e precisa adivinhar: pegar
uma senha provável, calcular, comparar, repetir. **A única coisa que o servidor controla é quanto custa cada
palpite**:

```java
// Cost.java: how many password guesses a second SHA-256 allows, and how many PBKDF2 allows
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

public class Cost {
    public static void main(String[] args) throws GeneralSecurityException {
        MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
        int guesses = 1_000_000;
        long start = System.nanoTime();
        for (int i = 0; i < guesses; i++) {
            sha256.digest(("guess" + i).getBytes(StandardCharsets.UTF_8));
        }
        report("SHA-256", guesses, start);

        SecretKeyFactory pbkdf2 = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        byte[] salt = new byte[16];
        guesses = 5;
        start = System.nanoTime();
        for (int i = 0; i < guesses; i++) {
            PBEKeySpec spec = new PBEKeySpec(("guess" + i).toCharArray(), salt, 600_000, 256);
            pbkdf2.generateSecret(spec).getEncoded();
            spec.clearPassword();
        }
        report("PBKDF2, 600,000 iterations", guesses, start);
    }

    static void report(String name, int guesses, long start) {
        double seconds = (System.nanoTime() - start) / 1e9;
        System.out.printf("%-27s %,9d guesses in %.2f s: %,.0f a second%n", name, guesses, seconds, guesses / seconds);
    }
}
```

```
ana@vm:~/fp/secrets$ java Cost.java
SHA-256                     1,000,000 guesses in 0.15 s: 6,491,031 a second
PBKDF2, 600,000 iterations          5 guesses in 0.67 s: 7 a second
```

## Cinco milhões contra sete

O SHA-256 conferiu **mais de cinco milhões de palpites por segundo**, num núcleo desta máquina. É o digest da
aula 25 fazendo aquilo para que foi projetado, ser rápido, e para uma senha esse é o projeto errado: uma
lista com as cem milhões de senhas mais comuns leva menos de um minuto, e uma placa de vídeo é bem mais
rápida ainda. **O PBKDF2 com 600.000 iterações permitiu sete**: ele roda o HMAC-SHA-256 600.000 vezes em
cadeia, e um atacante tem de rodar a mesma cadeia para cada palpite. O usuário legítimo paga mais ou menos
um sétimo de segundo uma vez, quando entra; o atacante paga isso a cada palpite.

| guardado | um atacante com o banco |
|---|---|
| a própria senha | tem todas as senhas |
| um digest rápido, SHA-256 | testa milhões de palpites por segundo |
| uma derivação lenta com salt, PBKDF2 | testa um punhado por segundo, para cada conta separadamente |

600.000 iterações é o número que o guia de armazenamento de senhas do OWASP dá para o PBKDF2 com
HMAC-SHA-256. O número deve subir conforme as máquinas ficam mais rápidas, e é por isso que a próxima seção o
guarda ao lado de cada hash.

O PBKDF2 é a função de senha que o JDK traz. Argon2id e bcrypt costumam ser preferidos, porque também
precisam de memória, o que torna os milhares de núcleos de uma placa de vídeo bem menos úteis para um
atacante, mas o JDK não tem nenhum dos dois; eles vêm de bibliotecas como o Bouncy Castle ou o Spring
Security. O jeito de usá-los é o mesmo de abaixo.
