---
title: The data is the hard part
version: 1
---

The lab's stock service started with the same numbers as the monolith because both keep twelve bags in
memory. A real one does not get off so lightly. The stock lives in the monolith's database, the
monolith's other modules may read it with a join, and the moment the new service takes writes, there
are two places that think they own the number of bags of coffee.

Moving the data is the part of a strangler migration that takes longest, and there is a standard
sequence for it, each step reversible:

1. **Make the module the only way in**, while it is still inside the monolith. Every other module that
   reads the stock tables directly is changed to call the stock module's interface instead. Lesson 2's
   modular monolith is the starting point that makes this step short. Fowler calls the technique of
   putting an interface in front of something before replacing it **branch by abstraction**.
2. **Give the new service a copy**, kept up to date from the monolith's database by change data capture
   (Debezium reading the write-ahead log is the usual tool) or by events from an outbox, lesson 7. The
   service answers reads from its copy; the monolith still takes the writes.
3. **Move the reads** through the facade, a share at a time, as the lab did. The copy is a lesson 9
   copy, so a read right after a write may be stale for a moment.
4. **Move the writes**, which is the step that changes who owns the data. From here the new service is
   the owner and the monolith's tables are the copy, kept in step in the other direction for as long as
   anything in the monolith still reads them.
5. **Stop the copying and drop the old tables**, when nothing reads them.

What every step avoids is **writing to both databases from the application**, the dual write: two
writes with no transaction around them, which lesson 7 showed will one day succeed on one side and fail
on the other, quietly.
