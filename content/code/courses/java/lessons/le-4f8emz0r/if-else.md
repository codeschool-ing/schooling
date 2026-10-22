---
title: `if`, `else` and the operators that decide
version: 1
---

A program that cannot choose does the same thing every time. **`if` runs a block only when a
condition is `true`**, and the condition must be a `boolean`: a comparison like `loans < limit`, a
method that answers yes or no, or several of those joined with `&&` (and), `||` (or) and `!` (not).
Make a directory for this lesson, `~/cond`, and save this as `Loans.java`, a library deciding whether
a member may borrow another book:

```schooling-example
{
  "language": "java",
  "file": "Loans.java",
  "parts": [
    {
      "code": "public class Loans {\n    static boolean hasOverdue(String member) {\n        System.out.println(\"  checked the overdue loans of \" + member);\n        return member.equals(\"Bruno\");\n    }",
      "note": "A method that **says when it runs**, so the output shows whether a condition called it. It answers `true` for Bruno only. Lesson 13 is about writing methods; here it is a witness."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        int loans = 3;\n        int limit = 3;\n        if (loans < limit) {\n            System.out.println(\"may borrow\");\n        } else if (loans == limit) {\n            System.out.println(\"at the limit\");\n        } else {\n            System.out.println(\"over the limit\");\n        }",
      "note": "**An `if` chain takes the first branch whose condition is `true` and skips the rest.** 3 is not below 3, 3 equals 3, so it printed `at the limit`, and the `else` was never looked at."
    },
    {
      "code": "\n        System.out.println(\"with &&:\");\n        if (loans < limit && hasOverdue(\"Ana\")) {\n            System.out.println(\"  refused\");\n        }",
      "note": "`&&` stops at the first `false`. `loans < limit` is `false`, so **`hasOverdue` was never called**: nothing was printed under `with &&:`."
    },
    {
      "code": "        System.out.println(\"with &:\");\n        if (loans < limit & hasOverdue(\"Ana\")) {\n            System.out.println(\"  refused\");\n        }",
      "note": "A single `&` evaluates both sides whatever the first gives, so this time the method ran and printed its line. The answer is the same `false`; only the work differs."
    },
    {
      "code": "\n        String word = loans == 1 ? \"loan\" : \"loans\";\n        System.out.println(loans + \" \" + word);",
      "note": "The **conditional operator**, `condition ? a : b`, is an `if` that produces a value. It chose `\"loans\"` because `loans` is not 1."
    },
    {
      "code": "\n        int fine = 0;\n        if (loans > limit)\n            fine = 5;\n            System.out.println(\"fine charged\");\n        System.out.println(\"fine \" + fine);\n    }\n}",
      "note": "**Without braces, an `if` controls exactly one statement**, the next one. The indentation suggests two, and the compiler ignores indentation: `fine charged` printed with a fine of 0."
    }
  ],
  "output": "at the limit\nwith &&:\nwith &:\n  checked the overdue loans of Ana\n3 loans\nfine charged\nfine 0\n"
}
```

## Short-circuit, and why it matters

`&&` and `||` are called **short-circuit** operators: each evaluates its right side only when the
left side has not already settled the answer. `false && anything` is `false`, and `true || anything`
is `true`, so the right side is skipped. That is a performance detail until the right side does
something, and then it is the whole point. The most common use is a guard:
`member != null && member.equals("Bruno")` never calls `equals` on a `null`, because the left side
stops it first. **Swap the two sides and the guard is gone.**

`&` and `|` on `boolean`s always evaluate both sides. They exist, and the transcript shows them
working; in a condition, the short-circuit pair is almost always what you mean.

## Always write the braces

The last block of the program is the bug that the braces prevent. The two indented lines look like
one block under the `if`, and **only the first belongs to it**. Nothing warned: the program compiled
and ran, and printed `fine charged` for a member with no fine. The common Java style guides require braces on
every `if`, even one whose body is a single line, so that adding a second line later cannot do this.

## A condition must be a `boolean`

In C, `if (x = 5)` assigns 5 to `x` and then treats 5 as true, and it is a famous bug. Java refuses
it at compile time:

```java
// Assign.java
public class Assign {
    public static void main(String[] args) {
        int loans = 3;
        if (loans = 5) {
            System.out.println("five");
        }
    }
}
```

```
ana@vm:~/cond$ javac Assign.java
Assign.java:5: error: incompatible types: int cannot be converted to boolean
        if (loans = 5) {
                  ^
1 error
```

`loans = 5` is an assignment, and its value is the `int` 5. **Java never treats a number as true or
false**, so the compiler stops at line 5 and puts a caret under the `=`. The comparison is `==`.
