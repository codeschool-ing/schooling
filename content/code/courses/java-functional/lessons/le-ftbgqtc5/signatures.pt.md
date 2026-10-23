---
title: Pares de chaves e assinaturas
version: 1
---

**Um algoritmo assimétrico usa duas chaves feitas juntas: uma chave privada que o dono guarda, e uma chave
pública que qualquer um pode ter.** O que uma chave faz, só a outra confere. Uma **assinatura** é feita com
a chave privada e verificada com a pública, então uma assinatura válida prova que a mensagem foi assinada
por quem tem a chave privada, e que não mudou desde então:

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

## Três verificações

A chave privada da biblioteca assinou o aviso, e a chave pública da biblioteca o verificou: `true`. **Um
caractere acrescentado ao aviso e a mesma assinatura falhou**, e o mesmo aconteceu com o aviso certo
conferido contra a chave de um estranho. Ninguém sem a chave privada da biblioteca consegue produzir uma
assinatura que a chave pública da biblioteca aceite, e esse é o objetivo: a chave pública pode ficar no site
da biblioteca, e qualquer um pode conferir um aviso com ela, sem conseguir forjar um.

O Ed25519 é um algoritmo de assinatura com curvas elípticas, no JDK desde o Java 15. As suas assinaturas têm
64 bytes e as chaves são pequenas, os 44 bytes acima sendo a chave pública na codificação X.509 padrão. O RSA
faz o mesmo trabalho com chaves de 3.072 bits ou mais, e ainda está em todo lugar, inclusive na maioria dos
certificados HTTPS.

| objetivo | ferramenta | chave |
|---|---|---|
| detectar qualquer mudança | digest | nenhuma |
| guardar um segredo entre duas partes | AES-GCM | uma chave secreta compartilhada |
| provar quem escreveu, para qualquer um | assinatura | privada para assinar, pública para verificar |

O mesmo par de chaves resolve o problema com que a seção anterior terminou. Dois programas que nunca
compartilharam um segredo podem cada um fazer um par de chaves, trocar as chaves públicas, e derivar delas
uma chave AES compartilhada por **acordo de chaves**, que o JDK oferece como `KeyAgreement` com X25519. É
assim que o HTTPS começa cada conexão: o passo assimétrico, lento, combina uma chave, e a cifra simétrica,
rápida, carrega os dados.
