---
title: When retrieval is the wrong tool
version: 1
---

Retrieval answers questions whose answer is written down somewhere, in a passage short enough to
find. A surprising share of the questions people put to a company assistant are not like that, and a
retrieval system given one of them does not fail loudly. It returns three passages, the closest it
has, and the generator does its best with them.

## A question about the whole corpus

```
ana@lab:~/rag$ python sections.py "Which documents mention a 14-day limit?"
[1] 0.414  privacy-notice > How long we keep it
[2] 0.410  returns-policy > The return window
[3] 0.348  terms-of-sale > 6. The right of withdrawal
The sources do not say.
ana@lab:~/rag$ grep -l "14 days" data/docs/*.md
data/docs/ebooks-and-audiobooks.md
data/docs/returns-policy-2025.md
data/docs/returns-policy.md
data/docs/seller-agreement.md
```

`grep` read every document and answered in a line per match: four documents. The search returned
three sections, none of which contains the phrase, because **a question about which documents say
something is a question about all of them**, and a search returns the few nearest. Even a perfect
search with k = 3 could not list four documents, and nothing in its output says it was cut short.
extract-1 refused this time, because no sentence was similar enough. A real model given those three
sections might have named them as the answer, a confident partial list with citations.

## A question about everything

```
ana@lab:~/rag$ python sections.py "Summarise all of our policies"
[1] 0.272  support-handbook > How we write
[2] 0.227  terms-of-sale > 10. Personal data
[3] 0.202  privacy-notice > What we collect
Quote the policy in your own words and link the help centre article. [1]
```

The best match scored 0.272, close to the floor, and the reply is a sentence about how support agents
write. A summary of every policy needs every policy read. The tool for that is a batch job that reads
each document, summarises it, then summarises the summaries, run when the documents change and stored
like any other document. Lesson 15 builds the summarising step for conversations, and the same
method serves documents.

## Three kinds of question that belong elsewhere

| the question | what it needs | where it goes |
| --- | --- | --- |
| *How many refunds did we issue in February?* | a count over records | a database query |
| *Which documents mention a 14-day limit?* | every document, exactly | a lexical search with no cut-off |
| *What is the status of order MG-20481937?* | live data about one record | an API call |
| *Summarise every policy* | the whole corpus, read once | a batch job, stored as a document |

The first and third are not about text at all. The refund count lives in the payments database and
the order status in the order system, and both change by the minute. Copying them into documents so a
retrieval system can find them gives you stale numbers with citations. The right design calls the
database or the API directly, often as a tool the model can use, which is the subject of the course
after this one, `agents-mcp`.

## Telling them apart in practice

A system that serves real questions meets all of these kinds, so the job is not to refuse them but to
route them. Three signals help.

**The best score is low.** Every question in this section had a top score under 0.42, against 0.72
for the fraud question and 0.698 for the express question in lesson 1. A low top score says nothing
matched well, which is the case lesson 6 teaches a search to report.

**The question asks for a count, a list, a total or all of something.** *How many*, *which ones*,
*every*, *all*. Words like these mark a question about the corpus or a database, and a classifier, or
a simple rule, can send it elsewhere before retrieval runs.

**The answer would be a number that changes daily.** If the true answer next week is different from
today's and no document was edited, the answer was never in a document.
