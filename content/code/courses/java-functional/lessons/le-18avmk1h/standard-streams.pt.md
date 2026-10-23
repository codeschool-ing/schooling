---
title: Entrada, saída e erro padrão
version: 1
---

**Todo programa começa com três streams já abertos: a entrada padrão, a saída padrão e o erro padrão.**
O Java os chama de `System.in`, um `InputStream`, e `System.out` e `System.err`, dois `PrintStream`. O
shell decide para onde eles levam: o teclado e o terminal por padrão, ou um arquivo, ou outro programa,
e é assim que um programa Java toma o seu lugar numa sequência de comandos.

```java
// WordCount.java: count the lines and words that arrive on standard input
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

public class WordCount {
    public static void main(String[] args) throws IOException {
        BufferedReader in = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
        long lines = 0;
        long words = 0;
        String line;
        while ((line = in.readLine()) != null) {
            lines++;
            String trimmed = line.strip();
            if (!trimmed.isEmpty()) {
                words += trimmed.split("\\s+").length;
            }
        }
        System.out.println(lines + " lines, " + words + " words");
        if (lines == 0) {
            System.err.println("warning: nothing arrived on standard input");
        }
    }
}
```

```
ana@vm:~/fp/io$ java WordCount.java < shelf.txt
3 lines, 4 words
ana@vm:~/fp/io$ printf 'the hobbit\nthere and back again\n' | java WordCount.java
2 lines, 6 words
ana@vm:~/fp/io$ java WordCount.java < /dev/null
0 lines, 0 words
warning: nothing arrived on standard input
ana@vm:~/fp/io$ java WordCount.java < /dev/null 2> errors.txt
0 lines, 0 words
ana@vm:~/fp/io$ cat errors.txt
warning: nothing arrived on standard input
```

## Lendo as quatro execuções

A primeira lê `shelf.txt`, o arquivo que `Layers.java` escreveu na seção 03, através de `<`, que faz do
arquivo a entrada padrão do programa. A segunda recebe a saída do `printf` por um pipe, `|`, como se os
dois programas fossem um. **O programa não sabe nem se importa de onde veio a sua entrada**, e é isso que
deixa combiná-lo com qualquer outro.

As duas últimas não mandam nada, de `/dev/null`, o arquivo que está sempre vazio. A contagem vai para a
saída padrão e o aviso para o erro padrão, e `2> errors.txt` manda o erro padrão para um arquivo, então o
aviso saiu do terminal e foi para onde mandaram. **Resultados na saída padrão, reclamações no erro
padrão**: um script que encadeia a saída em outro programa nunca o alimenta com uma mensagem de aviso
por engano.

O `System.in` não é fechado pelo programa, de propósito: ele pertence ao processo, não ao `main`, e
fechá-lo impediria qualquer outra parte do programa de lê-lo.
