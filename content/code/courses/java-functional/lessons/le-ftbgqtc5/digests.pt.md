---
title: Digests
version: 1
---

**Um digest criptográfico transforma qualquer quantidade de bytes numa impressão digital curta de tamanho
fixo, e é construído para que ninguém consiga achar duas entradas com a mesma impressão, nem uma entrada
para uma impressão que recebeu.** O SHA-256 dá 32 bytes. O JDK o calcula com o `MessageDigest`:

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

## O que as impressões mostram

Os dois textos diferem na última letra, e **132 dos 256 bits dos seus digests diferem**, mais ou menos a
metade, que é o que um bom digest faz: nada na saída diz o quão próximas eram as entradas. O mesmo texto deu
o mesmo digest, e o último comando, o `sha256sum` do coreutils do Ubuntu, calculou os mesmos 64 dígitos
hexadecimais a partir dos mesmos bytes, porque o SHA-256 é um padrão e não uma invenção do Java.

Esse par de propriedades faz de um digest uma verificação de **integridade**: publique o digest de um
arquivo, e quem o baixar pode calculá-lo de novo e comparar. Não é uma verificação de **quem** fez o
arquivo. Qualquer um calcula um digest, então quem consegue trocar o arquivo consegue trocar o digest
publicado ao lado dele; provar o autor é o papel das assinaturas, duas seções adiante.

O `MessageDigest.isEqual` compara dois digests num tempo que não depende de onde eles começam a diferir. O
`Arrays.equals` para no primeiro byte diferente, o que, para um valor que um atacante está adivinhando,
conta a ele quanto do palpite estava certo.

| algoritmo | saída | usar? |
|---|---|---|
| MD5 | 16 bytes | não: colisões podem ser feitas num notebook |
| SHA-1 | 20 bytes | não: uma colisão foi publicada em 2017 |
| SHA-256 | 32 bytes | sim |
| SHA-512, SHA3-256 | 64 e 32 bytes | sim |

Uma coisa para a qual um digest rápido não serve é senha. O SHA-256 foi feito para ser rápido, e rápido é o
que quer um atacante tentando um bilhão de palpites; a aula 26 mostra a função lenta feita para esse
trabalho.
