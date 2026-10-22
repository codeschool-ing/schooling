---
title: Maps, and the three methods that replace a page of code
version: 1
---

A `Map` is a set of keys with a value attached to each one: an ISBN to its book, a title to the
number of times it was borrowed. It is not a `Collection` at all, and it does not iterate like one,
but its classes mirror the sets one for one. **`HashMap`, `LinkedHashMap` and `TreeMap` are
`HashSet`, `LinkedHashSet` and `TreeSet` with a value beside each element**, and they keep the same
three orders for the same reasons.

The program below counts loans, and in doing it uses the three methods that make a map pleasant:
`merge`, `getOrDefault` and `computeIfAbsent`.

```schooling-example
{
  "language": "java",
  "file": "Counts.java",
  "parts": [
    {
      "code": "import java.util.ArrayList;\nimport java.util.HashMap;\nimport java.util.LinkedHashMap;\nimport java.util.List;\nimport java.util.Map;\nimport java.util.TreeMap;\n\npublic class Counts {\n    public static void main(String[] args) {\n        String[] loans = {\"Dune\", \"Emma\", \"Dune\", \"Ulysses\", \"Dune\", \"Emma\"};",
      "note": "**Six loans, three titles.** A map is the shape for a question like *how many times was each title borrowed*: one entry per key, and a value beside it."
    },
    {
      "code": "\n        Map<String, Integer> count = new HashMap<>();\n        for (String title : loans) {\n            count.merge(title, 1, Integer::sum);\n        }\n        System.out.println(\"HashMap       \" + count);",
      "note": "**`merge` is a count in one call.** If the key is absent it stores `1`; if it is there it combines the old value with `1` using `Integer::sum`. Written by hand it is a `get`, a test for `null` and a `put`."
    },
    {
      "code": "        System.out.println(\"Beloved       \" + count.get(\"Beloved\"));\n        System.out.println(\"or default    \" + count.getOrDefault(\"Beloved\", 0));",
      "note": "**`get` answers `null` for a key that is not there**, which unboxed into an `int` is a `NullPointerException` waiting to happen (lesson 4). `getOrDefault` names the answer for *absent* yourself."
    },
    {
      "code": "\n        Map<String, Integer> firstSeen = new LinkedHashMap<>();\n        for (String title : loans) {\n            firstSeen.putIfAbsent(title, firstSeen.size());\n        }\n        System.out.println(\"LinkedHashMap \" + firstSeen);\n        System.out.println(\"TreeMap       \" + new TreeMap<>(count));",
      "note": "**The same three orders as the sets.** A `LinkedHashMap` keeps the order keys first arrived in, and `putIfAbsent` leaves an existing entry alone. A `TreeMap` built from `count` sorts the keys."
    },
    {
      "code": "\n        Map<Character, List<String>> byLetter = new TreeMap<>();\n        for (String title : loans) {\n            byLetter.computeIfAbsent(title.charAt(0), k -> new ArrayList<>()).add(title);\n        }\n        System.out.println(\"grouped       \" + byLetter);\n    }\n}",
      "note": "**`computeIfAbsent` is the grouping idiom.** It returns the list stored under the key, creating an empty one first if there is none, so `.add(title)` always has a list to add to. The `k -> new ArrayList<>()` is a lambda, which `java-functional` explains; here read it as *how to make the missing value*."
    }
  ]
}
```

```
ana@vm:~/colls$ java Counts.java
HashMap       {Dune=3, Ulysses=1, Emma=2}
Beloved       null
or default    0
LinkedHashMap {Dune=0, Emma=1, Ulysses=2}
TreeMap       {Dune=3, Emma=2, Ulysses=1}
grouped       {D=[Dune, Dune, Dune], E=[Emma, Emma], U=[Ulysses]}
```

Three things to read off it. **`Dune=3` came from `merge` alone**, with no test anywhere for whether
the key was new. `Beloved` was never borrowed, and `get` said `null` where `getOrDefault` said `0`;
the `0` is the answer a report wants. And the `HashMap` printed `Dune, Ulysses, Emma`, the
`LinkedHashMap` `Dune, Emma, Ulysses`, the `TreeMap` `Dune, Emma, Ulysses` again by alphabet. Two
of those agreeing is a coincidence of these titles.

## What a key must be

Everything section 03 said about a set's elements applies to a map's keys, because a `HashMap`
finds a key exactly as a `HashSet` finds an element. A `Book` key with `equals` and no `hashCode`
breaks `get` in the same silent way: the entry is there, and `get` with an equal book answers
`null`.

**A key must also not change while it is in the map.** Its hash code decided its bucket when it went
in; change a field that the hash code reads and the entry stays in the old bucket, where no lookup
will look. Strings, wrappers, records and enums cannot change, which is why they make good keys and
why most maps use one of them.
