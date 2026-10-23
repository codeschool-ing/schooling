---
title: Substituindo e dividindo
version: 1
---

**Casar é metade do uso dos padrões; a outra metade é mudar texto.** Um padrão pode ser o separador em que
uma string é dividida, a parte de uma string que é substituída, ou o lugar onde uma função é aplicada:

```java
// Tidy.java: splitting, replacing, and replacing with a function
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Tidy {
    public static void main(String[] args) {
        String messy = "Dune ,  Emma,Dom Casmurro ;Neuromancer";
        List<String> titles = Pattern.compile("\\s*[,;]\\s*").splitAsStream(messy).toList();
        System.out.println(titles);

        System.out.println("2026-03-20".replaceAll("(\\d{4})-(\\d{2})-(\\d{2})", "$3/$2/$1"));

        String tags = "#scifi #classic #brazil #scifi";
        System.out.println(Pattern.compile("#(\\w+)").matcher(tags).results()
                .map(r -> r.group(1)).distinct().sorted().toList());

        String stock = "3 copies of Dune, 12 of Emma";
        System.out.println(Pattern.compile("\\d+").matcher(stock)
                .replaceAll(r -> String.valueOf(Integer.parseInt(r.group()) * 2)));

        String price = "R$12,90";
        System.out.println("price: X".replace("X", price));
        System.out.println("price: X".replaceAll("X", Matcher.quoteReplacement(price)));
        try {
            System.out.println("price: X".replaceAll("X", price));
        } catch (IndexOutOfBoundsException e) {
            System.out.println("replaceAll failed: " + e);
        }
    }
}
```

```
ana@vm:~/fp/regex$ java Tidy.java
[Dune, Emma, Dom Casmurro, Neuromancer]
20/03/2026
[brazil, classic, scifi]
6 copies of Dune, 24 of Emma
price: R$12,90
price: R$12,90
replaceAll failed: java.lang.IndexOutOfBoundsException: No group 1
```

## Quatro ferramentas e uma armadilha

O `splitAsStream` cortou a lista bagunçada onde houvesse uma vírgula ou um ponto e vírgula, **com os espaços
em volta**, então os títulos saíram limpos; dividir só por `","` teria mantido os espaços e perdido o ponto e
vírgula. Numa substituição, `$1`, `$2` e `$3` representam os grupos, e a data foi reescrita de
ano-mês-dia para dia/mês/ano numa chamada. O `results()` de novo deu um stream, e o `distinct` e o `sorted`
fizeram o resto.

O `replaceAll` com uma função é a forma geral. **Para cada casamento ele chama a função com o `MatchResult` e
põe no lugar o que a função devolver**, então cada número da frase foi dobrado. Tudo o que puder ser calculado
a partir de um casamento pode ser a substituição: uma consulta, uma conversão, a chamada a outro método.

A armadilha são as três últimas linhas. **`$` numa string de substituição quer dizer um grupo**, então
`R$12,90` pediu o grupo 1, que o padrão não tem, e o `replaceAll` lançou. O `String.replace`, sem `All`,
recebe texto simples e não tem essa regra. Quando a substituição vem de dados, um preço, um nome, qualquer
coisa que um usuário digitou, o `Matcher.quoteReplacement` transforma cada `$` e `\` num literal. Uma
substituição que funciona com todo valor de teste e falha no primeiro preço de verdade com um cifrão é
exatamente como isso chega à produção.
