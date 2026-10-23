---
title: Four genres and no fifth
version: 1
---

The first way people write a fixed set of values is as constants: `static final int FICTION = 0`,
`HISTORY = 1`, and so on, or as strings, `"fiction"` and `"history"`. Both compile, and both let a
method that takes a genre receive `7`, or `"histroy"`, without a word from the compiler. **An `enum`
is a type whose values are listed once and can never be anything else**, so the compiler checks
every genre in the program the way it checks every `int`.

Here is one, with what every enum gets for free, in `~/enums`:

```java
// Basics.java
enum Genre {
    FICTION, HISTORY, SCIENCE, POETRY
}

public class Basics {
    public static void main(String[] args) {
        for (Genre g : Genre.values()) {
            System.out.println(g.ordinal() + " " + g.name());
        }

        Genre picked = Genre.valueOf("HISTORY");
        System.out.println(picked == Genre.HISTORY);

        String floor = switch (picked) {
            case FICTION, POETRY -> "ground floor";
            case HISTORY, SCIENCE -> "first floor";
        };
        System.out.println(floor);

        System.out.println(Genre.valueOf("history"));
    }
}
```

```
ana@vm:~/enums$ javac Basics.java && java Basics
0 FICTION
1 HISTORY
2 SCIENCE
3 POETRY
true
first floor
Exception in thread "main" java.lang.IllegalArgumentException: No enum constant Genre.history
	at java.base/java.lang.Enum.valueOf(Enum.java:293)
	at Genre.valueOf(Basics.java:2)
	at Basics.main(Basics.java:21)
```

Line by line against the program:

- **`values()` returns every constant, in the order they are written**, and `ordinal()` is a
  constant's position in that order, from 0. `name()` is the constant's name exactly as written.
- **`valueOf("HISTORY")` turns a name back into the constant**, and the constant it returned is the
  same object as `Genre.HISTORY`, so `==` printed `true`. There is exactly one `HISTORY` object in a
  running program, which makes `==` the right comparison for enums, where lesson 7 warned against it
  for strings.
- **The `switch` names constants without the `Genre.` prefix**, and groups two to a case. Lesson 10
  showed the arrow form; with an enum it gains something, which the next program shows.
- **`valueOf` is exact.** `"history"` in lower case is not a name the enum has, and the program
  ended on an `IllegalArgumentException` saying so. Input from a person needs converting first, with
  `toUpperCase(Locale.ROOT)` from lesson 7, and a plan for text that is not a genre at all.

## An enum is a class

`javap` shows what the compiler made of four words:

```
ana@vm:~/enums$ javap Genre
Compiled from "Basics.java"
final class Genre extends java.lang.Enum<Genre> {
  public static final Genre FICTION;
  public static final Genre HISTORY;
  public static final Genre SCIENCE;
  public static final Genre POETRY;
  public static Genre[] values();
  public static Genre valueOf(java.lang.String);
  static {};
}
```

**`Genre` is a `final` class that extends `java.lang.Enum`, and each constant is a `public static
final` field holding one object of it.** `values()` and `valueOf` were written by the compiler, and
`static {}` is the class initialiser from lesson 27, which creates the four objects the first time
`Genre` is used. Nobody else can create a fifth: an enum's constructor is private whether you write
so or not, and `new Genre()` does not compile. That is the guarantee the whole type rests on.

## The `switch` that cannot forget

`Floors` uses the same enum, and its `switch` handles three of the four genres:

```java
// Floors.java
enum Genre {
    FICTION, HISTORY, SCIENCE, POETRY
}

public class Floors {
    static String floor(Genre g) {
        return switch (g) {
            case FICTION -> "ground floor";
            case HISTORY, SCIENCE -> "first floor";
        };
    }

    public static void main(String[] args) {
        System.out.println(floor(Genre.POETRY));
    }
}
```

```
ana@vm:~/enums/floors$ javac Floors.java
Floors.java:8: error: the switch expression does not cover all possible input values
        return switch (g) {
               ^
1 error
```

**A `switch` expression has to produce a value for every possible input, and the compiler knows
every possible `Genre`.** `POETRY` has no case, so it refuses the file. With strings or `int`
constants the compiler could not know, and the missing genre would be found by a reader at the
shelf. Add `POETRY` to a case, or add a fifth genre to the enum without updating this `switch`, and
the compiler tells you exactly where to look, once per `switch` in the program.

A `default ->` branch also satisfies the compiler, and it costs this check: a genre added next year
would fall into `default` silently. **Where every constant has a real answer, list them all and
leave `default` out.**
