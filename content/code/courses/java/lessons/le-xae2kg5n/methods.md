---
title: The methods you will use every day
version: 1
---

`String` has around seventy public methods, and a dozen of them do nearly all the work. The program
below cleans and takes apart one line of a library's export file, `author;title;year`, which is the
kind of string a program meets most:

```java
// Methods.java
import java.util.Arrays;
import java.util.Locale;

public class Methods {
    public static void main(String[] args) {
        String line = "  Machado de Assis;Dom Casmurro;1899  ";
        String s = line.strip();
        System.out.println("[" + s + "]");
        System.out.println(s.length());
        System.out.println(s.charAt(0));
        System.out.println(s.indexOf(';'));
        System.out.println(s.substring(0, s.indexOf(';')));
        System.out.println(Arrays.toString(s.split(";")));
        System.out.println(s.replace(';', '|'));
        System.out.println(s.contains("Casmurro"));
        System.out.println(s.toUpperCase(Locale.ROOT));
        System.out.println("apple".compareTo("banana"));
        System.out.println("Zebra".compareTo("apple"));
    }
}
```

```
ana@vm:~/strings$ java Methods.java
[Machado de Assis;Dom Casmurro;1899]
34
M
16
Machado de Assis
[Machado de Assis, Dom Casmurro, 1899]
Machado de Assis|Dom Casmurro|1899
true
MACHADO DE ASSIS;DOM CASMURRO;1899
-1
-7
```

Line by line, what each call answered:

| call | printed | what it tells you |
|---|---|---|
| `strip()` | the line without its outer spaces | the brackets show both ends are clean |
| `length()` | `34` | how many `char`s: 34 after stripping |
| `charAt(0)` | `M` | **positions start at 0**, so the last is `length() - 1` |
| `indexOf(';')` | `16` | the first position of `;`, or `-1` when there is none |
| `substring(0, 16)` | `Machado de Assis` | from the first index **up to but not including** the second |
| `split(";")` | three pieces | an array, which lesson 9 is about |
| `replace`, `;` for a bar | the line with bars | every occurrence, not only the first |
| `contains("Casmurro")` | `true` | a yes or no, where `indexOf` gives a position |
| `toUpperCase(Locale.ROOT)` | capitals | a new string, as section 02 showed |
| `compareTo` | `-1`, then `-7` | negative, zero or positive, for sorting |

Two of those answers trip people. `substring(0, 16)` stops **before** index 16, so the end index is
the position of the `;` itself, and `indexOf` is exactly the number to pass. And `compareTo` is not
alphabetical order as a person means it. `"apple"` before `"banana"` gave `-1`, the distance from `a`
to `b`. But `"Zebra"` before `"apple"` gave `-7`, a negative number, so **`Zebra` sorts first**:
every capital letter has a smaller code than every small one.

`strip()` is the modern spelling of `trim()`. Both remove spaces from the ends; `strip()` also knows
the Unicode spaces that `trim()`, older than Unicode's growth, does not.

## A `char` is not always a character

Two methods in that table, `length()` and `toUpperCase`, answer something subtler than their names
suggest, and Portuguese text is where it shows:

```schooling-example
{
  "language": "java",
  "file": "Chars.java",
  "parts": [
    {
      "code": "import java.util.Locale;\n\npublic class Chars {\n    public static void main(String[] args) {\n        String word = \"ação\";\n        System.out.println(word.length());",
      "note": "**`length()` counts `char`s**, and each of these four letters is one `char`, accents included. Printed: `4`."
    },
    {
      "code": "        String thumb = \"\\uD83D\\uDC4D\";\n        System.out.println(thumb.length());\n        System.out.println(thumb.codePointCount(0, thumb.length()));",
      "note": "A thumbs-up emoji, written as its two escape codes. **One symbol, two `char`s**: `length()` says `2` and `codePointCount` says `1`. A `char` is 16 bits, and a character outside the first 65,536 needs two of them."
    },
    {
      "code": "\n        System.out.println(\"title\".toUpperCase(Locale.ROOT));\n        System.out.println(\"title\".toUpperCase(Locale.forLanguageTag(\"tr\")));\n        System.out.println(\"title\".toUpperCase(Locale.forLanguageTag(\"tr\")).equals(\"TITLE\"));\n    }\n}",
      "note": "**Upper case depends on the language.** In Turkish a dotted `i` becomes `İ`, so `\"title\"` becomes `TİTLE`, and a program comparing it with `\"TITLE\"` gets `false`. `Locale.ROOT` asks for no language at all, which is what code comparing identifiers wants."
    }
  ],
  "output": "4\n2\n1\nTITLE\nTİTLE\nfalse\n"
}
```

**`length()` is right for every letter of Portuguese**, accents included, because each fits in
one `char`. It is wrong for emoji and a few rare scripts, and the fix is `codePointCount` when you
need to count what a person sees. Upper case is the more common trap. A program running on a
machine set to Turkish, with a plain `toUpperCase()` and no argument, uses that machine's language,
and a check like `command.toUpperCase().equals("TITLE")` fails there and nowhere else. **Pass
`Locale.ROOT` when the text is an identifier**, and the user's own locale when it is a sentence
somebody will read.
