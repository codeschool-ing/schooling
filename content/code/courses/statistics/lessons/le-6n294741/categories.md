---
title: Categories in a model
version: 1
---

Lesson 2 promised a way to put a categorical variable, such as the neighbourhood, into a calculation without pretending its labels are numbers. Here it is.

## Dummy variables

A category with *k* levels becomes *k* − 1 columns of zeros and ones, called **dummy variables** or **indicators**. For the four neighbourhoods, with Centro as the **reference**:

| neighbourhood | Cambuí | Taquaral | Barão Geraldo |
|---|---|---|---|
| Centro | 0 | 0 | 0 |
| Cambuí | 1 | 0 | 0 |
| Taquaral | 0 | 1 | 0 |
| Barão Geraldo | 0 | 0 | 1 |

Centro is the row of zeros. There is no fourth column, because it would always equal one minus the sum of the other three, and the regression could not separate it from the intercept.

## What the coefficients mean

A regression of minutes on the three dummies gives:

**predicted minutes = 30.60 + 1.35 × Cambuí + 7.62 × Taquaral + 23.22 × Barão Geraldo**

The intercept is Centro's mean, 30.60 minutes. Each coefficient is that neighbourhood's **difference from Centro**: Cambuí's mean is 30.60 + 1.35 = 31.95, Taquaral's 38.22, Barão Geraldo's 53.82. A regression on dummies alone reproduces the group means of lesson 16's ANOVA, and its F test is the same test.

## Adding distance

Put distance into the same model and the neighbourhood coefficients collapse: **−1.03**, **−0.26** and **−0.69** minutes, none distinguishable from zero (p = 0.38, 0.87 and 0.86), while distance keeps a slope of 2.51 minutes per kilometre.

Barão Geraldo was 23 minutes slower than Centro, and the model says the 23 minutes are distance. The data shows no sign that a delivery to Barão Geraldo takes longer than any other delivery of the same length. The neighbourhood mattered only because of where it is.

## Choosing the reference

The reference level is a choice, and it changes the coefficients but not the predictions. With Barão Geraldo as the reference, every coefficient would be a difference from Barão Geraldo. Choose the level that makes the comparisons you care about easiest to read, usually the most common one or a natural baseline.
