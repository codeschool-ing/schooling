---
title: What enrichment is
version: 1
---

**Enrichment** is adding columns from a source outside the data set: a region for each state, an
official code for each city, a flag for each date that was a public holiday, an exchange rate for
each invoice. Lesson 7 has already done it once, when it converted the invoices with the rates the
finance team booked. This lesson treats it as a technique of its own, because it brings risks the
other lessons do not.

Mechanically, enrichment is a join, and everything lesson 11 said applies: check the key on both
sides, use `validate`, count the rows that found no partner. What is new is the far side of the
join. **The reference table is somebody else's data**, and it arrives with four questions attached:

- **Who published it**, and is it the authority for what it claims? A list of state codes from the
  national statistics office is; the same list copied into a blog post is not.
- **When**, and does it change? State codes have been stable for decades; holidays change by law,
  and a list made last year can be wrong this year.
- **Under what terms** may it be used, copied and passed on with your results?
- **What did you send to get it?** Downloading a public file sends nothing. Calling a web service
  with your customers' postcodes sends personal data to whoever runs it.

The lab keeps three reference files in `ref/`, and unlike everything in `raw/` they are real:
the IBGE codes for the 27 federative units and for the five cities the company serves, and the
national holidays and optional days of 2025. They were typed into the lab from the published lists,
which is itself a provenance fact worth recording, and the fifth section of this lesson records it.

Enrichment also cleans. A column with thirteen spellings of four states, matched against the
official list, comes out as four codes; a city column with twenty-eight spellings of five cities
comes out as five IBGE codes.
**A reference table is the strongest normalisation there is**, because the target spellings were
not chosen by you.
