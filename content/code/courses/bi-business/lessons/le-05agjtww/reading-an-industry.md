---
title: Reading an industry: four questions
version: 1
---

The last five lessons of the course take BI into industries: finance here, then retail, health,
manufacturing and regulated reporting. An analyst who moves between industries does not start again
each time. **They ask the same four questions of every new industry, and the answers tell them where
the work is and where it goes wrong.** This section sets out the four, and lessons 18 to 21 use them
without explaining them again.

| | the question | what it finds |
|---|---|---|
| 1. the decisions | what decisions does this industry make over and over? | the work BI exists for: a repeated decision, answered the same way every time (lesson 1) |
| 2. the indicators | which indicators serve them? | the industry's vocabulary of numbers, each tied to one of those decisions (lessons 10 to 12) |
| 3. the data | where does the data come from, and what is odd about it? | the systems that record the work, and the habit of those records that misleads a newcomer |
| 4. the trap | which trap is typical? | the misleading indicator this industry produces most often, the lesson 12 of that industry |

## Why these four, and in this order

**The decisions come first because they decide everything else**, which is lesson 1's definition
applied to a whole industry. A lender decides thousands of times a day whom to lend to; a hospital
decides every morning which patient gets which bed. An indicator that serves none of the repeated
decisions is a curiosity, however standard it is in the industry's reports.

The indicators come second, and most industries have more than anyone can use. Each one is worth
learning with its definition, its numerator and denominator, because two companies in the same
industry often compute "the same" ratio differently, and lesson 10's card is how you find out.

**The data is the question newcomers skip**, and it is where the industry hides its peculiarities.
Every industry records its work for its own reasons, and each set of records has a habit: it arrives
late, it records only some of what happened, it is typed by hand at the end of a shift. Knowing that
habit is the difference between an analyst who reads the numbers and one who is read by them.

The trap comes last because it follows from the other three: it is what happens when an indicator from
question 2 is computed on data with the habit from question 3 and used for a decision from question 1.
Every industry has one that its experienced people know and its newcomers fall into.

@@fig:l17-four@@

## Ipê Crédito

The organisation for this lesson is invented, like every one in this course. **Ipê Crédito is a
consumer-credit company in São Paulo** that offers two products: a personal loan, paid back in
monthly instalments, which it launched in January 2024, and a credit card. Its head of BI is Fernanda
Okada. A lender is a good first industry to read, because its product is money, so almost every
number it keeps is already a number.

**The decisions.** Ipê decides, over and over: whether to approve an application, how much to lend
and at what interest rate; what limit to give a card; whether to let a card payment through or block
it as possible fraud; how much to spend to win a customer; and what to do about a customer who stops
paying. The first four happen thousands of times a day, most of them by rules and models the BI team
measures rather than runs.

**The indicators.** For the company as a whole, its income and costs as ratios of the money lent:
net interest margin, cost of risk, efficiency ratio. For lending, default rates, read by vintage. For
fraud, how many alerts are right and how many good customers each catches. For customers, their
lifetime value against what they cost to acquire. The next four sections take one each.

**The data.** Contracts and instalments come from the lending system, card payments from the card
processor, and much of what Ipê knows about an applicant from credit bureaus. **What is odd about
it is time and absence.** The outcome of a lending decision arrives months after it, when the
customer pays or stops paying. Fraud is often confirmed weeks after the payment, when the real card
holder disputes it. And an application Ipê declined is never seen again: nobody knows whether that
person would have paid, so the data only ever describes the customers Ipê chose. It is also personal
financial data, protected by the LGPD (`data-governance` lessons 6 and 7), and Ipê reports on it to the
Central Bank, which lesson 21 takes up.

**The trap.** Put the first three together. Outcomes arrive late, so the newest loans have not had
time to go wrong. A lender that is growing has a lot of new loans. **So a growing loan book looks
safe**: its default rate is low because most of it is young, not because it is good. The credit-risk
section of this lesson shows it in Ipê's numbers, and the fraud section shows the other trap of this
industry, which is that the thing being hunted is rare.
