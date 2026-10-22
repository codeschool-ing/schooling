---
title: Storing a password, and checking one
version: 1
---

**A stored password is three things beside the hash: the algorithm, its cost, and a salt.** The salt is
16 random bytes chosen for each password, so two people with the same password get different records, and
an attacker must attack each record separately instead of computing a table once for everybody. The
whole record fits in one string:

```java
// Passwords.java: storing a password as a salted PBKDF2 hash, and checking a login against it
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

public class Passwords {
    static final SecureRandom RANDOM = new SecureRandom();
    static final int ITERATIONS = 600_000;

    public static void main(String[] args) throws GeneralSecurityException {
        String first = hash("correct horse".toCharArray());
        String second = hash("correct horse".toCharArray());
        System.out.println(first);
        System.out.println(second);
        System.out.println("right password: " + verify("correct horse".toCharArray(), first));
        System.out.println("wrong password: " + verify("correct horse!".toCharArray(), first));

        String old = hash("battery staple".toCharArray(), 100_000);
        System.out.println("old record:     " + verify("battery staple".toCharArray(), old)
                + ", needs a new hash: " + needsRehash(old));
    }

    static String hash(char[] password) throws GeneralSecurityException {
        return hash(password, ITERATIONS);
    }

    static String hash(char[] password, int iterations) throws GeneralSecurityException {
        byte[] salt = new byte[16];
        RANDOM.nextBytes(salt);
        byte[] derived = derive(password, salt, iterations);
        Base64.Encoder b64 = Base64.getEncoder().withoutPadding();
        return "pbkdf2-sha256$" + iterations + "$" + b64.encodeToString(salt) + "$" + b64.encodeToString(derived);
    }

    static boolean verify(char[] password, String stored) throws GeneralSecurityException {
        String[] parts = stored.split("\\$");
        int iterations = Integer.parseInt(parts[1]);
        byte[] salt = Base64.getDecoder().decode(parts[2]);
        byte[] expected = Base64.getDecoder().decode(parts[3]);
        return MessageDigest.isEqual(derive(password, salt, iterations), expected);
    }

    static boolean needsRehash(String stored) {
        return Integer.parseInt(stored.split("\\$")[1]) < ITERATIONS;
    }

    static byte[] derive(char[] password, byte[] salt, int iterations) throws GeneralSecurityException {
        PBEKeySpec spec = new PBEKeySpec(password, salt, iterations, 256);
        try {
            return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).getEncoded();
        } finally {
            spec.clearPassword();
        }
    }
}
```

```
ana@vm:~/fp/secrets$ java Passwords.java
pbkdf2-sha256$600000$mhCTaVYwdyFBacjBJfA97w$QzmliPoWuBmwoTK180emjnbj6CnwJaq1BFE20DHyPoQ
pbkdf2-sha256$600000$8EcguLFm60lKqbvN++aKLA$HvIxN/e5AkL8SdXKVLOIX2c4zvPpSpIUb4YbaP7V99c
right password: true
wrong password: false
old record:     true, needs a new hash: true
```

## Reading the records

**The same password, hashed twice, gave two different records**, because each had its own salt, the third
field. Neither record contains the password, and neither can be turned back into it; the only thing that
can be done with one is what `verify` does: read the algorithm's settings out of the record, derive again
from the password typed, and compare. `MessageDigest.isEqual` is the comparison from lesson 25 that takes
the same time wherever the bytes differ.

The record carries its own cost, `600000`, and that is what made the last line possible. A record written
years ago with 100,000 iterations still **verified with the number it was written with**, and
`needsRehash` noticed it was below today's figure. The moment to fix it is the successful login, the one
time the server holds the password: hash it again at the new cost and store the new record. Nobody is
asked to change anything, and the old records disappear as people log in.

| rule | why |
|---|---|
| a new random salt per password | equal passwords give unequal records |
| the cost stored in the record | the cost can rise without breaking old records |
| the password as `char[]`, and `clearPassword()` | a `String` cannot be erased, and lingers in memory |
| compare with `MessageDigest.isEqual` | the time of the comparison says nothing |
| the same answer for a wrong password and an unknown user | the login page is not a way to ask who has an account |

The last row is outside this program and just as important. A login that says "no such user" for one
address and "wrong password" for another tells a stranger who has an account. So a server answers both
the same way, and takes the same time to do it, by checking a typed password against a decoy record when
the account does not exist.

That is the end of the course. Its first half wrote programs out of functions and streams; its second
gave those programs threads, files, a network and secrets to keep. The standard library of lessons 19 to
26 is what every Java framework is built on, so what comes next is mostly familiar code with more
convenience on top.
