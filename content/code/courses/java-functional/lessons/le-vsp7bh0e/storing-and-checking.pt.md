---
title: Guardando uma senha, e conferindo uma
version: 1
---

**Uma senha guardada é três coisas além do hash: o algoritmo, o seu custo e um salt.** O salt são 16 bytes
aleatórios escolhidos para cada senha, então duas pessoas com a mesma senha ganham registros diferentes, e
um atacante tem de atacar cada registro separadamente em vez de calcular uma tabela uma vez para todo mundo.
O registro inteiro cabe numa string:

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

## Lendo os registros

**A mesma senha, passada pelo hash duas vezes, deu dois registros diferentes**, porque cada um teve o seu
salt, o terceiro campo. Nenhum dos registros contém a senha, e nenhum pode ser transformado de volta nela; a
única coisa que se pode fazer com um é o que o `verify` faz: ler do registro os ajustes do algoritmo, derivar
de novo a partir da senha digitada, e comparar. O `MessageDigest.isEqual` é a comparação da aula 25 que leva
o mesmo tempo onde quer que os bytes difiram.

O registro leva o seu próprio custo, `600000`, e foi isso que tornou possível a última linha. Um registro
gravado anos atrás com 100.000 iterações ainda **foi verificado com o número com que foi gravado**, e o
`needsRehash` percebeu que ele estava abaixo do número de hoje. O momento de consertá-lo é o login bem
sucedido, a única vez em que o servidor tem a senha: passar o hash de novo no custo novo e guardar o registro
novo. Ninguém é chamado a mudar nada, e os registros antigos somem conforme as pessoas entram.

| regra | por quê |
|---|---|
| um salt aleatório novo por senha | senhas iguais dão registros diferentes |
| o custo guardado no registro | o custo pode subir sem quebrar registros antigos |
| a senha como `char[]`, e `clearPassword()` | uma `String` não pode ser apagada, e fica na memória |
| comparar com `MessageDigest.isEqual` | o tempo da comparação não diz nada |
| a mesma resposta para senha errada e usuário desconhecido | a página de login não é um jeito de perguntar quem tem conta |

A última linha está fora deste programa e é igualmente importante. Um login que diz "usuário não existe"
para um endereço e "senha errada" para outro conta a um estranho quem tem conta, então um servidor responde
aos dois do mesmo jeito, e leva o mesmo tempo para isso, conferindo a senha digitada contra um registro de
fachada quando a conta não existe.

É o fim do curso. A primeira metade escreveu programas com funções e streams; a segunda deu a esses
programas threads, arquivos, uma rede e segredos para guardar. A biblioteca padrão das aulas 19 a 26 é a base
de todo framework Java, então o que vem depois é, na maior parte, código conhecido com mais conveniência por
cima.
