---
title: A constraint of your own, @ValidIsbn
version: 1
---

An ISBN-13 is thirteen digits, and **the last one is a check digit** computed from the first twelve,
so that a single mistyped digit makes the number invalid instead of naming another book. The rule:
multiply the twelve digits by 1 and 3 in turn, add the products, and the check digit is whatever
brings the sum up to the next multiple of ten.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 210\" role=\"img\" aria-label=\"The first twelve digits of 9786500000047, 9 7 8 6 5 0 0 0 0 0 0 4, multiplied by the weights 1 3 1 3 and so on, give 9 21 8 18 5 0 0 0 0 0 0 12, which add up to 73. (10 - 73 % 10) % 10 is 7, and the thirteenth digit is 7, so the ISBN is valid.\"><text x=\"96\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">digit</text><text x=\"96\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">weight</text><text x=\"96\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">product</text><rect x=\"112\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"128\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9</text><text x=\"128\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"128\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">9</text><rect x=\"152\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"168\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><text x=\"168\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"168\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">21</text><rect x=\"192\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"208\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8</text><text x=\"208\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"208\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">8</text><rect x=\"232\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"248\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"248\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"248\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">18</text><rect x=\"272\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"288\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"288\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"288\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">5</text><rect x=\"312\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"328\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"328\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"328\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"352\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"368\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"368\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"368\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"392\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"408\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"408\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"408\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"432\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"448\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"448\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"448\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"472\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"488\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"488\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"488\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"512\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"528\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"528\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"528\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"552\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"568\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><text x=\"568\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"568\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">12</text><rect x=\"606\" y=\"24\" width=\"32\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"622\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">7</text><text x=\"622\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">check</text><line x1=\"112\" y1=\"124\" x2=\"584\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"112\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the products add up to 9 + 21 + 8 + 18 + 5 + 12 = 73</text><text x=\"112\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">(10 - 73 % 10) % 10 = (10 - 3) % 10 = 7</text><text x=\"112\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">7 is the thirteenth digit of 9786500000047, so the ISBN is valid</text></svg>", "caption": "The ISBN-13 check digit of 9786500000047, worked by hand: weights 1 and 3 in turn, then the distance to the next multiple of ten."}
```

`9786500000048` has the same first twelve digits, so its check digit should also be 7, and it ends in
8. That is the difference the previous section could not see.

A constraint of your own is three pieces: the rule, the annotation a record carries, and a validator
that connects the two.

## The rule

Create `src/main/java/com/example/bookshop/catalogue/Isbn.java`:

```schooling-example
{
  "language": "java",
  "file": "Isbn.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\npublic final class Isbn {\n\n    private Isbn() {\n    }\n",
      "note": "Only static methods and a private constructor: nobody makes an `Isbn`, they ask it a question. It knows nothing about Spring, which is why lesson 18 can test it with nothing running."
    },
    {
      "code": "    /** True when the text is thirteen digits whose last one is the ISBN-13 check digit. */\n    public static boolean isValid(String text) {\n        if (text == null || !text.matches(\"\\\\d{13}\")) {\n            return false;\n        }",
      "note": "Thirteen digits and nothing else. `matches` has to cover the whole text, so a hyphen, a space or a fourteenth digit fails here, before any arithmetic."
    },
    {
      "code": "        int sum = 0;\n        for (int i = 0; i < 12; i++) {\n            int digit = text.charAt(i) - '0';\n            sum += (i % 2 == 0) ? digit : digit * 3;\n        }",
      "note": "Weights 1 and 3 in turn: the digits at even positions, counting from zero, count once and the others three times. `charAt(i) - '0'` turns the character `'7'` into the number 7."
    },
    {
      "code": "        int check = (10 - sum % 10) % 10;\n        return check == text.charAt(12) - '0';\n    }",
      "note": "The distance from the sum up to the next multiple of ten. The outer `% 10` is for a sum that already ends in 0: the distance would come out as 10, and the check digit is 0."
    },
    {
      "code": "}"
    }
  ]
}
```

## The annotation

Create `ValidIsbn.java` beside it:

```java
package com.example.bookshop.catalogue;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

@Documented
@Constraint(validatedBy = IsbnValidator.class)
@Target({ElementType.FIELD, ElementType.PARAMETER, ElementType.RECORD_COMPONENT})
@Retention(RetentionPolicy.RUNTIME)
public @interface ValidIsbn {

    String message() default "must be a valid ISBN-13";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
```

Each line has a job:

- **`@Constraint(validatedBy = IsbnValidator.class)`** is what makes this annotation a constraint,
  and names the class that checks it.
- `message`, `groups` and `payload` are the three members Bean Validation requires of every
  constraint. `message` is the default text of a violation, the one you will see in the log below;
  `groups` and `payload` are for selecting and labelling constraints, and this lesson needs neither.
- `@Retention(RetentionPolicy.RUNTIME)` keeps the annotation in the compiled class. The validator
  finds constraints by reflection while the application runs, and an annotation the compiler threw
  away is invisible to it.
- `@Target` says where the annotation may be written. `RECORD_COMPONENT` allows it on a record's
  component, and **`FIELD` is the one that makes it work**: Java copies an annotation written on a
  component onto the private field behind it only if `@Target` includes `FIELD`, and the field is
  where the validator looks. A detour at the end of this section takes `FIELD` out.

## The validator

Create `IsbnValidator.java`:

```java
package com.example.bookshop.catalogue;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class IsbnValidator implements ConstraintValidator<ValidIsbn, String> {

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        return value == null || Isbn.isValid(value);
    }
}
```

`ConstraintValidator<ValidIsbn, String>` reads as "checks `@ValidIsbn` on a `String`". The validator
answers one question, and **a `null` is not its question**: it returns `true` and leaves `null` to
`@NotNull`. That is the convention of every standard constraint, `@Size` and `@PositiveOrZero`
included, and it means each broken rule produces exactly one error, as the missing ISBN below shows.

The rule sits in `Isbn` rather than inside the validator because it is a fact about books, not about
HTTP. Lesson 18 tests `Isbn` on its own, with no Spring and no request anywhere.

## The record carries it

Replace `BookRequest.java` with its final version:

```java
package com.example.bookshop.catalogue;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public record BookRequest(
        @NotNull @ValidIsbn String isbn,
        @NotBlank @Size(max = 200) String title,
        @NotBlank @Size(max = 120) String author,
        @NotNull @PositiveOrZero Integer priceCents) {
}
```

Build, restart, and send the ISBN that passed before:

```
(pending wrong-check-400)
```

```
(pending wrong-check-400-log)
```

The field error carries the code `ValidIsbn` and the message from the annotation. A request with no
ISBN at all breaks only `@NotNull`, so it gets one error and not two:

```
(pending no-isbn)
```

```
(pending no-isbn-log)
```

And a real check digit goes through:

```
(pending valid-201)
```

The in-memory repository started again with the application, which is why this book is number 4
once more.

## A detour: a constraint nobody checks

Take `FIELD` out of `@Target`, build, restart, and send the wrong check digit again:

```
(pending no-field)
```

```
(pending no-field-201)
```

The project compiled without a warning, the annotation is still written on the record, and the
request was accepted. Without `FIELD`, the copy on the field was never made and the validator had
nothing to check. **A constraint that is never checked looks exactly like one that always passes**,
and the only way to tell them apart is a request that should fail. Sending one every time is a
test's job, and lesson 18 starts writing them. Put `FIELD` back and build again:

```
(pending field-back)
```
