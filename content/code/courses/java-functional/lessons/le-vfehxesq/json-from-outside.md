---
title: JSON from outside
version: 1
---

**JSON from another program is input, and input is whatever its author sent.** A field can be missing,
an extra one can arrive, a number can come as words, and the text can stop halfway. The program below
reads five such inputs with two mappers: the default one of the last section, and one told to refuse
more. Save it as `src/main/java/com/example/catalogue/Input.java`, next to `App`:

```java
// src/main/java/com/example/catalogue/Input.java
package com.example.catalogue;

import tools.jackson.core.JacksonException;
import tools.jackson.databind.DeserializationFeature;
import tools.jackson.databind.json.JsonMapper;

public class Input {
    public static void main(String[] args) {
        JsonMapper lenient = JsonMapper.builder().build();
        JsonMapper strict = JsonMapper.builder()
                .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
                .enable(DeserializationFeature.FAIL_ON_MISSING_CREATOR_PROPERTIES)
                .build();
        String[] inputs = {
            "{\"title\":\"Dune\",\"author\":\"Frank Herbert\",\"year\":1965}",
            "{\"title\":\"Dune\",\"author\":\"Frank Herbert\",\"year\":1965,\"isbn\":\"0441013597\"}",
            "{\"title\":\"Dune\"}",
            "{\"title\":\"Dune\",\"author\":\"Frank Herbert\",\"year\":\"nineteen sixty-five\"}",
            "{\"title\":\"Dune\",",
        };
        for (String in : inputs) {
            System.out.println(in);
            System.out.println("  lenient: " + read(lenient, in));
            System.out.println("  strict:  " + read(strict, in));
        }
    }

    static String read(JsonMapper mapper, String json) {
        try {
            return mapper.readValue(json, Book.class).toString();
        } catch (JacksonException e) {
            return e.getClass().getSimpleName() + ": " + e.getOriginalMessage();
        }
    }
}
```

`-Dexec.mainClass` overrides the class named in `pom.xml` for one run:

```
ana@vm:~/catalogue$ mvn -q compile exec:java -Dexec.mainClass=com.example.catalogue.Input
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper (file:/usr/share/maven/lib/guava.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
{"title":"Dune","author":"Frank Herbert","year":1965}
  lenient: Book[title=Dune, author=Frank Herbert, year=1965]
  strict:  Book[title=Dune, author=Frank Herbert, year=1965]
{"title":"Dune","author":"Frank Herbert","year":1965,"isbn":"0441013597"}
  lenient: Book[title=Dune, author=Frank Herbert, year=1965]
  strict:  UnrecognizedPropertyException: Unrecognized property "isbn" (class com.example.catalogue.Book), not marked as ignorable
{"title":"Dune"}
  lenient: Book[title=Dune, author=null, year=0]
  strict:  MismatchedInputException: Missing creator property 'author' (index 1); `DeserializationFeature.FAIL_ON_MISSING_CREATOR_PROPERTIES` enabled
{"title":"Dune","author":"Frank Herbert","year":"nineteen sixty-five"}
  lenient: InvalidFormatException: Cannot deserialize value of type `int` from String "nineteen sixty-five": not a valid `int` value
  strict:  InvalidFormatException: Cannot deserialize value of type `int` from String "nineteen sixty-five": not a valid `int` value
{"title":"Dune",
  lenient: StreamReadException: Unexpected end-of-input within/between Object entries
  strict:  StreamReadException: Unexpected end-of-input within/between Object entries
```

## Five inputs, two mappers

The first input is the right one, and both read it. The last two failed in both: **a year spelled in
words and text that stops halfway are not a `Book` by any reading**, and Jackson said so with an
exception that names the type and the value. Every one of its exceptions is a `JacksonException`, which
in Jackson 3 is unchecked, so a lambda can call `readValue` with no wrapping, unlike `Files.size` in
lesson 20.

The two in the middle are the ones to look at. **The default mapper accepted both without a word.** It
skipped the `isbn` it had no component for, and it built a `Book` with no author and the year 0 from an
object that had neither: a book printed in year 0, by nobody, is now in the program, and nothing will
notice until a page shows it. The strict mapper refused each of them, naming the field.

| feature | refuses | default in Jackson 3 |
|---|---|---|
| `FAIL_ON_UNKNOWN_PROPERTIES` | a field the class has no place for | off |
| `FAIL_ON_MISSING_CREATOR_PROPERTIES` | a constructor argument the JSON left out | off |

Which to turn on depends on who writes the JSON. Accepting unknown fields lets the other side add one
without breaking every reader; refusing missing ones is almost always
right for data a program is about to trust. Either way, **the checks that belong to the data belong in
the record**: a compact constructor that refuses a blank title or a year in the future runs when Jackson
builds the record, because Jackson builds it through that constructor, so no JSON can make an invalid
`Book`.

## The one setting that brings the danger back

Jackson can be told to write class names into the JSON and to build whatever class it finds there,
which is called polymorphic or **default typing**. It is off by default, and with it on for input from
outside, JSON becomes section 03's problem again: the sender chooses the classes. Leave it off; where a
field really can hold several types, name the allowed subtypes on the base type with `@JsonSubTypes`,
which is an allow-list written in the code.
