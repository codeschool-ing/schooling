---
title: Reading every vector
version: 1
---

Every search in lessons 3 to 10 was the same line of NumPy: multiply the question's vector by every
stored vector and sort the scores. It is easy to file that line under "toy" and assume a real
system does something cleverer from the start. **It is not a toy. It is exact search**, the method
that returns the true nearest vectors, and it is the yardstick every faster method is measured
against; lesson 15 measures approximate indexes by how often they agree with it. What it costs is
the question here, and the cost has a simple shape: **every query reads every vector.**

`brute.py` times it at three sizes. The vectors are random rather than embedded texts, because a
million random numbers take seconds to make and a million embedded texts would take hours, and the
arithmetic does not care what the numbers mean.

```schooling-example
{
  "language": "python",
  "file": "brute.py",
  "parts": [
    {
      "code": "import os\nos.environ[\"OPENBLAS_NUM_THREADS\"] = \"1\"\nimport time\nimport numpy as np\n\nrng = np.random.default_rng(11)\nd = 384\nq = rng.standard_normal(d).astype(np.float32)\nq /= np.linalg.norm(q)",
      "note": "Tell NumPy's matrix library to use one thread before NumPy is imported, so the timings are one core's. Then a random query of 384 numbers, made unit length like every vector this course stores."
    },
    {
      "code": "print(f\"{'vectors':>9} {'memory':>9} {'per query':>10} {'queries/s':>9} {'multiply-adds':>14}\")\nfor n in (10_000, 100_000, 1_000_000):\n    D = rng.standard_normal((n, d), dtype=np.float32)\n    D /= np.linalg.norm(D, axis=1, keepdims=True)",
      "note": "Three collections of random unit vectors: ten thousand, a hundred thousand and a million. Random numbers cost exactly what real embeddings cost to multiply."
    },
    {
      "code": "    times = []\n    for _ in range(50):\n        t = time.perf_counter()\n        scores = D @ q\n        top = np.argpartition(-scores, 10)[:10]\n        times.append(time.perf_counter() - t)\n    s = min(times)",
      "note": "One search is the whole of lesson 3's method: a dot product with every vector, then the ten best. Run it 50 times and keep the fastest."
    },
    {
      "code": "    print(f\"{n:>9,} {D.nbytes / 1e6:>6.0f} MB {s * 1000:>7.2f} ms {1 / s:>9.0f} {n * d:>14,}\")",
      "note": "Print the memory the vectors take, the time per query, how many queries a second that allows, and the multiplications one query needs."
    }
  ]
}
```

```
ana@lab:~/emb$ nproc; grep -m1 "model name" /proc/cpuinfo
4
model name	: Intel(R) Xeon(R) Processor @ 2.10GHz
ana@lab:~/emb$ python brute.py
  vectors    memory  per query queries/s  multiply-adds
   10,000     15 MB    0.66 ms      1526      3,840,000
  100,000    154 MB    5.86 ms       171     38,400,000
1,000,000   1536 MB  129.16 ms         8    384,000,000
```

**The time follows the count.** Ten times the vectors took 8.9 times as long from the first row to
the second, from 0.66 ms to 5.86 ms. The work is one multiply-add per number stored, and the last
column is the vector count times 384. From the second row to the third it took 22 times as
long, 129.16 ms. A million vectors are 1536 MB, and every query has to pull all of it through the
processor; at that size the likeliest limit is how fast memory can be read, not how fast the
multiplications are done.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A bar chart with a logarithmic axis of the time one exact search takes on one core, against the number of 384-dimension vectors searched: 10,000 vectors 0.66 ms, 100,000 vectors 5.86 ms, 1,000,000 vectors 129.16 ms. Each step is ten times more vectors.\"><path d=\"M170 200 L640 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M170 200 L170 206\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"170\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.1</text><path d=\"M287.5 200 L287.5 206\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"287.5\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M405 200 L405 206\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"405\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M522.5 200 L522.5 206\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"522.5\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M640 200 L640 206\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"640\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000</text><text x=\"405\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milliseconds per query, logarithmic scale</text><text x=\"158\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">10,000</text><text x=\"158\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">15 MB</text><rect x=\"170\" y=\"44\" width=\"96.3\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"274.3\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.66 ms</text><text x=\"158\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">100,000</text><text x=\"158\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">154 MB</text><rect x=\"170\" y=\"98\" width=\"207.7\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"385.7\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5.86 ms</text><text x=\"158\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1,000,000</text><text x=\"158\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1536 MB</text><rect x=\"170\" y=\"152\" width=\"365.6\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"543.6\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">129.16 ms</text><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vectors</text><text x=\"700\" y=\"262\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ten times the vectors, roughly ten times the time or more</text></svg>", "caption": "One exact search on one core, measured by brute.py. Every query reads every vector, so the time follows the count; the memory column is what has to be read each time."}
```

The queries-per-second column is the same measurement turned round, and it is the one that decides
whether this is enough. At ten thousand vectors one core answers 1526 searches a second, which is
more than most help centres will ever be asked. At a million it answers 8. Every answer is still exact; there
are simply only eight of them a second per core, and a second core only doubles that.

## When reading everything is the right answer

**For a small collection, exact search is the right method and not a stopgap.** Marginalia's 40
articles take 40 × 384 multiply-adds per question, nothing worth an index. Exact search needs no
building, no tuning and no memory beyond the vectors, and it never misses. Lesson 13 shows FAISS
calling it `IndexFlatIP`, and lesson 15 shows when it stops being enough.

What changes the answer is not only the size. The same million vectors at 8 queries a second are
fine for a nightly job that finds near-duplicates and hopeless for a search box that a thousand
people type into at once. The count of vectors and the count of queries together decide when the
cost of reading everything stops being acceptable, and the measurement above gives you both
numbers for one core.
