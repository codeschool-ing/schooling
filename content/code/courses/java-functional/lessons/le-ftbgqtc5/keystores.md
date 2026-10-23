---
title: Keys live in a keystore
version: 1
---

**A key in a variable lives as long as the program; a key the program needs tomorrow has to be stored,
and stored keys are the thing an attacker looks for.** The JDK's answer is a `KeyStore`, a file that holds
private keys with their certificates, and secret keys, each protected by a password. The standard format
is PKCS12, and the JDK's `keytool` creates and inspects one.

The password must not be written in the code or typed on the command line, where the shell's history
keeps it. Set it in the environment of the terminal first, typing it where it is not shown:

```
read -rs STOREPASS && export STOREPASS
```

Then make a key pair and a self-signed certificate for it, and list what the file holds:

```
ana@vm:~/fp/crypto$ keytool -genkeypair -alias library -keyalg Ed25519 -dname "CN=library.example" -validity 365 -keystore library.p12 -storetype PKCS12 -storepass:env STOREPASS
Generating Ed25519 key pair and self-signed certificate (Ed25519) with a validity of 365 days
	for: CN=library.example
ana@vm:~/fp/crypto$ keytool -list -keystore library.p12 -storepass:env STOREPASS
Keystore type: PKCS12
Keystore provider: SUN

Your keystore contains 1 entry

library, Oct 22, 2026, PrivateKeyEntry, 
Certificate fingerprint (SHA-256): 1B:D8:42:57:5C:00:0E:7C:27:5E:6B:6A:D7:6C:B1:A6:95:F7:85:32:81:B8:3F:31:A7:0E:41:A3:31:E3:DC:A7
```

`-storepass:env STOREPASS` tells `keytool` to read the password from that variable. The entry is a
`PrivateKeyEntry` under the alias `library`, with a certificate whose SHA-256 fingerprint is printed so a
person can compare it with the one somebody else sees. A program then reads the key from the file, with
the password from the same variable:

```java
// Store.java: a key pair read from a PKCS12 keystore, with the password from the environment
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.Signature;
import java.security.cert.Certificate;
import java.util.Collections;

public class Store {
    public static void main(String[] args) throws IOException, GeneralSecurityException {
        String secret = System.getenv("STOREPASS");
        if (secret == null) {
            System.err.println("set STOREPASS first");
            System.exit(1);
        }
        char[] password = secret.toCharArray();

        KeyStore store = KeyStore.getInstance("PKCS12");
        try (InputStream in = new FileInputStream("library.p12")) {
            store.load(in, password);
        }
        System.out.println("aliases: " + Collections.list(store.aliases()));

        PrivateKey key = (PrivateKey) store.getKey("library", password);
        Certificate certificate = store.getCertificate("library");
        System.out.println("key: " + key.getAlgorithm() + ", certificate type: " + certificate.getType());

        byte[] notice = "ana owes nothing: all books returned".getBytes(StandardCharsets.UTF_8);
        Signature signer = Signature.getInstance("Ed25519");
        signer.initSign(key);
        signer.update(notice);
        byte[] signature = signer.sign();

        Signature verifier = Signature.getInstance("Ed25519");
        verifier.initVerify(certificate.getPublicKey());
        verifier.update(notice);
        System.out.println("signed with the stored key, verified with its certificate: " + verifier.verify(signature));
    }
}
```

```
ana@vm:~/fp/crypto$ java Store.java
aliases: [library]
key: EdDSA, certificate type: X.509
signed with the stored key, verified with its certificate: true
ana@vm:~/fp/crypto$ STOREPASS=wrong java Store.java 2>&1 | head -2
Exception in thread "main" java.io.IOException: keystore password was incorrect
	at java.base/sun.security.pkcs12.PKCS12KeyStore.engineLoad(PKCS12KeyStore.java:2109)
```

## What the program did

`KeyStore.getInstance("PKCS12")` and `load` opened the file with the password, and the alias came back as
`library`. **The private key never left the keystore in any readable form until the program asked for it
with the password**, and the certificate carried the matching public key, so the program signed with one
and verified with the other. With a wrong password, `load` refuses with `keystore password was incorrect`
before giving out anything.

The program refuses to start when `STOREPASS` is missing rather than falling back to a default password.
**A default password in the code is the password of every copy of the program**, and the first person to
read the source has it.

A keystore is a file, and the file still has to be protected: readable only by the account that runs the
program, never committed to version control, and with a password that is not used anywhere else. A
production system often keeps the key in a hardware module or a cloud key service instead, where the
program can ask for a signature and never sees the key at all. The Java code barely changes: a hardware module
is reached through the same `KeyStore` and `Signature` classes, with a different provider behind them.
