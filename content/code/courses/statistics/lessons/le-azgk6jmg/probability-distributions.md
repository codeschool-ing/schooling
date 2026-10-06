---
title: From data to a model
version: 1
---

A **probability distribution** is a rule that says how likely each possible value of something is, before you see it. It is the model counterpart of a histogram: a histogram describes values that have happened, a distribution describes values that might.

The thing whose value is uncertain is called a **random variable**. How many of tonight's ten deliveries will be late? How many complaints will arrive tomorrow? How much will the next bag of rice weigh? Each question has a random variable behind it, and each kind of random variable has a kind of distribution that fits it.

## Discrete: a probability for each value

When the random variable is a count — late deliveries, complaints — it takes separate values, 0, 1, 2 and so on, and the distribution gives each of them a probability. The probabilities are all between 0 and 1 and **add up to 1**, because one of the values must happen.

Such a distribution is drawn as bars, one per value, and the height of each bar is a probability rather than a count.

## Continuous: probability is area

When the random variable is a measurement — a weight, a time — it can take any value in a range, and the chance of any single exact value is zero. The chance that a bag weighs exactly 1003.000000 g is nil, because there are infinitely many weights near it.

So a continuous distribution is drawn as a curve called a **density**, and **a probability is an area under that curve**. The chance that a bag weighs less than 995 g is the area under the curve to the left of 995. The whole area under the curve is 1.

The height of a density curve is not a probability. It says where values are crowded, as the height of a histogram bar does, but only an area between two points answers a question of the form "how likely is it that the value falls between here and there?".

## Why bother with a model

A model is a simplification, and its value is what it lets you do.

- It **answers questions the data never asked**. Sixty days of complaints might never have produced a day with seven; a model can say how often such a day should be expected.
- It **compresses**. A whole distribution described by one or two numbers — a mean, a standard deviation, a rate — can be compared, reported and reasoned about.
- It **makes inference possible**. Lessons 11 to 16 rest on knowing the distribution of a statistic, and that distribution is almost always one of the models in this lesson.

A model is only as good as its fit to the data. The last section of this lesson is about checking that.
