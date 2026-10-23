---
title: An annotation of your own, and the code that reads it
version: 1
---

Declaring an annotation is declaring a special kind of interface, with `@interface`. Two annotations
from the JDK go on it and decide most of what it can do: **`@Retention` says how long it lives**, as
section 03 showed, and **`@Target` says what it may be written on**: a class, a method, a field, a
parameter. This one marks fields that must not be blank, and carries a message:

```java
// NotBlank.java
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
public @interface NotBlank {
    String message() default "must not be blank";
}
```

`message()` looks like a method and acts as a setting. `default` gives it a value, so `@NotBlank` alone
is legal, and `@NotBlank(message = "...")` replaces it. The types such an element may have are few and
fixed: primitives, `String`, `Class`, enums, other annotations, and arrays of those, because the value
has to be written into the class file.

A class that uses it on two fields and leaves the third alone:

```java
// Member.java
public class Member {
    @NotBlank
    String name;

    @NotBlank(message = "an e-mail address is needed for reminders")
    String email;

    String phone;

    Member(String name, String email, String phone) {
        this.name = name;
        this.email = email;
        this.phone = phone;
    }
}
```

## The code that gives it a meaning

`@NotBlank` still means nothing. **The meaning is whatever the code that reads it does**, and this
validator is that code:

```schooling-example
{
  "language": "java",
  "file": "Validator.java",
  "parts": [
    {
      "code": "// Validator.java\nimport java.lang.reflect.Field;\nimport java.util.ArrayList;\nimport java.util.List;\n\npublic class Validator {\n    static List<String> check(Object o) throws IllegalAccessException {\n        List<String> problems = new ArrayList<>();",
      "note": "`check` takes any object at all and returns a list of what is wrong with it, empty when nothing is. **It knows nothing about `Member`**, and that is what makes it a validator rather than a method of one class."
    },
    {
      "code": "        for (Field f : o.getClass().getDeclaredFields()) {\n            NotBlank rule = f.getAnnotation(NotBlank.class);\n            if (rule == null) continue;",
      "note": "For each field the class declares, ask for its `@NotBlank`. `getAnnotation` returns the annotation, or `null` when the field has none, and a field without one is skipped: `phone` never gets past this line."
    },
    {
      "code": "            Object value = f.get(o);\n            if (value == null || value.toString().isBlank()) {\n                problems.add(f.getName() + \": \" + rule.message());\n            }\n        }\n        return problems;\n    }",
      "note": "`f.get(o)` reads the field's value from this object. Null or only spaces is a problem, reported with the field's name and the annotation's own `message()`, which is the default unless the field set another."
    },
    {
      "code": "\n    public static void main(String[] args) throws IllegalAccessException {\n        System.out.println(check(new Member(\"Ana\", \"ana@example.com\", null)));\n        System.out.println(check(new Member(\"  \", null, \"\")));\n    }\n}",
      "note": "Two members: one complete, one with a name of two spaces and no e-mail. The phone is empty in both and nobody minds, because nothing marked it."
    }
  ]
}
```

```
ana@vm:~/annot$ javac NotBlank.java Member.java Validator.java && java Validator
[]
[name: must not be blank, email: an e-mail address is needed for reminders]
```

`[]` for Ana, who has a name and an address. Two problems for the second member, each with its
message: the default for `name`, which was two spaces, and the field's own for `email`, which was
`null`. **The rule lives on the field and the checking lives in one place**, so a third class with
`@NotBlank` fields is validated with no new code. That is the shape of Jakarta Bean Validation, the
library `java-back` uses on the data a web service receives, at a fraction of its size.

`f.get(o)` worked here because `Validator` and `Member` are in the same package and the fields are
package-private. Reading a `private` field by reflection needs `f.setAccessible(true)` first, and lesson
40 shows a case where even that is refused.

## What `@Target` refuses

Written on a method, the annotation is refused before anything runs:

```java
// Misplaced.java
public class Misplaced {
    @NotBlank
    String title() {
        return "";
    }
}
```

```
ana@vm:~/annot$ javac Misplaced.java
Misplaced.java:3: error: annotation interface not applicable to this kind of declaration
    @NotBlank
    ^
1 error
```

The compiler cannot know what `@NotBlank` means, but it knows where its author allowed it to go, and a
method is not on the list. **An annotation's declaration is the only check it gets for free.**
Everything else, whether the value is blank, whether it is checked at all, belongs to the code that reads
it. A field marked with an annotation that no code reads is a field with a comment on it.
