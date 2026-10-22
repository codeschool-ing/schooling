---
title: Lendo e gravando arquivos inteiros
version: 1
---

**`Files` é uma classe de métodos estáticos que fazem o trabalho, cada um recebendo um `Path`.** Gravar
um arquivo, lê-lo de volta e lê-lo linha a linha são uma chamada cada, e cada uma abre o arquivo, faz o
seu serviço e o fecha antes de retornar:

```java
// Catalogue.java: write a file, add a line to it, then read it back three ways
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.List;
import java.util.stream.Stream;

public class Catalogue {
    public static void main(String[] args) throws IOException {
        Path file = Path.of("catalogue.csv");
        Files.write(file, List.of(
                "Dune,Frank Herbert,1965,412",
                "Emma,Jane Austen,1815,474",
                "Dom Casmurro,Machado de Assis,1899,256"));
        Files.writeString(file, "Neuromancer,William Gibson,1984,271\n", StandardOpenOption.APPEND);
        System.out.println(Files.size(file) + " bytes");

        String all = Files.readString(file);
        System.out.println(all.lines().count() + " lines in one string");

        List<String> lines = Files.readAllLines(file);
        System.out.println("last: " + lines.getLast());

        try (Stream<String> stream = Files.lines(file)) {
            int pages = stream.map(line -> line.split(","))
                    .filter(fields -> Integer.parseInt(fields[2]) > 1900)
                    .mapToInt(fields -> Integer.parseInt(fields[3]))
                    .sum();
            System.out.println("pages after 1900: " + pages);
        }
    }
}
```

```
ana@vm:~/fp/files$ java Catalogue.java
129 bytes
4 lines in one string
last: Neuromancer,William Gibson,1984,271
pages after 1900: 683
```

## Três jeitos de ler, e quando cada um serve

O `Files.write` recebeu uma lista de linhas e gravou cada uma com uma quebra de linha depois; o
`Files.writeString` recebeu uma string. **Sem opções os dois substituem o arquivo**, criando-o se não
existir, e o `StandardOpenOption.APPEND` fez a segunda chamada acrescentar ao fim. Os dois codificam em
UTF-8 a menos que mandem outra coisa, então a regra da aula 19 de dizer a codificação já está cumprida.

| chamada | dá | guarda na memória |
|---|---|---|
| `Files.readString(path)` | o arquivo inteiro numa `String` | tudo |
| `Files.readAllLines(path)` | uma `List<String>`, uma por linha | tudo |
| `Files.lines(path)` | um `Stream<String>`, lido conforme é puxado | o que cabe num buffer |

As duas primeiras são a chamada certa para um arquivo de configuração ou um modelo, onde tudo é preciso e
é pequeno. **O `Files.lines` é o de um log de dois gigabytes**: ele lê as linhas só quando o stream as
puxa, então a soma acima teria precisado de mais ou menos a mesma memória num arquivo um milhão de vezes maior. É a fonte que
a aula 6 prometeu, e o pipeline sobre ela é o `map`, o `filter` e o `sum` da aula 7. Os dois livros
publicados depois de 1900 têm 412 e 271 páginas, e a soma deu 683.

## Um stream que segura um arquivo tem de ser fechado

O `Files.lines` é o único stream deste curso que **precisa ir num `try` com recursos**. Um stream feito
de uma lista não segura nada, mas este segura um arquivo aberto, o descritor da aula 19 seção 04, até ser
fechado, e uma operação terminal como `sum` não o fecha. O `Files.list`, o `Files.walk` e o `Files.find`
da próxima seção são iguais, pelo mesmo motivo.

Para arquivos grandes demais para ler inteiros e que não são feitos de linhas, `Files.newBufferedReader`,
`Files.newBufferedWriter`, `Files.newInputStream` e `Files.newOutputStream` dão os streams da aula 19, já
abertos no caminho.
