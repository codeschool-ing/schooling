---
title: Discrete and continuous
version: 1
---

Numerical variables come in two kinds, and the difference is about **what values are possible
between two others**.

A **discrete** variable takes separate values with gaps between them. Horta's *items* is discrete: an
order holds 3 items or 4, and nothing in between. Counts are the usual case — orders per day,
complaints per week, people in a household.

A **continuous** variable can take any value in a range. *minutes* is continuous: between 34 and 35
minutes lies 34.5, between those lies 34.25, and the only limit is how finely somebody measured. Time,
weight, distance and temperature are continuous.

## The recording is not the variable

Horta's system writes delivery times to the nearest half minute: 34.5, 41.0, 52.5. Written down,
they look discrete, with gaps of 0.5. They are still continuous. The gaps belong to the
stopwatch, and a finer stopwatch would fill them.

The reverse happens too. Money is strictly discrete, because nothing is smaller than one centavo,
yet a basket of R$ 86.40 is treated as continuous in practice. The steps are so small next to the
amounts that pretending they are not there costs nothing.

So the question to ask is **what the thing itself can do**, not how the column happens to store it.

## Why the distinction matters

For describing data — the next five lessons — it matters little. A mean, a median and a standard
deviation are computed the same way for both.

It matters when you model data. A count cannot be negative and cannot be 2.7, so the right model for
"how many complaints arrive in an hour" is a different one from the model for "how long a delivery
takes". Lesson 8 gives each its distribution: the **binomial** and the **Poisson** for counts, the
**normal** for measurements that cluster around a centre.

It also matters for pictures. A discrete variable with few values is drawn as separate bars, one per
value. A continuous one is drawn as a histogram, which groups the values into intervals first;
lesson 7 shows how the choice of interval can change what the picture seems to say.
