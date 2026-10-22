---
title: From text to a number, and back
version: 1
---

Everything that comes into a program from outside arrives as text: the command line, a file, a form
on a web page. `args[0]` holding `"21"` is a `String` of two characters, not the number 21, and no
cast turns one into the other, because a cast converts between number types and a `String` is not
one. **The conversion is a method call, and it can fail**, because most strings are not numbers.

```java
// Copies.java
public class Copies {
    public static void main(String[] args) {
        int copies = Integer.parseInt(args[0]);
        System.out.println(copies * 2);
    }
}
```

```
ana@vm:~/convert$ javac Copies.java Price.java
ana@vm:~/convert$ java Copies 21
42
ana@vm:~/convert$ java Copies "21 "
Exception in thread "main" java.lang.NumberFormatException: For input string: "21 "
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:565)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at Copies.main(Copies.java:4)
ana@vm:~/convert$ java Copies twenty; echo $?
Exception in thread "main" java.lang.NumberFormatException: For input string: "twenty"
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:565)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at Copies.main(Copies.java:4)
1
```

`Integer.parseInt` read `"21"` and returned the `int` 21. Given anything else, it threw a
`NumberFormatException` with the exact text in quotes, which is worth reading closely: the second run
failed on `"21 "`, and the only difference is a trailing space you could not see on the command line.
**`parseInt` accepts digits and an optional sign, and nothing else, not even a space.** The stack
trace's last line names the line of your code that asked, `Copies.java:4`, and the lines above it are
inside the JDK.

## Decimals, and the comma

`Double.parseDouble` is the same for a `double`, with two differences you can see here:

```java
// Price.java
public class Price {
    public static void main(String[] args) {
        double price = Double.parseDouble(args[0]);
        System.out.println(price * 2);
        String text = String.valueOf(price);
        System.out.println(text + 1);
    }
}
```

```
ana@vm:~/convert$ java Price 39.90
79.8
39.91
ana@vm:~/convert$ java Price " 39.90 "
79.8
39.91
ana@vm:~/convert$ java Price 39,90
Exception in thread "main" java.lang.NumberFormatException: For input string: "39,90"
	at java.base/jdk.internal.math.FloatingDecimal.check(FloatingDecimal.java:2324)
	at java.base/jdk.internal.math.FloatingDecimal.readJavaFormatString(FloatingDecimal.java:1969)
	at java.base/jdk.internal.math.FloatingDecimal.parseDouble(FloatingDecimal.java:110)
	at java.base/java.lang.Double.parseDouble(Double.java:971)
	at Price.main(Price.java:4)
```

It accepted `" 39.90 "` with spaces round it, where `parseInt` refused `"21 "`: the two methods were
written to different rules, and the habit to take from that is to call `strip()` on input before
parsing it, which lesson 7 shows. And it refused `39,90`. **Java's parsing methods always read a
point as the decimal separator**, whatever language the computer is set to. A Brazilian user typing a
price with a comma, as they would on any form in Portuguese, gets an exception, and lesson 7 shows how
formatting and parsing for a locale are done.

The other direction is `String.valueOf`, or joining with `+` to a `String`. `String.valueOf(39.9)` is
`"39.9"`, and `text + 1` joined a `1` to it as text, `39.91`, which is the section 04 rule again: once
one side is a `String`, `+` means joining.

| from | to | how | when it fails |
|---|---|---|---|
| `String` | `int` | `Integer.parseInt(s)` | not digits, a space, too large: `NumberFormatException` |
| `String` | `long` | `Long.parseLong(s)` | the same |
| `String` | `double` | `Double.parseDouble(s)` | not a number, a comma: `NumberFormatException` |
| any value | `String` | `String.valueOf(x)` or `"" + x` | never |
