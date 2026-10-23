---
title: Formatting and parsing
version: 1
---

**A date has one text form that every program understands, ISO 8601, `2026-12-28`, and it is what
`toString` gives and `parse` reads.** For people there are others, and a `DateTimeFormatter` turns a
date into any of them and back, either from a pattern of letters or from the conventions of a locale:

```java
// Formats.java: printing and parsing dates, and the pattern letter that lies once a year
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.format.FormatStyle;
import java.time.format.ResolverStyle;
import java.util.Locale;

public class Formats {
    public static void main(String[] args) {
        LocalDate date = LocalDate.of(2026, 12, 28);
        System.out.println("ISO:        " + date);
        System.out.println("dd/MM/uuuu: " + date.format(DateTimeFormatter.ofPattern("dd/MM/uuuu")));
        System.out.println("pt-BR long: " + date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG).withLocale(Locale.forLanguageTag("pt-BR"))));
        System.out.println("en-US long: " + date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG).withLocale(Locale.US)));
        System.out.println("dd/MM/YYYY: " + date.format(DateTimeFormatter.ofPattern("dd/MM/YYYY")));

        DateTimeFormatter smart = DateTimeFormatter.ofPattern("dd/MM/uuuu");
        DateTimeFormatter strict = smart.withResolverStyle(ResolverStyle.STRICT);
        for (String text : new String[] {"07/09/2026", "31/02/2026", "2026-09-07"}) {
            System.out.println(text + "  smart: " + parse(text, smart) + "  strict: " + parse(text, strict));
        }
    }

    static String parse(String text, DateTimeFormatter format) {
        try {
            return LocalDate.parse(text, format).toString();
        } catch (DateTimeParseException e) {
            return "refused";
        }
    }
}
```

```
ana@vm:~/fp/time$ java Formats.java
ISO:        2026-12-28
dd/MM/uuuu: 28/12/2026
pt-BR long: 28 de dezembro de 2026
en-US long: December 28, 2026
dd/MM/YYYY: 28/12/2027
07/09/2026  smart: 2026-09-07  strict: 2026-09-07
31/02/2026  smart: 2026-02-28  strict: refused
2026-09-07  smart: refused  strict: refused
```

## Patterns, locales and one bad letter

`dd/MM/uuuu` is day, month and year, and `MM` is month where `mm` would be minutes; the letters are case
sensitive and the table of them is in the `DateTimeFormatter` documentation. **A localised format is
usually the better choice for a person**, because it follows the reader's language without a pattern in
the code: the same date came out as `28 de dezembro de 2026` and `December 28, 2026`.

The fifth line printed **2027 for a date in December 2026**. `YYYY` is not the year: it is the
*week-based* year, the year a week belongs to under the week rules of the locale, and the last days of
December can belong to the first week of the next year. The pattern works for fifty-one weeks and
prints the wrong year for the last few days, which is how it reaches production. **The year is `uuuu`**
(or `yyyy`, the year of the era).

## Parsing is input

Text from a form or a file is input, and the two formatters disagreed on it. `07/09/2026` read the same
in both. **`31/02/2026` became 28 February with the default formatter**, which is called smart and
adjusts a day that is too large for its month; `withResolverStyle(ResolverStyle.STRICT)` refused it.
Text in another format was refused by both; behind each `refused` is a `DateTimeParseException`, whose
message says at which character the text stopped matching.

A strict formatter is the one for input, so that a date nobody wrote is not quietly turned into one
somebody did. Strict is also why the pattern says `uuuu`: in strict mode `yyyy` is a year of an era, and
without an era in the pattern it cannot be resolved into a date at all.
