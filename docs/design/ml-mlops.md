---
format: 5
course: ml-mlops
---

# ml-mlops

**Machine Learning and MLOps** · `co-hj6nnhy2` · 50 h declared · advanced · 10 lessons · `ai` · paid

## Reach

In **1 track** — `data-platform`(7).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `python` and `pipelines-etl` — a language, and orchestration to hang a model lifecycle on.

**Leaves ready:** **nothing.** It is the last course of `data-platform`.

## Shape

| | |
|---|---|
| declared hours | 50 h |
| lessons | 10 |
| **hours per lesson** | **5.00** |
| section budget | ~107, about 10.7 a lesson |
| exercises | ~500, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **Python, MLflow or DVC, and somewhere to deploy to** — no API key, which makes it the only course in the category that does not need one |
| browser · database | the tracking servers are browser interfaces · **yes, a feature store or a stand-in** |
| exercises **blocked** | **~400 (75%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~55 — the model lifecycle end to end, a feature store between training and serving, drift shown as two distributions separating, a retraining trigger |

## Ageing

**Low to moderate.** MLflow and DVC move slowly, and the lifecycle they serve does not.

## Flags

**1 ·** **It is in `ai` by category and in `data-platform` by every other measure**, and that is not a misfiling — it is a data engineer's view of a model rather than a modeller's. Lesson 5 says so outright: *"The data engineer's role in the model lifecycle"*.

**2 ·** **Its first four lessons duplicate `machine-learning`'s first four, and here the duplication is correct.** Supervised and unsupervised, the common tasks, splits and leakage, the accuracy trap — all four are `machine-learning` lessons 1 to 4. But `data-platform` `continues: data`, and `data` does not contain `machine-learning` (that is `data-science`), so **no student ever meets both**. This is the `continues` mechanism working exactly as designed, and it is worth recording as the positive case beside the three places where `C-28` reads the same field wrongly.

**3 ·** **Ten lessons for fifty hours — 10.7 sections each**, the widest in the category. Lesson 10 alone is drift detection and retraining. Wide lessons need an internal arc, and this course has the fewest lessons in `ai` carrying nearly the most hours per lesson.
