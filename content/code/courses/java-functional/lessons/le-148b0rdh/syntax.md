---
title: The forms a lambda takes
version: 1
---

**A lambda is a parameter list, an arrow, and a body.** Every other rule is about how much of that
can be left out. This program writes the forms you will meet, one per line, each stored in a
variable whose type says what it takes and returns:

```schooling-example
{
  "language": "java",
  "file": "Shapes.java",
  "parts": [
    {
      "code": "// Shapes.java: the forms a lambda can take\nimport java.util.function.BiFunction;\nimport java.util.function.BinaryOperator;\nimport java.util.function.Function;\nimport java.util.function.Predicate;\n\npublic class Shapes {\n    public static void main(String[] args) {",
      "note": "The types on the left all come from `java.util.function`, which lesson 2 is about. For now, read each one as a description: what goes in, what comes out."
    },
    {
      "code": "        Runnable hello = () -> System.out.println(\"no parameters\");",
      "note": "No parameters: empty brackets, which cannot be left out."
    },
    {
      "code": "        Function<String, Integer> length = s -> s.length();",
      "note": "One parameter: the brackets are optional, and the type is inferred from `Function<String, Integer>`."
    },
    {
      "code": "        BinaryOperator<Integer> add = (a, b) -> a + b;",
      "note": "Two or more parameters need brackets. An expression body is returned without `return`."
    },
    {
      "code": "        BiFunction<String, Integer, String> repeat = (String s, Integer n) -> s.repeat(n);",
      "note": "Types may be written out, and then they must be written for every parameter."
    },
    {
      "code": "        Predicate<String> blank = (var s) -> s.isBlank();",
      "note": "`var` works as a parameter type too. It is there so an annotation can be put on a parameter without naming its type."
    },
    {
      "code": "        Function<Integer, String> describe = n -> {\n            if (n < 0) {\n                return \"negative\";\n            }\n            return n % 2 == 0 ? \"even\" : \"odd\";\n        };",
      "note": "A block body is ordinary Java between braces, with `return` where a value comes out and a semicolon after the closing brace, because the whole thing is one statement."
    },
    {
      "code": "\n        hello.run();\n        System.out.println(length.apply(\"lambda\"));\n        System.out.println(add.apply(2, 3));\n        System.out.println(repeat.apply(\"ab\", 3));\n        System.out.println(blank.test(\"   \"));\n        System.out.println(describe.apply(7) + \" \" + describe.apply(-2));\n    }\n}\n",
      "note": "Defining a lambda runs nothing. Each one runs when its interface's method is called: `run`, `apply` or `test`."
    }
  ],
  "output": "no parameters\n6\n5\nababab\ntrue\nodd negative"
}
```

Nothing in the program printed until the calls at the end. **Writing a lambda creates an object;
calling the interface's method runs the body**, as often as it is called. That gap between
defining and running is what makes the Stream API of lesson 6 work, and the reason lesson 9
can run the same lambda on four processors at once.

## The type comes from where it is written

A lambda has no type of its own. **It takes the type of the place it is written**, which the
specification calls its **target type**: the variable it is assigned to, the parameter it is passed
as, the value a method returns. With no target there is nothing to infer from:

```java
// NoTarget.java: two lambdas with nowhere to take a type from
public class NoTarget {
    public static void main(String[] args) {
        var twice = (Integer x) -> x * 2;
        Object task = () -> System.out.println("hi");
    }
}
```

```
ana@vm:~/fp/lambdas$ javac -d out NoTarget.java
NoTarget.java:4: error: cannot infer type for local variable twice
        var twice = (Integer x) -> x * 2;
            ^
  (lambda expression needs an explicit target-type)
NoTarget.java:5: error: incompatible types: Object is not a functional interface
        Object task = () -> System.out.println("hi");
                      ^
2 errors
```

`var` asks the compiler to take the type from the right-hand side, and the lambda asks to take its
type from the left: each waits for the other. `Object` is a type, but not one with a single method
to implement, so the lambda has nothing to become. Both errors say it in their own words, and both
have the same cure: **write the interface the lambda should be**.

## Short and long are the same lambda

| written | means |
|---|---|
| `s -> s.length()` | one parameter, its type inferred, the expression returned |
| `(s) -> s.length()` | the same, with optional brackets |
| `(String s) -> s.length()` | the same, with the type written |
| `(String s) -> { return s.length(); }` | the same, as a block |

Write the shortest form that stays readable. A block with one `return` in it is almost always the
expression form with more noise, and **a lambda longer than a few lines is a method that has not
been given a name yet**: lesson 3 shows how to pass a method itself, and that reads better than
twenty lines inside an argument list.
