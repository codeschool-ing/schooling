---
title: Two meanings of precision and recall
version: 2
---

**Precision** and **recall** turn up in two places in evaluating a model, and they mean the same
arithmetic about different things.

**About a search.** Of the chunks the search returned, how many belong to the answer: precision. Of the
chunks that hold the answer, how many did the search return: recall. `rag` lesson 8 measured the second
as recall@k, with the rank of the first hit as mean reciprocal rank, and this lesson does not repeat it.
It adds the version that evaluation frameworks report under the names **context precision** and
**context recall**, in the section after next.

**About a detector.** Anything that flags replies as bad is a detector: a rule from lesson 8, a judge
from lesson 9, an alert from lesson 16. Of the replies it flagged, how many were bad: precision. Of the
replies that were bad, how many did it flag: recall. Lesson 10 gave this course its first set of
replies whose badness is known, the forty-eight with agreed labels, so a detector can now be scored.

The two meanings share a shape: a set that was chosen, a set that should have been, and the overlap.

| | Chosen | Should have been | Precision | Recall |
| --- | --- | --- | --- | --- |
| A search | chunks returned | chunks with the answer | returned that hold it | holding it that were returned |
| A detector | replies flagged | replies that are bad | flagged that are bad | bad that were flagged |

**Each number can be made perfect by ruining the other.** A search that returns every chunk has recall
1 and useless precision; one that returns a single sure chunk has high precision and misses whatever
else was needed. A detector that flags everything catches every bad reply; one that flags nothing is
never wrong about what it flagged, because there is nothing. That is why the two are reported
together, and why a single number that combines them, such as **F1**, their harmonic mean, hides which
one moved.

Kappa from lesson 10 was a different question: do two sets of labels agree beyond chance. A detector
can have a respectable kappa and still miss what matters, if the class it misses is small. Precision
and recall say which way it errs, and the way it errs is what decides whether it is fit for a job.
