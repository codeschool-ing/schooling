---
title: When a lambda reads better
version: 1
---

**A reference is better when it names what happens; a lambda is better when it has to show what
happens.** `String::toUpperCase` says everything in its name. `s -> s.substring(2)` cannot become a
reference at all, because it passes a value the call site chose, and a reference can only pass
along the arguments it receives.

## The compiler cannot choose

Some references are refused because they fit in more than one way:

```java
// Ambiguous.java: a reference that matches two methods
import java.util.function.Function;

public class Ambiguous {
    public static void main(String[] args) {
        Function<Integer, String> show = Integer::toString;
        System.out.println(show.apply(7));
    }
}
```

```
ana@vm:~/fp/references$ javac -d out Ambiguous.java
Ambiguous.java:6: error: incompatible types: invalid method reference
        Function<Integer, String> show = Integer::toString;
                                         ^
    reference to toString is ambiguous
      both method toString(int) in Integer and method toString() in Integer match
1 error
```

`Integer` has a static `toString(int)` and an instance `toString()`. Read as static, the reference
passes the argument to `toString(int)`; read as unbound, it calls `toString()` on the argument. Both
fit `Function<Integer, String>`, and **the compiler refuses to guess**. The lambda says which:
`n -> Integer.toString(n)`, or `n -> n.toString()`. A reference that needs a comment to explain
which method it means is a lambda waiting to be written.

## A short guide

| the lambda | as a reference? |
|---|---|
| `s -> s.length()` | `String::length`, clearer |
| `x -> Math.abs(x)` | `Math::abs`, clearer |
| `() -> new HashMap<>()` | `HashMap::new`, clearer |
| `s -> s.substring(2)` | none: the `2` is not an argument |
| `b -> b.author().name()` | none: two calls in a row |
| `n -> n % 2 == 0` | none: not a method call |
| `x -> helper.check(x, LIMIT)` | none, unless `check` is changed to take one argument |

**When the logic is long enough to need a name, give it one**: write a private method and pass a
reference to it, `this::isWorthShipping` or `Rules::isWorthShipping`. That is the step lesson 1
section 05 promised, and it is what turns a twenty-line lambda in an argument list into one
readable line with a method you can test on its own.
