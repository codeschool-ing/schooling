---
title: Texto vindo de fora
version: 1
---

**Uma caixa de busca que compila o que o usuário digitou como padrão entregou ao usuário uma linguagem de
programação.** O que ele digita pode ser um padrão que quer dizer algo que ele não pretendia, um padrão que
não compila, ou um padrão como o terceiro da seção anterior. A saída é um método, o `Pattern.quote`, que
transforma qualquer string num padrão que casa exatamente com aquela string:

```java
// Search.java: a search term typed by somebody else, used as text and not as a pattern
import java.util.List;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

public class Search {
    static final List<String> TITLES = List.of("C++ Primer", "The C Programming Language", "Dune", "Effective Java");

    public static void main(String[] args) {
        for (String term : new String[] {"java", "C++", "*java"}) {
            System.out.println(term);
            System.out.println("  as a pattern: " + asPattern(term));
            System.out.println("  quoted:       " + quoted(term));
        }
    }

    static String asPattern(String term) {
        try {
            Pattern p = Pattern.compile(term, Pattern.CASE_INSENSITIVE);
            return TITLES.stream().filter(t -> p.matcher(t).find()).toList().toString();
        } catch (PatternSyntaxException e) {
            return "refused: " + e.getDescription();
        }
    }

    static String quoted(String term) {
        Pattern p = Pattern.compile(Pattern.quote(term), Pattern.CASE_INSENSITIVE);
        return TITLES.stream().filter(t -> p.matcher(t).find()).toList().toString();
    }
}
```

```
ana@vm:~/fp/regex$ java Search.java
java
  as a pattern: [Effective Java]
  quoted:       [Effective Java]
C++
  as a pattern: [C++ Primer, The C Programming Language, Effective Java]
  quoted:       [C++ Primer]
*java
  as a pattern: refused: Dangling meta character '*'
  quoted:       []
```

## Três termos

`java` achou o mesmo livro dos dois jeitos: não tem caracteres especiais. **`C++` como padrão achou três
livros, dois deles errados**: `+` é um quantificador, então `C++` quer dizer um ou mais `C`s, de modo
possessivo, e com `CASE_INSENSITIVE` ele achou o `c` de "Effective Java" e o `C` do outro título. Nada
falhou, e os resultados simplesmente estavam errados. Entre aspas, ele achou o único livro com `C++` no
título.

`*java` foi recusado como padrão com uma `PatternSyntaxException`: um `*` precisa vir depois de algo a
repetir. Uma página de busca que mostra essa mensagem contou ao usuário como funciona por dentro; uma que não
a captura falha com uma página de erro. Entre aspas, é uma busca pelo texto `*java`, que nenhum título tem.

| quando o padrão vem de | faça |
|---|---|
| o código | escreva-o para cada pedaço casar de um jeito, e compile-o uma vez |
| um usuário, que quer dizer texto simples | `Pattern.quote(term)`, ou `String.contains` e padrão nenhum |
| um usuário, que de fato escreve padrões | limite o tamanho do texto, e construa um limite de tempo |

A última linha é rara e difícil: o `Matcher` do Java não tem timeout, e interromper a thread dele não o
para, então um programa que precisa aceitar padrões de estranhos tem de construir o próprio limite, e limita
o tamanho que o texto pode ter, já que o custo dos piores padrões cresce com o tamanho do texto. **Para quase
todo programa a resposta é a linha do meio.** Um termo de busca é texto, e o `quote` o mantém texto.
