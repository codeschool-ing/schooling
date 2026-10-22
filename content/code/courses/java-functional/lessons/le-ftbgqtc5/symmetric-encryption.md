---
title: Symmetric encryption with AES-GCM
version: 1
---

**A symmetric cipher uses one secret key to encrypt and the same key to decrypt.** AES is the standard
cipher, and the JDK names how it is used in one string: algorithm, mode and padding. **GCM is the mode
to use**, because besides hiding the text it adds a tag that detects any change to what was encrypted:

```java
// Seal.java: encrypting with AES-GCM, decrypting, and what one changed bit does
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.HexFormat;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

public class Seal {
    static final SecureRandom RANDOM = new SecureRandom();

    public static void main(String[] args) throws GeneralSecurityException {
        KeyGenerator generator = KeyGenerator.getInstance("AES");
        generator.init(256);
        SecretKey key = generator.generateKey();

        byte[] plain = "loan Dune to ana, due 2026-03-20".getBytes(StandardCharsets.UTF_8);
        byte[] iv = new byte[12];
        RANDOM.nextBytes(iv);
        byte[] sealed = encrypt(key, iv, plain);
        System.out.println("plain " + plain.length + " bytes, sealed " + sealed.length + " bytes");
        System.out.println("sealed starts " + HexFormat.of().formatHex(sealed, 0, 8));
        System.out.println("opened: " + new String(decrypt(key, iv, sealed), StandardCharsets.UTF_8));

        byte[] iv2 = new byte[12];
        RANDOM.nextBytes(iv2);
        System.out.println("again, new IV, starts " + HexFormat.of().formatHex(encrypt(key, iv2, plain), 0, 8));

        sealed[3] ^= 1;
        try {
            decrypt(key, iv, sealed);
        } catch (GeneralSecurityException e) {
            System.out.println("one bit changed: " + e);
        }
    }

    static byte[] encrypt(SecretKey key, byte[] iv, byte[] plain) throws GeneralSecurityException {
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(128, iv));
        return cipher.doFinal(plain);
    }

    static byte[] decrypt(SecretKey key, byte[] iv, byte[] sealed) throws GeneralSecurityException {
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(128, iv));
        return cipher.doFinal(sealed);
    }
}
```

```
ana@vm:~/fp/crypto$ java Seal.java
plain 32 bytes, sealed 48 bytes
sealed starts 41692fb91d08f724
opened: loan Dune to ana, due 2026-03-20
again, new IV, starts e126a7ba8eb6bd02
one bit changed: javax.crypto.AEADBadTagException: Tag mismatch
```

## What happened

`KeyGenerator` made a random 256-bit key. The 32 bytes of text became 48: **the same 32, encrypted, and a
16-byte tag**, the `128` bits given to `GCMParameterSpec`. Decrypting with the same key and IV gave the
text back. The hexadecimal on the second and fourth lines differs on every run, because the key and the
IVs are new each time.

The **IV**, the initialisation vector, is the other input: 12 random bytes, chosen afresh for every
message and stored or sent beside the ciphertext, since it is not secret. The same text encrypted again
with a new IV came out completely different, so a reader of the ciphertexts cannot even tell that two
messages were the same. **An IV must never be used twice with the same key**: with GCM, two messages under
one key and one IV leak the relation between their texts and let the tag be forged.

The last line is the reason for GCM. **One bit of the ciphertext was flipped, and decryption refused**
with `AEADBadTagException: Tag mismatch` instead of returning text that is wrong in one place. Without the
tag a cipher decrypts whatever it is given, and changed ciphertext becomes changed text that the program
then trusts.

| choice | why |
|---|---|
| `AES/GCM/NoPadding` | encrypts and detects tampering |
| `AES/ECB/...` | never: equal blocks of text give equal blocks of ciphertext, and patterns show through |
| `AES/CBC/...` alone | hides the text but detects nothing; it needs a separate MAC done correctly |
| `Cipher.getInstance("AES")` | never: the JDK fills in ECB |

A symmetric key has to be shared by both sides before they can talk, and kept secret by both. Getting
it there safely is the problem the next section's other kind of key solves.
