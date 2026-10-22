---
title: Four ways to remove while walking
version: 1
---

Section 03's two programs were the same mistake: a `for-each` loop, and a change to the list from
outside the iterator. **The safe versions all have one thing in common: whatever changes the list
is also whatever walks it**, or the walk happens over something that does not change. One program
shows the four of them side by side:

```schooling-example
{
  "language": "java",
  "file": "Safe.java",
  "parts": [
    {
      "code": "import java.util.ArrayList;\nimport java.util.Iterator;\nimport java.util.List;\nimport java.util.ListIterator;\n\npublic class Safe {\n    public static void main(String[] args) {\n        List<String> loans = new ArrayList<>(List.of(\"Dune\", \"Emma:late\", \"Ulysses:late\", \"Beloved:late\"));",
      "note": "**Four loans, three of them late**, and each technique below starts from its own copy of this list, so they cannot interfere with each other."
    },
    {
      "code": "\n        List<String> a = new ArrayList<>(loans);\n        Iterator<String> it = a.iterator();\n        while (it.hasNext()) {\n            if (it.next().endsWith(\":late\")) {\n                it.remove();\n            }\n        }\n        System.out.println(\"iterator.remove  \" + a);",
      "note": "**Remove through the iterator.** `it.remove()` deletes the element the last `next()` returned, and because the iterator made the change it updates its own count and cursor. This is the loop section 03 wanted to write, with the iterator in plain sight."
    },
    {
      "code": "\n        List<String> b = new ArrayList<>(loans);\n        b.removeIf(loan -> loan.endsWith(\":late\"));\n        System.out.println(\"removeIf         \" + b);",
      "note": "**Or say only what to remove.** `removeIf` takes a condition and does the walking itself, safely. The argument is a lambda, which `java-functional` explains; read it as *a loan whose text ends with `:late`*."
    },
    {
      "code": "\n        List<String> c = new ArrayList<>(loans);\n        ListIterator<String> li = c.listIterator();\n        while (li.hasNext()) {\n            String loan = li.next();\n            if (loan.endsWith(\":late\")) {\n                li.set(loan.replace(\":late\", \":fined\"));\n                li.add(\"letter to \" + loan.replace(\":late\", \"\"));\n            }\n        }\n        System.out.println(\"listIterator     \" + c);",
      "note": "**A `ListIterator` can also replace and insert.** `set` replaces the element just returned, and `add` inserts a new one after it, where the next `next()` will not see it. Only lists have one, because only lists have positions."
    },
    {
      "code": "\n        List<String> d = new ArrayList<>(loans);\n        for (String loan : List.copyOf(d)) {\n            if (loan.endsWith(\":late\")) {\n                d.remove(loan);\n            }\n        }\n        System.out.println(\"copy             \" + d);\n    }\n}",
      "note": "**Or walk a copy and change the original.** The `for-each` iterates over `List.copyOf(d)`, which nothing changes, while `remove` works on `d`. It costs a second list for the length of the loop."
    }
  ]
}
```

```
ana@vm:~/iter$ java Safe.java
iterator.remove  [Dune]
removeIf         [Dune]
listIterator     [Dune, Emma:fined, letter to Emma, Ulysses:fined, letter to Ulysses, Beloved:fined, letter to Beloved]
copy             [Dune]
```

Three techniques removed the late loans and left `[Dune]`, with no exception and no skipped element.
The fourth did more: every late loan became `fined`, and a letter was inserted after it. **Seven
elements came out of four**, and the iterator went on walking cleanly past each insertion, because
it made each one itself.

## Which one to reach for

| you want to | write |
|---|---|
| remove what matches a condition | `removeIf`, the shortest and the hardest to get wrong |
| decide element by element, with more than one condition or a side effect | an explicit `Iterator` and `it.remove()` |
| replace or insert while walking a list | a `ListIterator` and its `set` or `add` |
| call a method that changes the list from inside the loop | walk a copy, `List.copyOf(...)` |

The copy is the last resort and sometimes the only one, for instance when the loop calls
`member.returnLoan(loan)`, which removes from a list the loop cannot see into. **Each of the others
avoids the second list**, and that matters when the list has a million entries.

## And for maps

A `Map` is walked through one of its views, `keySet()`, `values()` or `entrySet()`, and the same
rule holds: change the map through the view's iterator, or not at all, while the walk lasts.
`map.entrySet().removeIf(e -> e.getValue() == 0)` removes every entry whose value is zero, and
`map.values().removeIf(...)` does the same by looking only at the values. **A view is backed by the
map**, so what it removes is gone from the map itself.
