---
title: Fechando
version: 1
---

**Um stream aberto segura um recurso do sistema operacional, um descritor de arquivo, e o sistema
operacional dá a cada processo um número limitado deles.** Um stream que nunca é fechado guarda o seu
descritor até o coletor de lixo por acaso limpá-lo, o que pode ser nunca. Um programa que abre arquivos
num laço e esquece de fechá-los acaba ficando sem:

```java
// Leak.java: opening a file again and again without closing it
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class Leak {
    public static void main(String[] args) throws IOException {
        Files.writeString(Path.of("orders.txt"), "1,Dune\n");
        for (int i = 1; i <= 100; i++) {
            try {
                FileInputStream in = new FileInputStream("orders.txt");
                in.read();
            } catch (IOException e) {
                System.out.println("file " + i + ": " + e.getMessage());
                return;
            }
        }
        System.out.println("opened 100 files");
    }
}
```

O `ulimit -n` define quantos descritores os programas do shell podem segurar. O limite comum no Ubuntu é
1.024; os parênteses rodam o programa com um limite de 64, para a falha chegar rápido, e deixam o limite
do próprio terminal como estava:

```
ana@vm:~/fp/io$ (ulimit -n 64; java Leak.java)
file 61: orders.txt (Too many open files)
```

A própria JVM segura algumas dezenas de descritores para os seus arquivos, e **o 61º `FileInputStream`
foi recusado** com `Too many open files`. Num servidor que vaza um descritor por requisição, a mesma
mensagem chega depois de alguns milhares de requisições, vinda do código que por acaso abrir o próximo
arquivo ou socket, longe do vazamento.

## try-with-resources, sempre

O remédio é a aula 37 do `java`: declare o stream num `try` com recursos, e ele é fechado quando o bloco
termina, normalmente ou por exceção. Com camadas, **feche a mais externa**; cada stream fecha o stream que
embrulha, então um `close` num `BufferedReader` fecha o reader, a ponte e o arquivo.

```java
// NoLeak.java: the same loop with try-with-resources
import java.io.FileInputStream;
import java.io.IOException;

public class NoLeak {
    public static void main(String[] args) throws IOException {
        for (int i = 1; i <= 100; i++) {
            try (FileInputStream in = new FileInputStream("orders.txt")) {
                in.read();
            }
        }
        System.out.println("opened and closed 100 files");
    }
}
```

```
ana@vm:~/fp/io$ (ulimit -n 64; java NoLeak.java)
opened and closed 100 files
```

Os mesmos 64 descritores bastaram para cem arquivos, e bastariam para um milhão, porque cada um foi
devolvido antes de o próximo ser pego.
