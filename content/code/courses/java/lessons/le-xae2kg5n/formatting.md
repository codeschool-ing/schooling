---
title: Formatting numbers and text
version: 1
---

Gluing values together with `+` gives you no say over how they look: `12.5` prints as `12.5` when
a fine should read `12.50`, and a million prints as `1234567`. **A format string describes the
line once, with placeholders, and the values fill it in.** Java's comes from C's `printf`, and it
appears in three spellings that all take the same placeholders:
`String.format(...)`, `"...".formatted(...)` and `System.out.printf(...)`, which prints instead of
returning.

```java
// Format.java
import java.util.Locale;

public class Format {
    public static void main(String[] args) {
        String title = "Dom Casmurro";
        int copies = 3;
        double fine = 12.5;
        long readers = 1234567;

        System.out.println(String.format("%s: %d copies", title, copies));
        System.out.println("Fine: %.2f".formatted(fine));
        System.out.println("[%10s] [%-10s]".formatted("right", "left"));
        System.out.println("[%5d] [%05d]".formatted(42, 42));
        System.out.println("%,d readers".formatted(readers));
        System.out.printf("%s%n", "printf ends its own line with %n");

        Locale br = Locale.forLanguageTag("pt-BR");
        System.out.println(String.format(br, "%,.2f", 1234.5));
        System.out.println(String.format(Locale.ROOT, "%,.2f", 1234.5));
        System.out.println(String.format("%d copies", "three"));
    }
}
```

```
ana@vm:~/strings$ java Format.java; echo $?
Dom Casmurro: 3 copies
Fine: 12.50
[     right] [left      ]
[   42] [00042]
1,234,567 readers
printf ends its own line with %n
1.234,50
1,234.50
Exception in thread "main" java.util.IllegalFormatConversionException: d != java.lang.String
	at java.base/java.util.Formatter$FormatSpecifier.failConversion(Formatter.java:4662)
	at java.base/java.util.Formatter$FormatSpecifier.printInteger(Formatter.java:3200)
	at java.base/java.util.Formatter$FormatSpecifier.print(Formatter.java:3155)
	at java.base/java.util.Formatter.format(Formatter.java:2761)
	at java.base/java.util.Formatter.format(Formatter.java:2698)
	at java.base/java.lang.String.format(String.java:4455)
	at Format.main(Format.java:21)
1
```

Each placeholder starts with `%` and ends with a letter saying what kind of value goes there.
Between the two go the options:

| placeholder | value | printed | what it does |
|---|---|---|---|
| `%s` | `"Dom Casmurro"` | `Dom Casmurro` | any value, as text |
| `%d` | `3` | `3` | a whole number |
| `%.2f` | `12.5` | `12.50` | a decimal, exactly two places after the point |
| `%10s`, `%-10s` | `"right"`, `"left"` | padded to 10 | a width; `-` pads on the right instead |
| `%05d` | `42` | `00042` | a width filled with zeros |
| `%,d` | `1234567` | `1,234,567` | groups of thousands |
| `%n` | none | a line break | the line ending of the system it runs on |

The sixth line shows a detail worth having seen once. `%n` inside the **format** ends the line, but
the text `"printf ends its own line with %n"` was an **argument**, put in by `%s`, and an argument is
never read as a format. It printed as written.

## The locale decides the separators

`1.234,50` and `1,234.50` are the same number written for two audiences. In Brazil the comma marks
decimals and the point groups thousands, and in English it is the other way round. **Pass a
`Locale` as the first argument and the format follows that country's rules**: `pt-BR` gave the
Brazilian form. Without one, `String.format` uses the machine's default, and here that is English,
because the lab runs with `LANG=C.UTF-8`.

The rule is the one section 03 gave for upper case. Text a person reads takes the reader's locale;
text another program reads, a CSV file or a log line, takes `Locale.ROOT`, so the number is written
the same on every machine. A file written in `pt-BR` and read back by a program expecting points is
the classic bug of a Brazilian spreadsheet export.

## A wrong placeholder fails when it runs

The last call asked `%d` to print the string `"three"`. **The compiler accepted it**, because the
format is only a string to the compiler, and the program failed when the line ran:
`IllegalFormatConversionException: d != java.lang.String`, a `d` placeholder handed a `String`. The
exit status was 1, and everything before that line had already been printed.

That is the first stack trace in this course, and it reads from the top. The first line names the
exception and its message. The lines that follow are the calls that were in progress, the most
recent first, and **the first line that names your own code is where to look**:
`Format.main(Format.java:21)`, line 21 of the file, the `String.format` with `"three"`. The lines
above it are inside the JDK and are not where the mistake is. Lesson 36 reads stack traces in full.
