---
title: The swamp
version: 1
---

A lake that grows without rules is called, without much affection, a **data swamp**: plenty of data, and
no way to know which of it to trust. The failures that produce one are always the same few, and each one is
something a database handles for you that a folder of files does not.

- **No transactions.** A job writing twenty files that dies after eleven leaves eleven files in the folder,
  and every reader from then on sees a partial load as if it were complete. Two jobs writing the same folder
  at once can interleave their files with nobody the wiser.
- **No updates or deletes.** Lesson 8 showed that a Parquet file is written once and never edited. Correcting
  one sale means rewriting a file, and removing a customer who asked to be forgotten means finding and
  rewriting every file that mentions them.
- **No schema enforcement.** The previous section: any file of any shape can land anywhere.
- **No history.** Overwrite a file and the old version is gone; there is no asking what the folder looked
  like yesterday, when last week's report was run.
- **The small-file problem.** A stream that writes a file every minute makes half a million files a year, and
  opening a file has a fixed cost however little is in it. Lesson 7 met this as partitions that were too fine.
- **Nobody knows what is there.** Without a catalogue, lesson 12's subject, a folder called `orders_v2_final`
  is a question rather than an answer.

None of these is about the format of the files, which is usually Parquet and fine. **They are all about the
absence of a layer above the files that says which files make up the table right now.** That layer is the
next section.
