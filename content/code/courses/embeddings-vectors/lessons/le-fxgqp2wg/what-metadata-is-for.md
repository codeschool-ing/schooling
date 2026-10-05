---
title: What metadata is for
version: 1
---

A vector answers one question: *what is this text about?* Most real searches ask a second one at
the same time: articles about returns *in Portuguese*; messages like this one *from the last
week*; documents about the contract *that this user is allowed to read*. The second question
has an exact answer, and a vector is the wrong tool for it. That answer comes from **metadata**:
ordinary fields stored beside the vector and tested with ordinary comparisons.

Every article in the help centre carries three such fields: a language, a category and the date it
was last updated.

```
ana@lab:~/emb$ jq -r .lang data/help.jsonl | sort | uniq -c
     37 en
      3 pt
ana@lab:~/emb$ jq -r .category data/help.jsonl | sort | uniq -c
      7 account
      6 ebooks
      6 orders
      6 payments
      7 returns
      8 shipping
```

## The fields a search usually needs

The fields that turn up again and again fall into a few kinds, and each one is a condition no
amount of similarity can stand in for:

| field | the question it answers |
|---|---|
| language | can this reader read it? |
| category, product, section | is it the kind of thing they are looking at? |
| date | is it current, or within the period asked for? |
| price, stock, availability | can they buy it? |
| tenant, owner, permissions | **are they allowed to see it at all?** |

The last row is different in kind from the others, and the last section of this lesson is about
it. A wrong language is a bad result. A row from another customer's account is a leak.

**Why not let the vector carry it?** The tempting shortcut is to write the field into the text
before embedding, *Language: Portuguese. Como devolver um livro*, and hope the search sorts it
out. Lesson 1 showed what that hope is worth: all-MiniLM-L6-v2 scored *How to return a book*
against its own Portuguese translation as two unrelated texts. Similarity is a matter of degree, and *is
this in Portuguese* has a yes or no answer. A filter gives the exact answer every time.

## Stored beside the vector

Lesson 11 described a record as an id, a vector and its metadata, and every database in lessons 12
to 14 stores them that way: Chroma's `metadatas`, LanceDB's columns, Qdrant's payload, PostgreSQL's
ordinary columns. Keep the fields as typed values (a date as a date, a price as a number) so that
a filter can compare them, and keep them on the same record as the vector so that a filter and a
search can run in one request.

The question the rest of this lesson answers is how the two run together, because there are two
orders to do it in, and they do not give the same results.
