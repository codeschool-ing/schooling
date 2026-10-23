---
title: Slow on purpose
version: 1
---

**A server must be able to check a password and must not be able to read one.** So it stores something
computed from the password, and when somebody logs in it computes the same thing from what they typed and
compares. If the database leaks, the attacker has the stored values and no passwords, and has to guess:
take a likely password, compute, compare, repeat. **The only thing the server controls is how long each
guess costs**:

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

## Five million against seven

SHA-256 checked **over five million guesses a second**, on one core of this machine. That is the digest of
lesson 25 doing what it was designed for, being fast, and for a password it is the wrong design: a list of
the hundred million most common passwords takes it under a minute, and a graphics card is far faster
still. **PBKDF2 with 600,000 iterations allowed seven**: it runs HMAC-SHA-256 600,000 times in a chain,
and an attacker has to run the same chain for every guess. The legitimate user pays about a seventh of a
second once, when they log in; the attacker pays it for every guess.

| stored | an attacker with the database |
|---|---|
| the password itself | has every password |
| a fast digest, SHA-256 | tests millions of guesses a second |
| a slow derivation with a salt, PBKDF2 | tests a handful a second, for each account separately |

600,000 iterations is the figure OWASP's password storage guidance gives for PBKDF2 with HMAC-SHA-256.
The number is meant to rise as machines get faster, which is why the next section stores it beside every
hash.

PBKDF2 is the password function the JDK ships. Argon2id and bcrypt are generally preferred, because they
also need memory, which makes a graphics card's thousands of cores much less useful to an attacker, but
the JDK has neither; they come from libraries such as Bouncy Castle or Spring Security. The way they are used is the same as below.
