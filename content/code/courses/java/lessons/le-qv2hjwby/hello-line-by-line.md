---
title: The first program, line by line
version: 1
---

Lesson 1 ran `Hello.java` without reading it. It is five lines, and four of them are ceremony that a
newcomer is tempted to copy without looking. **Each of those lines is a rule of the language**, and
every file you write in this course follows the same rules. Here it is again, in a directory for
this lesson, `~/syntax`:

```schooling-example
{
  "language": "java",
  "file": "Hello.java",
  "parts": [
    {
      "code": "public class Hello {",
      "note": "**Every line of Java code lives inside a class.** `class Hello` declares one, `public` lets code anywhere use it, and the braces hold everything that belongs to it. A public class must sit in a file named after it, `Hello.java`, and section 03 shows the error when it does not."
    },
    {
      "code": "    public static void main(String[] args) {",
      "note": "**The entry point, and every word of it is required.** `java Hello` looks for a method with exactly this shape: `public` so the launcher may call it, `static` so it runs without an object (lesson 15), `void` because it returns nothing, and `String[] args` for the command line, as lesson 2 used."
    },
    {
      "code": "        System.out.println(\"Hello, Java\");",
      "note": "**One statement, ended by a semicolon.** `System` is a class from the library, `out` is its field for standard output, and `println` prints a line. The dots walk from one to the next, and the text in double quotes is a `String`."
    },
    {
      "code": "    }\n}",
      "note": "**Two closing braces, the method's and the class's.** The indentation is for people: four spaces per level is the common style, and the compiler would accept the whole file on one line."
    }
  ]
}
```

```
ana@vm:~/syntax$ java Hello.java
Hello, Java
```

## Statements, blocks and the semicolon

Java is written in **statements**, and a statement ends with a semicolon, not with the end of the
line. Braces group statements into a **block**: the body of a method, of a class, and in lessons 10 and 11 of an
`if` or a loop. The compiler reads the file as a stream of symbols, so line breaks and indentation
mean nothing to it. That freedom has a price, which is that a missing semicolon is reported
somewhere a person would not look first:

```java
// Oops.java
public class Oops {
    public static void main(String[] args) {
        System.out.println("one")
        System.out.println("two");
    }
}
```

```
ana@vm:~/syntax$ javac Oops.java; echo $?
Oops.java:4: error: ';' expected
        System.out.println("one")
                                 ^
1 error
1
ana@vm:~/syntax$ ls
Hello.java
Oops.java
```

**The error points at the end of line 4, where the semicolon should have been**, and the caret `^`
sits just after the closing parenthesis. `javac` read on into line 5 and only then understood that
line 4 had not ended, so it reports the place it expected the `;`. When a message says `';'
expected`, look at the end of the line it names, and if that line looks right, at the line above.
The exit status was 1, and `ls` shows no `Oops.class`: **a file with one compile error produces no
class at all**.

## Case matters, everywhere

Java tells `System` from `system`, `Hello` from `hello` and `main` from `Main`. Change one letter of
the working program and the compiler stops recognising the name:

```
ana@vm:~/syntax$ mkdir -p case && sed 's/System.out/system.out/' Hello.java > case/Hello.java
ana@vm:~/syntax$ javac case/Hello.java
case/Hello.java:3: error: package system does not exist
        system.out.println("Hello, Java");
              ^
1 error
```

`system.out` did not mean a misspelled class to the compiler. A lowercase name followed by a dot
could be a **package**, a group of classes that lesson 18 introduces, so it looked for a package
called `system`, found none, and said so. The message is accurate and unhelpful at the same time,
which makes it worth knowing: **`package … does not exist` on a line you did not mean to have a
package in usually means a capital letter went missing**.
