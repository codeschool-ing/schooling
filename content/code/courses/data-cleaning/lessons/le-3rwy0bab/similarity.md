---
title: How alike are two strings?
version: 1
---

**Fuzzy matching replaces "equal or not" with a score from 0 to 100.** The scores in this course
come from RapidFuzz, a Python library that implements the standard measures; SQL has its own
versions, in PostgreSQL's `pg_trgm` and `fuzzystrmatch` extensions, built on the same ideas.

The basic measure is **edit distance**: how many single-character insertions, deletions and
substitutions turn one string into the other. RapidFuzz's `ratio` turns it into a percentage of
the two lengths. Two variants matter for names:

```
ana@lab:~/clean$ python -c "from rapidfuzz import fuzz; print(fuzz.ratio('ana lima', 'ana lmia'), fuzz.ratio('ana lima', 'lima ana'), fuzz.token_sort_ratio('ana lima', 'lima ana'), fuzz.token_sort_ratio('renato p. gomes', 'renato pires gomes'))"
87.5 50.0 100.0 84.84848484848484
```

- `ratio('ana lima', 'ana lmia')` is 87.5: two letters swapped, the typo a hurried hand makes.
- `ratio('ana lima', 'lima ana')` is 50.0: the same two words in the other order, scored as half
  different, because edit distance reads left to right.
- `token_sort_ratio` sorts the words of each string before comparing, so the same pair scores
  100.0. Name order varies between forms; this measure does not care.
- `'renato p. gomes'` against `'renato pires gomes'` scores 84.8: an abbreviated middle name costs
  about fifteen points.

**A score is not a probability.** 85 does not mean "85% likely to be the same person"; it means the
strings are 85% alike by one particular measure. Whether 85 is enough depends on the file, and the
only way to know is to look at pairs near the threshold, or — in this lab — to count against the
truth, which the section after next does.

Which measure to use follows from how the field goes wrong: plain `ratio` for codes and short
values where order matters, `token_sort_ratio` for names and addresses where words move, and an
exact comparison for anything that should never be fuzzy, such as an e-mail address or a postcode
once both are plain.
