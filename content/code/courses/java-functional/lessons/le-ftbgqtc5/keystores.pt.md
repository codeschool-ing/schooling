---
title: Chaves moram num keystore
version: 1
---

**Uma chave numa variável vive enquanto o programa vive; uma chave de que o programa precisa amanhã tem de
ser guardada, e chaves guardadas são o que um atacante procura.** A resposta do JDK é um `KeyStore`, um
arquivo que guarda chaves privadas com os seus certificados, e chaves secretas, cada uma protegida por uma
senha. O formato padrão é o PKCS12, e o `keytool` do JDK cria e inspeciona um.

A senha não pode estar escrita no código nem ser digitada na linha de comando, onde o histórico do shell a
guarda. Defina-a primeiro no ambiente do terminal, digitando-a onde ela não aparece:

```
read -rs STOREPASS && export STOREPASS
```

Depois faça um par de chaves e um certificado autoassinado para ele, e liste o que o arquivo guarda:

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

O `-storepass:env STOREPASS` manda o `keytool` ler a senha daquela variável. A entrada é uma
`PrivateKeyEntry` sob o apelido `library`, com um certificado cuja impressão SHA-256 é impressa para uma
pessoa poder compará-la com a que outra pessoa vê. Um programa então lê a chave do arquivo, com a senha da
mesma variável:

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

## O que o programa fez

`KeyStore.getInstance("PKCS12")` e `load` abriram o arquivo com a senha, e o apelido voltou como `library`.
**A chave privada não saiu do keystore de forma legível até o programa pedi-la com a senha**, e o
certificado levava a chave pública correspondente, então o programa assinou com uma e verificou com a outra.
Com uma senha errada, o `load` recusa com `keystore password was incorrect` antes de entregar qualquer coisa.

O programa se recusa a começar quando `STOREPASS` falta, em vez de cair numa senha padrão. **Uma senha
padrão no código é a senha de toda cópia do programa**, e a primeira pessoa a ler o código a tem.

Um keystore é um arquivo, e o arquivo ainda precisa ser protegido: legível só pela conta que roda o
programa, nunca enviado ao controle de versão, e com uma senha que não é usada em nenhum outro lugar. Um
sistema em produção muitas vezes guarda a chave num módulo de hardware ou num serviço de chaves na nuvem, onde
o programa pode pedir uma assinatura e nunca vê a chave. O código Java quase não muda: um módulo de hardware
é alcançado pelas mesmas classes `KeyStore` e `Signature`, com outro provedor por trás.
