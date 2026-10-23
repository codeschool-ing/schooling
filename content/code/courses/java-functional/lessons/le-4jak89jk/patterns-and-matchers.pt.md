---
title: Pattern e Matcher
version: 1
---

**Uma expressão regular descreve um conjunto de strings, e o `java.util.regex` confere se um trecho de
texto pertence a ele e que partes casaram com que pedaço.** O `Pattern.compile` transforma a expressão num
`Pattern`, uma vez, e cada `matcher(text)` dá um `Matcher` que a aplica a uma string. Aqui um padrão lê as
linhas do log de uma biblioteca:

```java
// Lines.java: reading the parts of a log line with a pattern and named groups
import java.util.List;
import java.util.regex.MatchResult;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Lines {
    static final Pattern ENTRY = Pattern.compile(
            "(?<date>\\d{4}-\\d{2}-\\d{2}) (?<action>loan|return) \"(?<title>[^\"]+)\" (?<reader>\\w+)");

    public static void main(String[] args) {
        List<String> log = List.of(
                "2026-03-07 loan \"Dune\" ana",
                "2026-03-08 return \"Dom Casmurro\" bia",
                "2026-03-08 renew \"Emma\" ana",
                "loan \"Dune\" ana");
        for (String line : log) {
            Matcher m = ENTRY.matcher(line);
            if (m.matches()) {
                System.out.printf("%-6s  %-13s by %s on %s%n", m.group("action"), m.group("title"), m.group("reader"), m.group("date"));
            } else {
                System.out.println("no match: " + line);
            }
        }

        Pattern date = Pattern.compile("\\d{4}-\\d{2}-\\d{2}");
        String note = "due 2026-03-20, renewed to 2026-04-03";
        System.out.println("matches: " + date.matcher(note).matches());
        System.out.println("find:    " + date.matcher(note).find());
        System.out.println("results: " + date.matcher(note).results().map(MatchResult::group).toList());
    }
}
```

```
ana@vm:~/fp/regex$ java Lines.java
loan    Dune          by ana on 2026-03-07
return  Dom Casmurro  by bia on 2026-03-08
no match: 2026-03-08 renew "Emma" ana
no match: loan "Dune" ana
matches: false
find:    true
results: [2026-03-20, 2026-04-03]
```

## Lendo o padrão

| pedaço | casa com |
|---|---|
| `\d{4}` | exatamente quatro dígitos |
| `[^"]+` | um ou mais caracteres que não são aspas duplas |
| `\w+` | uma ou mais letras, dígitos ou sublinhados |
| `(?<name>...)` | o mesmo que `(...)`, e a parte que casou pode ser pedida por `name` |

Entre pedaços, uma barra quer dizer "ou": `loan|return` casa com qualquer das duas palavras. Dentro de uma
string Java toda barra invertida é escrita duas vezes, então o `\d` do padrão é `"\\d"` no código; esse é o
único motivo de a linha parecer mais carregada que a tabela. **Os grupos nomeados são o que deixa o padrão
legível depois**: `m.group("title")` diz o que quer, onde `m.group(3)` quebraria no dia em que alguém
acrescentasse um grupo antes dele.

As duas primeiras linhas casaram e se separaram nos seus quatro campos. A terceira tem `renew`, que o padrão
não permite, e a quarta não tem data, então as duas informaram `no match` em vez de produzir meio registro.
**Um padrão é uma definição de entrada válida**, e uma linha com que ele não casa é uma linha que o programa
não entende.

## `matches`, `find` e um stream de resultados

As três últimas linhas mostram a diferença que confunde. **O `matches` pergunta se o texto inteiro cabe no
padrão**, e uma frase que contém uma data não é uma data, então ele disse `false`. O `find` pergunta se
alguma parte do texto cabe, e há uma. O `results()` vai além e dá um `Stream<MatchResult>` de todos os
casamentos, em ordem, pronto para o `map` e o `toList` da aula 7.

Um `Pattern` é imutável e seguro para compartilhar entre threads, e é por isso que ele fica num campo
`static final` e é compilado uma vez. Um `Matcher` guarda o estado de uma busca e pertence a uma thread. O
`String.matches` e o `String.replaceAll` compilam o padrão de novo a cada chamada, o que não faz mal uma vez
e é desperdício num laço sobre um milhão de linhas.
