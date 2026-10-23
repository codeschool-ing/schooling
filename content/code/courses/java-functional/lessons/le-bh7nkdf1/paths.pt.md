---
title: Um Path é um nome
version: 1
---

**O `java.nio.file` é a porta mais nova para o sistema de arquivos, e começa pelo `Path`: o nome de um
arquivo ou de um diretório, e nada mais.** Construir um `Path` não abre nada e não confere se algo existe.
É uma sequência de nomes unidos pelo separador do sistema, com métodos para desmontá-la e montá-la:

```java
// Names.java: a Path is a name, and nothing here touches the disk but one line
import java.nio.file.Files;
import java.nio.file.Path;

public class Names {
    public static void main(String[] args) {
        Path dune = Path.of("library", "fiction", "dune.txt");
        System.out.println("path:      " + dune);
        System.out.println("file name: " + dune.getFileName());
        System.out.println("parent:    " + dune.getParent());
        System.out.println("names:     " + dune.getNameCount());
        System.out.println("exists:    " + Files.exists(dune));

        Path base = Path.of("library");
        Path odes = base.resolve("fiction/../poetry/./odes.txt");
        System.out.println("resolved:  " + odes);
        System.out.println("normal:    " + odes.normalize());
        System.out.println("relative:  " + base.relativize(dune));
        System.out.println("absolute:  " + dune.toAbsolutePath());
    }
}
```

```
ana@vm:~/fp/files$ java Names.java
path:      library/fiction/dune.txt
file name: dune.txt
parent:    library/fiction
names:     3
exists:    false
resolved:  library/fiction/../poetry/./odes.txt
normal:    library/poetry/odes.txt
relative:  fiction/dune.txt
absolute:  /home/ana/fp/files/library/fiction/dune.txt
```

## Desmontando e montando

`Path.of("library", "fiction", "dune.txt")` juntou três nomes em `library/fiction/dune.txt`, com o
separador do sistema onde rodou, então a mesma linha dá `library\fiction\dune.txt` no Windows. **O caminho
foi construído, impresso e desmontado, e a única linha que perguntou ao disco disse que o arquivo não
existe.** Nada falhou antes dessa linha, e nada falharia: um `Path` para um arquivo que não está lá é um
`Path` perfeitamente bom.

| método | responde | toca o disco? |
|---|---|---|
| `getFileName()` | o último nome, `dune.txt` | não |
| `getParent()` | tudo o que vem antes dele | não |
| `resolve(other)` | este caminho com `other` juntado depois | não |
| `normalize()` | o mesmo caminho sem `.` e sem `nome/..` | não |
| `relativize(other)` | os passos deste caminho até `other` | não |
| `toAbsolutePath()` | o caminho a partir da raiz, usando o diretório de trabalho | não |
| `Files.exists(path)` | se há alguma coisa lá agora | sim |

O `resolve` juntou o texto como foi dado, com pontos e tudo, e **o `normalize` arrumou-o lendo os nomes,
não o disco**: `fiction/..` se anula exista ou não `fiction`. O `toAbsolutePath` perguntou ao programa o
seu diretório de trabalho, `/home/ana/fp/files`, e mesmo assim não procurou o arquivo. Tudo o que olha o
disco é um método estático de `Files`, que é a próxima seção.

O `Path` substitui o `java.io.File`, a classe do Java 1.0. O `File` ainda está em código antigo e em APIs
antigas, e os dois se convertem com `file.toPath()` e `path.toFile()`. Código novo começa pelo `Path`,
porque os métodos que o usam informam uma falha com uma exceção que diz qual foi, onde o `File` muitas
vezes respondia `false` e não dizia mais nada.
