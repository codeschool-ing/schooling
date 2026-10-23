---
title: Digests
version: 1
---

**A cryptographic digest turns any number of bytes into a short fixed-size fingerprint, and it is built
so that nobody can find two inputs with the same fingerprint, or an input for a fingerprint they were
given.** SHA-256 gives 32 bytes. The JDK computes it with `MessageDigest`:

```java
// Fingerprint.java: a SHA-256 digest of some text, and what one changed letter does to it
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

public class Fingerprint {
    public static void main(String[] args) throws NoSuchAlgorithmException {
        byte[] a = sha256("Dune by Frank Herbert");
        byte[] b = sha256("Dune by Frank Herbers");
        System.out.println(HexFormat.of().formatHex(a));
        System.out.println(HexFormat.of().formatHex(b));

        int differing = 0;
        for (int i = 0; i < a.length; i++) {
            differing += Integer.bitCount((a[i] ^ b[i]) & 0xff);
        }
        System.out.println(a.length + " bytes each; " + differing + " of " + a.length * 8 + " bits differ");
        System.out.println("same text, same digest: " + MessageDigest.isEqual(a, sha256("Dune by Frank Herbert")));
    }

    static byte[] sha256(String text) throws NoSuchAlgorithmException {
        return MessageDigest.getInstance("SHA-256").digest(text.getBytes(StandardCharsets.UTF_8));
    }
}
```

```
ana@vm:~/fp/crypto$ java Fingerprint.java
542f8ae2095f418aab557957f0d858cfa207fc84385402973d36d1f0cba721b4
cfcf470c55ffc2f6a7ded5d7e202257c41693fa784f8cc86424245845b5ed6c0
32 bytes each; 132 of 256 bits differ
same text, same digest: true
ana@vm:~/fp/crypto$ printf 'Dune by Frank Herbert' | sha256sum
542f8ae2095f418aab557957f0d858cfa207fc84385402973d36d1f0cba721b4  -
```

## What the fingerprints show

The two texts differ in their last letter, and **132 of the 256 bits of their digests differ**, about
half, which is what a good digest does: nothing in the output says how close the inputs were. The same
text gave the same digest, and the last command, `sha256sum` from Ubuntu's coreutils, computed the same
64 hexadecimal digits from the same bytes, because SHA-256 is a standard and not a Java invention.

That pair of properties makes a digest a check of **integrity**: publish the digest of a file, and
anybody who downloads it can compute it again and compare. It is not a check of **who** made the file.
Anybody can compute a digest, so whoever can replace the file can replace the published digest beside
it; proving the author is what signatures, two sections on, are for.

`MessageDigest.isEqual` compares two digests in a time that does not depend on where they first differ.
`Arrays.equals` stops at the first different byte, which, for a value an attacker is guessing, tells
them how much of the guess was right.

| algorithm | output | use it? |
|---|---|---|
| MD5 | 16 bytes | no: collisions can be made on a laptop |
| SHA-1 | 20 bytes | no: a collision was published in 2017 |
| SHA-256 | 32 bytes | yes |
| SHA-512, SHA3-256 | 64 and 32 bytes | yes |

One thing a fast digest is not for is passwords. SHA-256 is designed to be fast, and fast is what an
attacker trying a billion guesses wants; lesson 26 shows the slow function made for that job.
