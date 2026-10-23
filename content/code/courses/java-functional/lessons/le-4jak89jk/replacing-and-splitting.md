---
title: Replacing and splitting
version: 1
---

**Matching is half of what patterns are used for; the other half is changing text.** A pattern can be the
separator a string is split on, the part of a string that is replaced, or the place a function is applied:

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

## Four tools and one trap

`splitAsStream` cut the messy list wherever a comma or a semicolon stood, **with any spaces around it**,
so the titles came out clean; splitting on `","` alone would have kept the spaces and missed the
semicolon. In a replacement, `$1`, `$2` and `$3` stand for the groups, and the date was rewritten from
year-month-day to day/month/year in one call. `results()` again gave a stream, and `distinct` and `sorted`
did the rest.

`replaceAll` with a function is the general form. **For each match it calls the function with the
`MatchResult` and puts in whatever the function returns**, so every number in the sentence was doubled.
Anything that can be computed from a match can be the replacement: a lookup, a conversion, a call to
another method.

The trap is the last three lines. **`$` in a replacement string means a group**, so `R$12,90` asked for
group 1, which the pattern does not have, and `replaceAll` threw. `String.replace`, with no `All`, takes
plain text and has no such rule. When the replacement comes from data, a price, a name, anything a user
typed, `Matcher.quoteReplacement` turns every `$` and `\` into a literal one. A replacement that works on
every test value and fails on the first real price with a dollar sign in it is exactly how this reaches
production.
