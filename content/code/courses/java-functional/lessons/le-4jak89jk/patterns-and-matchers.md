---
title: Pattern and Matcher
version: 1
---

**A regular expression describes a set of strings, and `java.util.regex` checks whether a piece of text
belongs to it and which parts matched which piece.** `Pattern.compile` turns the expression into a
`Pattern`, once, and each `matcher(text)` gives a `Matcher` that applies it to one string. Here a pattern
reads the lines of a library's log:

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

## Reading the pattern

| piece | matches |
|---|---|
| `\d{4}` | exactly four digits |
| `[^"]+` | one or more characters that are not a double quote |
| `\w+` | one or more letters, digits or underscores |
| `(?<name>...)` | the same as `(...)`, and the part it matched can be asked for by `name` |

Between pieces, a bar means "or": `loan|return` matches either word. Inside a Java string every backslash
is written twice, so the `\d` of the pattern is `"\\d"` in the source; that is the only reason the line
looks noisier than the table. **The named groups are what make the pattern readable later**:
`m.group("title")` says what it wants, where `m.group(3)` would break the day somebody adds a group in
front of it.

The first two lines matched and came apart into their four fields. The third has `renew`, which the
pattern does not allow, and the fourth has no date, so both reported `no match` instead of producing
half a record. **A pattern is a definition of valid input**, and a line it does not match is a line the
program does not understand.

## `matches`, `find` and a stream of results

The last three lines show the difference that trips people up. **`matches` asks whether the whole text
fits the pattern**, and a sentence containing a date is not a date, so it said `false`. `find` asks
whether some part of the text fits, and there is one. `results()` goes further and gives a
`Stream<MatchResult>` of every match, in order, ready for the `map` and `toList` of lesson 7.

A `Pattern` is immutable and safe to share between threads, which is why it sits in a `static final`
field and is compiled once. A `Matcher` holds the state of one search and belongs to one thread.
`String.matches` and `String.replaceAll` compile their pattern again on every call, which is fine once
and wasteful in a loop over a million lines.
