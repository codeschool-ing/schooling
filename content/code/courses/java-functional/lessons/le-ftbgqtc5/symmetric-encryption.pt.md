---
title: Cifra simétrica com AES-GCM
version: 1
---

**Uma cifra simétrica usa uma chave secreta para cifrar e a mesma chave para decifrar.** O AES é a cifra
padrão, e o JDK diz como ela é usada numa string: algoritmo, modo e padding. **O GCM é o modo a usar**,
porque além de esconder o texto ele acrescenta uma tag que detecta qualquer mudança no que foi cifrado:

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

## O que aconteceu

O `KeyGenerator` fez uma chave aleatória de 256 bits. Os 32 bytes de texto viraram 48: **os mesmos 32,
cifrados, e uma tag de 16 bytes**, os `128` bits dados ao `GCMParameterSpec`. Decifrar com a mesma chave e o
mesmo IV devolveu o texto. O hexadecimal da segunda e da quarta linhas muda a cada execução, porque a chave
e os IVs são novos a cada vez.

O **IV**, o vetor de inicialização, é a outra entrada: 12 bytes aleatórios, escolhidos de novo para cada
mensagem e guardados ou enviados ao lado do texto cifrado, já que não é secreto. O mesmo texto cifrado de
novo com um IV novo saiu completamente diferente, então quem lê os textos cifrados não consegue nem saber
que duas mensagens eram iguais. **Um IV nunca pode ser usado duas vezes com a mesma chave**: com GCM, duas
mensagens sob uma chave e um IV vazam a relação entre os seus textos e deixam forjar a tag.

A última linha é o motivo do GCM. **Um bit do texto cifrado foi invertido, e a decifração recusou** com
`AEADBadTagException: Tag mismatch` em vez de devolver um texto errado num ponto. Sem a tag, uma cifra
decifra o que receber, e um texto cifrado alterado vira um texto alterado em que o programa depois confia.

| escolha | por quê |
|---|---|
| `AES/GCM/NoPadding` | cifra e detecta adulteração |
| `AES/ECB/...` | nunca: blocos iguais de texto dão blocos iguais de cifra, e os padrões aparecem |
| `AES/CBC/...` sozinho | esconde o texto mas não detecta nada; precisa de um MAC separado, feito certo |
| `Cipher.getInstance("AES")` | nunca: o JDK completa com ECB |

Uma chave simétrica tem de ser compartilhada pelos dois lados antes de eles conversarem, e mantida em
segredo pelos dois. Levá-la até lá com segurança é o problema que o outro tipo de chave, da próxima seção,
resolve.
