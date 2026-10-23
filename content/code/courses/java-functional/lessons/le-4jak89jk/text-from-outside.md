---
title: Text from outside
version: 1
---

**A search box that compiles what the user typed as a pattern has handed the user a programming
language.** What they type may be a pattern that means something they did not intend, a pattern that does
not compile, or a pattern like the third of the last section. The fix is one method, `Pattern.quote`,
which turns any string into a pattern that matches exactly that string:

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

## Three terms

`java` found the same book both ways: it has no special characters. **`C++` as a pattern found three
books, two of them wrong**: `+` is a quantifier, so `C++` means one or more `C`s, possessively, and with
`CASE_INSENSITIVE` it found the `c` in "Effective Java" and the `C` in the other title. Nothing failed,
and the results were simply wrong. Quoted, it found the one book with `C++` in its title.

`*java` was refused as a pattern with a `PatternSyntaxException`: a `*` must follow something to repeat.
A search page that shows that message has told the user how it works inside; one that does not catch it
fails with an error page. Quoted, it is a search for the text `*java`, which no title contains.

| when the pattern comes from | do |
|---|---|
| the code | write it so each piece matches one way, and compile it once |
| a user, who means plain text | `Pattern.quote(term)`, or `String.contains` and no pattern at all |
| a user, who really writes patterns | limit the length of the text, and build a limit on the time |

The last row is rare and hard. Java's `Matcher` has no timeout, and interrupting its thread does not stop
it, so a program that must accept patterns from strangers has to build its own limit. It also limits how long
the text may be, since the cost of the worst patterns grows with the length of the text. **For almost every program the answer
is the middle row.** A search term is text, and `quote` keeps it text.
