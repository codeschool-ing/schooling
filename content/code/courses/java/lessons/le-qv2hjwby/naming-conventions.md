---
title: Names, and the conventions every Java file shares
version: 1
---

The compiler accepts almost any name made of letters, digits, `_` and `$`, as long as it does not
start with a digit and is not one of the language's reserved words, such as `class` or `int`. **What
it does not enforce, the community does**: Java code anywhere in the world names things the same
way, and a name written another way reads as a mistake to every colleague who opens the file. The
conventions are few, and each one tells the reader what kind of thing a name is before they read its
declaration.

| kind of name | convention | examples from this course |
|---|---|---|
| class, interface, enum, record | **PascalCase**: every word capitalised | `Hello`, `LoanDesk`, `StringBuilder` |
| method, variable, parameter | **camelCase**: first word lower case | `main`, `printReceipt`, `loansToday` |
| constant (`static final`) | **UPPER_SNAKE_CASE** | `MAX_LOANS`, `Integer.MAX_VALUE` |
| package | all lower case, words run together, reversed domain | `java.util`, `com.example.library` |

A short program that follows all of them, in `~/syntax`:

```java
// LoanDesk.java
public class LoanDesk {
    static final int MAX_LOANS = 3;

    public static void main(String[] args) {
        int loansToday = 2;
        String memberName = "Ana";
        printReceipt(memberName, loansToday);
    }

    static void printReceipt(String memberName, int loanCount) {
        System.out.println(memberName + " has " + loanCount + " of " + MAX_LOANS + " loans");
    }
}
```

```
ana@vm:~/syntax$ java LoanDesk.java
Ana has 2 of 3 loans
```

Read the names alone and the program's shape is already there. `LoanDesk` is a class because it is
capitalised. `MAX_LOANS` is a constant, a value fixed for the program's whole life, which lesson 16
explains through `final`. `printReceipt` is a method, and a verb, because it does something.
`memberName` and `loanCount` are variables, nouns, holding one value each. **Methods are named for
what they do, and variables for what they hold**: `printReceipt`, not `receipt`; `loanCount`, not
`count2`.

## The one naming rule the compiler does enforce

**A public class must be in a file with exactly its name**, plus `.java`. This is not style, and the
compiler says so. Copy `Hello.java` to another name and compile the copy:

```
ana@vm:~/syntax$ cp Hello.java Greeting.java && javac Greeting.java
Greeting.java:1: error: class Hello is public, should be declared in a file named Hello.java
public class Hello {
       ^
1 error
ana@vm:~/syntax$ rm Greeting.java
```

The class inside is still `Hello`, so `Greeting.java` is the wrong home for it. The rule exists so
that the compiler and the JVM can find a public class from its name alone, without reading every
file in a directory. Lesson 2's multi-file launch depended on it: `java Main.java` found
`Shout.java` because the class `Shout` could only be in that file. A file may hold other classes
that are not public, and lesson 14 comes back to what that means.

## Spaces, braces and line length

The layout rules are conventions too, and the ones used in this course are the common ones:

- four spaces of indentation per level, never tabs mixed with spaces;
- the opening brace at the end of the line that starts the block, the closing brace alone on its
  own line, lined up with that line's start;
- one statement per line, and lines short enough to read without scrolling sideways.

Teams write their rules down, and most build tools can check them. What matters is that **every file
in one project looks the same**, so that a difference in layout always means a difference in code.
