---
title: When it goes wrong instead of slow
version: 1
---

**A sequential pipeline that changes shared state usually gets away with it. A parallel one does not**,
because several threads now run the same lambda at the same moment. The rules from earlier lessons,
no side effects in a lambda (lesson 4 section 02) and associative reductions (lesson 7 section 03),
stop being style and become correctness:

```java
// Wrong.java: shared state, order and the difference between findAny and findFirst
import java.util.ArrayList;
import java.util.List;
import java.util.stream.IntStream;

public class Wrong {
    public static void main(String[] args) {
        for (int run = 1; run <= 10; run++) {
            List<Integer> shared = new ArrayList<>();
            try {
                IntStream.range(0, 10_000).parallel().forEach(shared::add);
                System.out.println("run " + run + ": " + shared.size() + " of 10000");
            } catch (RuntimeException e) {
                System.out.println("run " + run + ": " + e.getClass().getSimpleName());
            }
        }
        List<Integer> collected = IntStream.range(0, 10_000).parallel().boxed().toList();
        System.out.println("collected: " + collected.size() + " of 10000, first " + collected.get(0) + ", last " + collected.get(9999));

        System.out.print("forEach:        ");
        IntStream.range(0, 10).parallel().forEach(i -> System.out.print(i + " "));
        System.out.print("\nforEachOrdered: ");
        IntStream.range(0, 10).parallel().forEachOrdered(i -> System.out.print(i + " "));
        System.out.println();

        System.out.println("findFirst: " + IntStream.range(0, 1_000_000).parallel().filter(i -> i % 7919 == 0).findFirst().getAsInt());
        System.out.println("findAny:   " + IntStream.range(0, 1_000_000).parallel().filter(i -> i % 7919 == 0).findAny().getAsInt());
    }
}
```

```
ana@vm:~/fp/parallel$ java Wrong.java
run 1: 10000 of 10000
run 2: 6628 of 10000
run 3: 8682 of 10000
run 4: 8648 of 10000
run 5: 5000 of 10000
run 6: ArrayIndexOutOfBoundsException
run 7: 9303 of 10000
run 8: 10000 of 10000
run 9: 9983 of 10000
run 10: 10000 of 10000
collected: 10000 of 10000, first 0, last 9999
forEach:        1 0 4 2 5 3 7 9 8 6 
forEachOrdered: 0 1 2 3 4 5 6 7 8 9 
findFirst: 0
findAny:   625601
```

## A shared `ArrayList` loses elements, or breaks

Ten runs of the same code, three different outcomes. Six runs lost elements, one lost half of them.
Run 6 threw `ArrayIndexOutOfBoundsException`. And three runs came out right, which is the worst of
the three outcomes, because a test that happened to land on one of those would pass.
`ArrayList.add` reads the size, writes the element at that index and stores the new size; two
threads doing that at once can write to the same slot, so one element vanishes. Or one thread grows
the internal array while another writes past its old end, and the result is an exception from deep
inside `ArrayList`. **Which one happens, and how many elements go missing, changes from run to
run**, which is the signature of a race condition. Lesson 14 names it
and lesson 12 explains what the processor is doing underneath.

The fix is not a lock around `add`. **It is to stop sharing**: let the stream build the list with
`toList()` or a collector, which gives each thread its own container and merges them at the end.
`collected` has all 10,000 elements, in order.

## Order costs something

`forEach` on a parallel stream runs each element on whatever thread has it, so the numbers came out
mixed. `forEachOrdered` keeps the source's order, by making threads wait for the elements before
theirs. `findFirst` likewise has to return the first match in source order, 0, even if a worker found
a later one first, while `findAny` may return whichever match any thread found. **Ask for order only
when the answer needs it**: on a parallel stream, `findAny` and `unordered()` let the threads stop
waiting for each other.
