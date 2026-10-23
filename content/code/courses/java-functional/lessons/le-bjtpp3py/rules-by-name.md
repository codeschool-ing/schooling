---
title: Rules chosen by name
version: 1
---

**When behaviour is a value, a set of behaviours is a map.** The classic Strategy pattern gives
each pricing rule its own class implementing a shared interface, and a factory with a `switch` to
pick one. With lambdas the interface is already in the JDK, the classes collapse to one line each,
and the `switch` becomes a lookup:

```java
// Strategies.java: pricing rules in a map, chosen by name at run time
import java.util.Map;
import java.util.TreeMap;
import java.util.function.UnaryOperator;

public class Strategies {
    static UnaryOperator<Long> percentOff(int percent) {
        return cents -> cents - cents * percent / 100;
    }

    static final Map<String, UnaryOperator<Long>> RULES = new TreeMap<>(Map.of(
            "none", cents -> cents,
            "student", percentOff(15),
            "black-friday", percentOff(40),
            "free-shipping", cents -> cents >= 15000 ? cents : cents + 1500));

    public static void main(String[] args) {
        String name = args[0];
        long price = Long.parseLong(args[1]);
        UnaryOperator<Long> rule = RULES.get(name);
        if (rule == null) {
            System.err.println("no rule called " + name + "; the rules are " + RULES.keySet());
            System.exit(2);
        }
        System.out.println(name + ": " + price + " -> " + rule.apply(price));
    }
}
```

```
ana@vm:~/fp/higher-order$ java Strategies.java student 8990
student: 8990 -> 7642
ana@vm:~/fp/higher-order$ java Strategies.java black-friday 8990
black-friday: 8990 -> 5394
ana@vm:~/fp/higher-order$ java Strategies.java free-shipping 12000
free-shipping: 12000 -> 13500
ana@vm:~/fp/higher-order$ java Strategies.java free-shipping 15000
free-shipping: 15000 -> 15000
ana@vm:~/fp/higher-order$ java Strategies.java studnet 8990; echo $?
no rule called studnet; the rules are [black-friday, free-shipping, none, student]
2
```

Each rule is one entry: a name and a lambda, or a factory call that returns one. **Adding a rule is
adding a line to the map**, with no new class and no new branch in a `switch`. The `TreeMap` keeps
the names sorted, which is only there so the list in the error message reads well.

## An unknown name is an error, said out loud

The last run asked for a rule that does not exist. `RULES.get` returned `null`, and the program
**said so, named the rules it does know, and exited with status 2**, the number `echo $?` printed under it. The tempting
shortcut is `RULES.getOrDefault(name, cents -> cents)`, which charges full price for a typo and
prints a perfectly plausible number. Nobody would notice until a customer did. A default is right
when the default is what the person meant, and a misspelt rule name never means "no rule".

## Where the pattern still needs classes

A map of lambdas fits when each strategy is **one operation with no state of its own**. When a
strategy needs several methods that belong together, configuration, or a name that shows up in
logs, an interface with a few small classes, or an `enum` whose constants each carry a lambda,
reads better. The test is the same as in lesson 3 section 05: if a rule needs a comment to say what
it does, it needs a name, and a class or an enum constant is a name.
