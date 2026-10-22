---
title: Scope, or where a name can be used
version: 1
---

The **scope** of a variable is the part of the program where its name means something. For a local
variable the rule is short: **it is in scope from its declaration to the closing brace of the block
that contains it.** Not the method, the block, and the braces of an `if` or a loop make a block. The
rule is what lets two methods use the same name for two different things without any trouble.

## A name declared inside a block ends with it

```java
// Blocks.java
public class Blocks {
    public static void main(String[] args) {
        int copies = 4;
        if (copies > 3) {
            int extra = copies - 3;
            System.out.println("extra copies: " + extra);
        }
        System.out.println(extra);
    }
}
```

```
ana@vm:~/scope$ javac Blocks.java
Blocks.java:9: error: cannot find symbol
        System.out.println(extra);
                           ^
  symbol:   variable extra
  location: class Blocks
1 error
```

`extra` was declared inside the `if`'s braces, so its scope ended at the `}` on line 8. On line 9 the
name means nothing, and `javac` says `cannot find symbol`: it looked for anything called `extra`
that could be seen from that line and found none. The fix is to declare `extra` before the `if` if
it is needed after it, and to leave it inside if it is not, which here it is not. **A variable
declared in the narrowest block that needs it cannot be misused outside that block.**

## Two locals with one name, in one method

Some languages let an inner block declare a variable with the same name as one outside it, hiding
the outer one until the block ends. **Java refuses**, for local variables:

```java
// Twice.java
public class Twice {
    public static void main(String[] args) {
        int total = 10;
        for (int i = 0; i < 2; i++) {
            int total = i;
            System.out.println(total);
        }
    }
}
```

```
ana@vm:~/scope$ javac Twice.java
Twice.java:6: error: variable total is already defined in method main(String[])
            int total = i;
                ^
1 error
```

The loop body is a block inside `main`, and `main` already has a `total` in scope there. Declaring a
second one would make every later `total` in the loop ambiguous to a reader, so the compiler stops
it. The `for` loop is lesson 11's subject; here only its braces matter.

## A local can hide a field

The rule above is about two locals. A local **can** have the same name as a field, and from its
declaration on, the plain name means the local:

```java
// Shadow.java
public class Shadow {
    static String name = "the library";

    public static void main(String[] args) {
        System.out.println(name);
        String name = "Ana";
        System.out.println(name);
        System.out.println(Shadow.name);
    }
}
```

```
ana@vm:~/scope$ java Shadow.java
the library
Ana
the library
```

The first `println` ran before the local `name` existed, so `name` meant the field, `"the library"`.
From line 7 on, `name` means the local, `"Ana"`. The field was still there, unchanged, and
`Shadow.name` reached it by naming its class. This is called **shadowing**. It is legal and it is a
common source of confusion, with one place where it is the normal style: a constructor whose
parameters have the same names as the fields they fill, which lesson 13 writes with `this.name =
name`.
