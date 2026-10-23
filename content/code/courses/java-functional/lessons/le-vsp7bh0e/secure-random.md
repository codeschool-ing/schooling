---
title: SecureRandom
version: 1
---

**`SecureRandom` is a source of numbers that cannot be predicted from earlier ones, seeded from the
operating system's own collection of unpredictable events.** It is the class for every secret a program
generates: tokens, keys, salts, the IVs of lesson 25. Its use is the same as `Random`'s, and what it is
used for is different:

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

## A token, a code, and a hundred thousand of them

On Linux the default algorithm is `NativePRNG`, which reads from the kernel's random device. **32 random
bytes are 256 bits**, more than anybody can guess, and Base64 in its URL-safe form, without padding,
writes them as 43 characters that fit in a link without escaping. A hundred thousand tokens came out with
no repeats, and that is the expected result: the chance of two 256-bit tokens being equal is too small to
write down.

The six-digit code is the other common form, and it has only a million values. That is fine for a code
sent by message that expires in minutes and allows a handful of attempts, and wrong for anything else. **The strength of a random secret is the number of values it could have had**, and a short code
borrows its safety from the limits around it.

Three habits keep `SecureRandom` working as intended. Make one and share it; it is thread-safe, and the
field above is used by every call. Do not give it a seed: `setSeed` with a fixed value on some
implementations makes it as predictable as `Random`. And do not reach for `SecureRandom.getInstanceStrong()`
on a server without reading what it does, because on some systems it can block, waiting for the
operating system to gather more randomness, at the moment a user is waiting for a page.
