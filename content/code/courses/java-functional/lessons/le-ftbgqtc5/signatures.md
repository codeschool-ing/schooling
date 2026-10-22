---
title: Key pairs and signatures
version: 1
---

**An asymmetric algorithm uses two keys made together: a private key that its owner keeps, and a public
key that anybody may have.** What one key does, only the other can check. A **signature** is made with the
private key and verified with the public one, so a valid signature proves the message was signed by
whoever holds the private key, and that it has not changed since:

```java
// Sign.java: an Ed25519 signature, checked against the message, a changed message and another key
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PublicKey;
import java.security.Signature;

public class Sign {
    public static void main(String[] args) throws GeneralSecurityException {
        KeyPairGenerator generator = KeyPairGenerator.getInstance("Ed25519");
        KeyPair library = generator.generateKeyPair();
        KeyPair stranger = generator.generateKeyPair();

        byte[] notice = "ana owes nothing: all books returned".getBytes(StandardCharsets.UTF_8);
        Signature signer = Signature.getInstance("Ed25519");
        signer.initSign(library.getPrivate());
        signer.update(notice);
        byte[] signature = signer.sign();
        System.out.println("signature: " + signature.length + " bytes; public key: " + library.getPublic().getEncoded().length + " bytes");

        byte[] altered = "ana owes nothing: all books returned!".getBytes(StandardCharsets.UTF_8);
        System.out.println("the notice, library's key:  " + verify(library.getPublic(), notice, signature));
        System.out.println("altered notice:             " + verify(library.getPublic(), altered, signature));
        System.out.println("the notice, stranger's key: " + verify(stranger.getPublic(), notice, signature));
    }

    static boolean verify(PublicKey key, byte[] message, byte[] signature) throws GeneralSecurityException {
        Signature verifier = Signature.getInstance("Ed25519");
        verifier.initVerify(key);
        verifier.update(message);
        return verifier.verify(signature);
    }
}
```

```
ana@vm:~/fp/crypto$ java Sign.java
signature: 64 bytes; public key: 44 bytes
the notice, library's key:  true
altered notice:             false
the notice, stranger's key: false
```

## Three checks

The library's private key signed the notice, and the library's public key verified it: `true`. **One
character added to the notice and the same signature failed**, and so did the right notice checked
against a stranger's key. Nobody without the library's private key can produce a signature that the
library's public key accepts, which is the whole point: the public key can be printed on the library's
website, and anybody can check a notice with it, without being able to forge one.

Ed25519 is an elliptic-curve signature algorithm in the JDK since Java 15. Its signatures are 64 bytes and
its keys small, the 44 bytes above being the public key in the standard X.509 encoding. RSA does the same
job with keys of 3,072 bits or more, and is still everywhere, most HTTPS certificates among them.

| goal | tool | key |
|---|---|---|
| detect any change | digest | none |
| keep a secret between two parties | AES-GCM | one shared secret key |
| prove who wrote it, to anybody | signature | private to sign, public to verify |

The same pair of keys solves the problem the last section ended on. Two programs that have never shared
a secret can each make a key pair, exchange public keys, and derive one shared AES key from them by **key
agreement**, which the JDK provides as `KeyAgreement` with X25519. That is how HTTPS starts every
connection: the slow asymmetric step agrees on a key, and the fast symmetric cipher carries the data.
