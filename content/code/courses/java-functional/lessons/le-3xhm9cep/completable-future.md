---
title: CompletableFuture
version: 1
---

**A `Future` can only be waited on. A `CompletableFuture` can also be told what to do next**, with the
same vocabulary as streams and `Optional`: `thenApply` maps the result, `thenCombine` joins two results,
`exceptionally` turns a failure into a value. A pipeline of steps is described up front and runs as each
result arrives, without a thread sitting in `get` between the steps.

The case it was made for: a product page needs a price from one service and a stock level from another,
each slow. Asked one after the other, the page waits for the sum of the two. Asked at once, it waits for
the slower one.

```schooling-example
{
  "language": "java",
  "file": "Page.java",
  "parts": [
    {
      "code": "// Page.java: two slow lookups at once, combined when both are back\nimport java.util.concurrent.CompletableFuture;\nimport java.util.concurrent.ExecutorService;\nimport java.util.concurrent.Executors;\n\npublic class Page {\n    static long price(String title) {\n        Pool.sleep(300);\n        return 4490;\n    }\n\n    static int stock(String title) {\n        Pool.sleep(200);\n        if (title.isBlank()) {\n            throw new IllegalArgumentException(\"no title\");\n        }\n        return 3;\n    }",
      "note": "Two stand-ins for remote services: one takes 300 ms, the other 200 ms, and the second fails for a blank title. They reuse `Pool.sleep` from section 02."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        try (ExecutorService io = Executors.newFixedThreadPool(4)) {\n            long start = System.nanoTime();\n            long p = price(\"Middlemarch\");\n            int s = stock(\"Middlemarch\");\n            System.out.printf(\"one after the other: %d cents, %d in stock, %d ms%n\", p, s, ms(start));",
      "note": "The plain version: two calls in sequence, so the page waits for both, one after the other."
    },
    {
      "code": "\n            start = System.nanoTime();\n            CompletableFuture<Long> priceF = CompletableFuture.supplyAsync(() -> price(\"Middlemarch\"), io);\n            CompletableFuture<Integer> stockF = CompletableFuture.supplyAsync(() -> stock(\"Middlemarch\"), io);\n            String line = priceF\n                    .thenCombine(stockF, (cents, copies) -> cents + \" cents, \" + copies + \" in stock\")\n                    .join();\n            System.out.printf(\"at once: %s, %d ms%n\", line, ms(start));",
      "note": "`supplyAsync` starts each lookup on the `io` pool and returns at once. `thenCombine` describes what to do when both are back; `join` waits for that final value."
    },
    {
      "code": "\n            String fallback = CompletableFuture.supplyAsync(() -> stock(\" \"), io)\n                    .thenApply(copies -> copies + \" in stock\")\n                    .exceptionally(e -> \"stock unknown (\" + e.getCause().getMessage() + \")\")\n                    .join();\n            System.out.println(fallback);\n        }\n    }",
      "note": "When a step fails, the steps after it are skipped until `exceptionally`, which turns the failure into a value the page can show. The original exception is its cause."
    },
    {
      "code": "\n\n    static long ms(long start) {\n        return (System.nanoTime() - start) / 1_000_000;\n    }\n}\n"
    }
  ],
  "output": "one after the other: 4490 cents, 3 in stock, 537 ms\nat once: 4490 cents, 3 in stock, 304 ms\nstock unknown (no title)"
}
```

## Reading the times

One after the other took the sum, 537 ms. **At once took about the slower of the two, 304 ms**,
because both lookups were running on two of the pool's threads at the same time. On a page that asks
five services, that is the difference between the sum of five waits and the longest of them.

`exceptionally` received the failure of a blank title and produced a line the page can print, where the
plain version would have thrown out of the page entirely. **The error is turned into a value on purpose,
and the message says so**: a fallback that hid the cause would be the silent failure this course keeps
pointing at.

## Which executor

Always pass one. Without the second argument, `supplyAsync` runs on the common fork-join pool, the same
three workers that parallel streams use (lesson 9 section 05), and lookups that wait would hold them and
stall every parallel stream in the program. A pool of its own for waiting work, or in lesson 17 an
executor of virtual threads, keeps the two kinds of work apart.
