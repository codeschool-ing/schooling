---
title: A queue, and the two ways each operation can fail
version: 1
---

A queue is a line at a desk: the first to arrive is the first served. Java's `Queue` interface
says exactly that and little else. You put elements in at the tail and take them out at the head,
and nothing in between is reachable by position. The belief to drop first is that a queue is a list
you promise to use carefully. **A `Queue` is a narrower type on purpose**, and the narrowness is
what lets `ArrayDeque` do the job faster than any list, as section 04 measures.

Every operation comes in two forms, one that throws when it cannot do its job and one that answers
with a special value instead:

| operation | throws an exception | answers a special value |
|---|---|---|
| put at the tail | `add(e)`, `IllegalStateException` when full | `offer(e)`, `false` when full |
| take from the head | `remove()`, `NoSuchElementException` when empty | `poll()`, `null` when empty |
| look at the head | `element()`, `NoSuchElementException` when empty | `peek()`, `null` when empty |

**Use the throwing form when the situation is a mistake, and the special value when it is a
normal outcome.** An empty desk at closing time is normal, so `poll` and a test for `null` read
well. A queue that should never be empty here, and is, deserves the exception.

## The desk

Save this in a new directory, `~/queues`. The second half uses an `ArrayBlockingQueue`, a queue with
a fixed capacity from `java.util.concurrent`, because an `ArrayDeque` grows without limit and could
never show `offer` refusing:

```java
// Desk.java
import java.util.ArrayDeque;
import java.util.Queue;
import java.util.concurrent.ArrayBlockingQueue;

public class Desk {
    public static void main(String[] args) {
        Queue<String> desk = new ArrayDeque<>();
        desk.offer("Ana");
        desk.offer("Bruno");
        desk.offer("Carla");
        System.out.println("queue   " + desk);
        System.out.println("peek    " + desk.peek());
        System.out.println("poll    " + desk.poll());
        System.out.println("poll    " + desk.poll());
        System.out.println("poll    " + desk.poll());
        System.out.println("poll    " + desk.poll());
        System.out.println("peek    " + desk.peek());

        Queue<String> twoSeats = new ArrayBlockingQueue<>(2);
        System.out.println("offer   " + twoSeats.offer("Ana"));
        System.out.println("offer   " + twoSeats.offer("Bruno"));
        System.out.println("offer   " + twoSeats.offer("Carla"));
        System.out.println("add     " + twoSeats.add("Carla"));
    }
}
```

```
ana@vm:~/queues$ java Desk.java
queue   [Ana, Bruno, Carla]
peek    Ana
poll    Ana
poll    Bruno
poll    Carla
poll    null
peek    null
offer   true
offer   true
offer   false
Exception in thread "main" java.lang.IllegalStateException: Queue full
	at java.base/java.util.AbstractQueue.add(AbstractQueue.java:98)
	at java.base/java.util.concurrent.ArrayBlockingQueue.add(ArrayBlockingQueue.java:330)
	at Desk.main(Desk.java:24)
```

Three people in, three out, in the order they arrived. **The fourth `poll` answered `null`** and
the program carried on; so did the `peek` after it. The two-seat queue took two people, and
`offer` answered `false` for the third. Then `add` asked for the same thing and threw
`IllegalStateException: Queue full`, from line 24, and the program ended there.

`null` as an answer has one consequence: **a queue that answers `null` for empty cannot hold `null`
as an element**, or the two would be indistinguishable. `ArrayDeque` refuses `null` outright with a
`NullPointerException`, and so do most queues.

## A queue that is not first come, first served

A `PriorityQueue` keeps the head at the *smallest* element, by natural order or by a `Comparator`
you give it. The library's holds go to whoever has waited fewest days, which is a strange rule for a
library and a convenient one for showing the order:

```schooling-example
{
  "language": "java",
  "file": "Holds.java",
  "parts": [
    {
      "code": "import java.util.Comparator;\nimport java.util.PriorityQueue;\nimport java.util.Queue;\n\npublic class Holds {\n    record Hold(String member, int days) {}",
      "note": "**A hold is a member and how many days they have waited**, as a record: lesson 29's one-line class with a constructor, accessors and a `toString`."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        Queue<Hold> holds = new PriorityQueue<>(Comparator.comparingInt(Hold::days));",
      "note": "**The comparator is the priority.** `Comparator.comparingInt(Hold::days)` reads as *compare holds by their days*, smallest first; the `::` syntax is a method reference, which `java-functional` explains."
    },
    {
      "code": "        holds.offer(new Hold(\"Bruno\", 9));\n        holds.offer(new Hold(\"Ana\", 2));\n        holds.offer(new Hold(\"Davi\", 5));\n        holds.offer(new Hold(\"Carla\", 1));\n        holds.offer(new Hold(\"Eva\", 3));\n        System.out.println(\"printed  \" + holds);",
      "note": "**Five holds, in no particular order**, then the queue printed whole. Watch the printed order against the order `poll` gives."
    },
    {
      "code": "        while (!holds.isEmpty()) {\n            System.out.println(\"next     \" + holds.poll());\n        }\n        holds.remove();\n    }\n}",
      "note": "**`poll` takes the head each time** until the queue is empty. The last line asks an empty queue for its head with `remove`, the throwing form."
    }
  ]
}
```

```
ana@vm:~/queues$ java Holds.java
printed  [Hold[member=Carla, days=1], Hold[member=Ana, days=2], Hold[member=Davi, days=5], Hold[member=Bruno, days=9], Hold[member=Eva, days=3]]
next     Hold[member=Carla, days=1]
next     Hold[member=Ana, days=2]
next     Hold[member=Eva, days=3]
next     Hold[member=Davi, days=5]
next     Hold[member=Bruno, days=9]
Exception in thread "main" java.util.NoSuchElementException
	at java.base/java.util.AbstractQueue.remove(AbstractQueue.java:117)
	at Holds.main(Holds.java:20)
```

**The printed queue is not in priority order: Eva, with 3 days, is last.** A `PriorityQueue` is a
heap, an array arranged so that the smallest element is at the front and each element is no larger
than the two below it. That is enough to find the head in one step and to restore the arrangement
in a few after a `poll`, and it is not a sorted list. `toString` and a `for-each` walk the array as
it lies. Only `poll`, one call at a time, gives the priority order: Carla, Ana, Eva, Davi, Bruno.

The last line shows the other form failing. `remove()` on the empty queue threw
`NoSuchElementException`, where `poll()` would have answered `null`.
