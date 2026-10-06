---
title: Choosing, and what does not depend on the choice
version: 1
---

Five ways to build the same thing have now been met: the provider's SDK with a database driver
(lesson 9), LangChain and LlamaIndex (lesson 10), Haystack and RAGFlow (this lesson). The comparison
that matters is not which one retrieves better. Measured with the same test, every library in this
course landed within a few questions of lesson 5's index once its settings were chosen for the
corpus, because the result belongs to the settings and the settings belong to the corpus. The differences are in what each one makes easy, what it
makes visible, and what it leaves for the team to own.

| | what it is | strongest at | what to check first |
| --- | --- | --- | --- |
| SDK and driver | about a hundred lines of your own | every decision in sight, nothing between you and the request | that you wrote the parts lessons 4 to 8 measured |
| LangChain | a library of parts joined into chains | connectors to almost any store and provider | splitter size, embedding client's input, ids, the meaning of a score |
| LlamaIndex | a library built around an index | retrieval techniques ready to use: windows, merging, citation engines | where the clients point, the default prompt |
| Haystack | a library of typed components in a declared graph | pipelines that are checked when built and stored as files | the duplicate policy, ids that include metadata |
| RAGFlow | a server application with a web interface | difficult documents, people who are not developers | where the corpus now lives, who may see what |

Three questions usually decide it, in this order.

**Who builds and changes it?** A pipeline inside a product, changed by its developers, behind its
permissions, is code: the SDK, or one of the three libraries. A knowledge base that a support team
fills and queries itself is an application, and writing one from scratch to avoid deploying
RAGFlow is a project of its own.

**What are the documents?** Markdown and HTML need a splitter and some care. Scanned contracts and
PDFs with tables need a parser, and that is where an application built around parsing earns its
servers, or where a team adds a parsing step in front of whichever library it chose.

**How much can be hidden?** Lesson 7's citations, lesson 6's filters and lesson 5's ids are the
parts that make an answer checkable. Any tool is fine where those are visible and set by the team,
and none is where they are defaults nobody has read.

## What does not depend on the choice

Whichever it is, these stay the same, and they are the rest of this course:

- the test set from lesson 8, run from outside the tool, before and after every change;
- what goes into the prompt and in what order, which lesson 12 measures;
- the conversation's history and what is remembered between turns, lesson 13;
- who may retrieve which document, lesson 14, which is a property of the data and never of a
  framework's default;
- what is summarised and what is kept, lesson 15;
- keeping one task's text out of another's, and text from outside out of the instructions, lesson 16;
- and what each query costs, lesson 17.

Lessons 12 to 16 are written with the plain SDK and the database, so that nothing hides what they
measure. Every one of them can be built inside any of the tools above, and the test is how you would
know it was built right.
