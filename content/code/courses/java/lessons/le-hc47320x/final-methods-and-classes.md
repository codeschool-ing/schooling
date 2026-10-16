---
title: Final methods and final classes
version: 1
---

Lesson 20 introduces inheritance properly: a class can **extend** another, inherit its fields and
methods, and replace a method with its own version, which is called *overriding*. Two uses of `final`
exist to limit that, and they are easiest to see before inheritance is familiar, with only the line
`class Dvd extends Item` to read. In a new directory, `~/final2`:

```java
// Item.java
class Item {
    String title = "Untitled";

    final String label() {
        return "[" + title + "]";
    }
}
```

```java
// Dvd.java
class Dvd extends Item {
    String label() {
        return "DVD " + title;
    }
}
```

```
ana@vm:~/final2$ javac Dvd.java
Dvd.java:3: error: label() in Dvd cannot override label() in Item
    String label() {
           ^
  overridden method is final
1 error
```

**A `final` method cannot be overridden.** `Item` decided that every item's label has one form, and
no subclass may change it. That matters when other code in `Item` relies on `label()` behaving
exactly as written: a subclass that replaced it would change the behaviour of methods it never
touched.

## A class nobody may extend

`final` on a class goes further: **no class may extend it at all.**

```java
// Isbn.java
final class Isbn {
    final String value;

    Isbn(String value) {
        this.value = value;
    }
}
```

```java
// FakeIsbn.java
class FakeIsbn extends Isbn {
    FakeIsbn() {
        super("000");
    }
}
```

```
ana@vm:~/final2$ javac FakeIsbn.java
FakeIsbn.java:2: error: cannot inherit from final Isbn
class FakeIsbn extends Isbn {
                       ^
1 error
```

(`super("000")` calls `Isbn`'s constructor, which lesson 20 explains; the compiler refused the class
before it got that far.) The JDK does the same with classes you use every day:

```java
// MyString.java
class MyString extends String {
}
```

```
ana@vm:~/final2$ javac MyString.java
MyString.java:2: error: cannot inherit from final String
class MyString extends String {
                       ^
1 error
ana@vm:~/final2$ javap java.lang.String | head -2
Compiled from "String.java"
public final class java.lang.String implements java.io.Serializable, java.lang.Comparable<java.lang.String>, java.lang.CharSequence, java.lang.constant.Constable, java.lang.constant.ConstantDesc {
```

## Why `String` is final

Lesson 7 showed that a `String` never changes after it is made. That promise is what the rest of the
platform builds on: strings are keys in maps, names of classes and files, parts of security checks. A
subclass of `String` could add a method that changed its characters, and then a value checked once
could be different when used. **Making the class final is the only way to make the promise hold for
every `String` in every program**, because a promise a subclass can break is not a promise.

The cost is real: you cannot add your own methods to `String`, and anything you want to do to strings
goes in a static method of another class, like lesson 15's `Isbns`. For your own classes the usual
advice is to make a class final unless you designed it to be extended, and lesson 20 shows what a
class has to get right before it can safely be extended.
