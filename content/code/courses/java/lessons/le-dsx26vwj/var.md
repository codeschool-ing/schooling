---
title: `var`, and where the type still is
version: 1
---

Since Java 10, a local variable can be declared with `var` instead of its type, and the compiler
works the type out from the value on the right. It is easy to read that as Java turning into a
language where variables have no type. **It is the opposite: the type is fixed exactly as before**,
only the compiler writes it instead of you. `jshell` shows what it chose, using the lines in
`vars.jsh`:

```
ana@vm:~/types$ cat vars.jsh
var title = "Dom Casmurro"
var year = 1899
var price = 39.90
var pages = 256L
var initial = 'D'
/vars
/exit
ana@vm:~/types$ jshell --feedback normal < vars.jsh
|  Welcome to JShell -- Version 25.0.4.1
|  For an introduction type: /help intro

jshell> title ==> "Dom Casmurro"

jshell> year ==> 1899

jshell> price ==> 39.9

jshell> pages ==> 256

jshell> initial ==> 'D'

jshell> |    String title = "Dom Casmurro"
|    int year = 1899
|    double price = 39.9
|    long pages = 256
|    char initial = 'D'

jshell> |  Goodbye
```

`/vars` lists every variable with the type the compiler inferred, and each one follows the literal
rules of section 02. `"Dom Casmurro"` is a `String`, `1899` an `int`, `39.90` a `double`, `256L` a
`long` because of its suffix, and `'D'` a `char` because of its single quotes. Write `var pages =
256` and `pages` is an `int`, not a `long`, whatever you had in mind.

## Three things `var` refuses

```java
// VarMistakes.java
public class VarMistakes {
    public static void main(String[] args) {
        var title;
        var author = null;
        var year = 1899;
        year = "nineteenth century";
    }
}
```

```
ana@vm:~/types$ javac VarMistakes.java
VarMistakes.java:4: error: cannot infer type for local variable title
        var title;
            ^
  (cannot use 'var' on variable without initializer)
VarMistakes.java:5: error: cannot infer type for local variable author
        var author = null;
            ^
  (variable initializer is 'null')
VarMistakes.java:7: error: incompatible types: String cannot be converted to int
        year = "nineteenth century";
               ^
3 errors
```

All three come from the same fact, that **the type is decided once, at the declaration, from the
value given there**:

1. `var title;` gives the compiler no value to look at, so there is nothing to infer from.
2. `var author = null;` gives it a value with no type of its own. `null` fits any object type, so
   it says nothing about which one was meant.
3. `year = "nineteenth century";` is the important one. `year` became an `int` on line 6, and an
   `int` cannot hold a `String` on line 7 or anywhere else. **`var` does not make a variable that
   changes type**, and this is the same error a variable declared `int year` would give.

`var` works only for local variables, the ones inside a method. A field of a class, a method's
parameters and its return type are always written out, because those are what other code reads.

## When it helps, and when it hides

`var` earns its place when the type is already on the screen, and long:

```java
var members = new java.util.ArrayList<String>();
```

`ArrayList<String>` is written once, on the right, instead of twice. It costs you when the right-hand
side does not show the type, as in `var total = calculate();`. The reader has to find `calculate`
to know whether `total` is an `int`, a `long` or a `double`, and section 02 showed that the
difference matters at two billion. **Use `var` when the type is obvious from the line, and write
the type when it is not.** This course writes types out in most places, because a course is read by
people learning what the types are.
