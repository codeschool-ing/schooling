---
title: The words people search for
version: 1
---

**Store search ranks apps by words, and the two stores read different words.** On the App Store,
the name, the subtitle and the hidden keyword list are what search matches; the description is
not used for it. On Google Play there is no keyword list, and the title, the short description and
the full description are all read. Ranking in both also depends on downloads, ratings and how
often people who find the app install it, none of which you write.

## Apple's keyword list

The list is one line of words separated by commas, 100 bytes in all. Apple's documentation gives
the rules plainly:

- **Each keyword longer than two characters.**
- **No space after the commas**: a space is a byte spent on nothing.
- **Do not repeat the app's name or the company's name**: search already matches them.
- **No names of other apps or companies.** A competitor's name in your keywords is a reason to
  reject the version.

The common mistakes are the opposite of those: `study, planner, study planner, study app` spends a
third of the budget on words the name already covers. `timetable,revision,exam,schedule,habit`
covers five more searches in fewer bytes.

## Google's text

With no keyword list, the words have to live in sentences. **Write for a person and include the
words a person would search for**: "Plan your study sessions and see your week's total" says what
the app does and contains *study*, *plan* and *week*. Repeating a word ten times to rank for it is
named in Google's policy as keyword stuffing, and a listing that does it can be rejected.

## The Portuguese list is a different list

A keyword list is not translated; it is **researched again**. Somebody preparing for the ENEM in
Brazil searches *vestibular*, *cronograma*, *simulado*, and none of those is the translation of an
English keyword. Each language's list is written from what people in that language type, and the
Portuguese one runs into the byte limit sooner, as the script in the next section shows.
