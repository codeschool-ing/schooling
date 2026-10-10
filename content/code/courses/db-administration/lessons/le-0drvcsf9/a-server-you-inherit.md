---
title: The first day with a server you did not build
version: 1
---

Most administrators meet most of their servers already running. Somebody else installed them,
somebody else configured them, and the person who knew why is often no longer around. **The first
day is an inventory**, and it is the same list whatever the engine: answer each question, write the
answer down with the date, and only then change anything.

| question | why it matters | where the course answers it |
|---|---|---|
| Which version, exactly, and is it still supported? | a version past its end of life gets no security fixes | lesson 3 reads the version string; lesson 20 is about moving on |
| Where are the data files, the configuration and the log? | everything else starts from here, and on a packaged server they are three different places | lessons 4 and 5 |
| Which settings differ from the defaults, and does anybody know why? | a setting nobody can explain is either a fix nobody wrote down or a mistake nobody noticed | lessons 5, 6 and 23 |
| Who can connect, from where, and as whom? | the most common hole is an account with more rights than its job, and a password everyone knows | lessons 5, 11, 12 and 13 |
| How big is it, how fast is it growing, and how much room is left? | the date the disk fills is a fact you can calculate today | lessons 4 and 9 |
| Is maintenance keeping up? | a table autovacuum has been losing to for months is a slow outage | lessons 14 to 17 |
| What does the log say? | a server usually complains for weeks before it fails | lesson 19 |
| When was the last backup restored, and how long did it take? | the only backup question with a useful answer | `db-reliability` lessons 1 and 7 |

None of these needs a change to the server, and that is deliberate. **On the first day nothing is
fixed**, however wrong it looks, because a setting that looks wrong may be holding up something you
have not found yet. The inventory comes first; the list of things to change comes from the
inventory, in order of risk.

## Writing it down

The answers go somewhere the next person will find them: a page in the team's documentation, a file
in a repository, a ticket. A useful inventory is dated, says how each answer was obtained (the
command, not just the result), and says what is not known yet. That last part matters most. "No
backup restore on record" is a finding; leaving the line out lets the next reader assume somebody
checked.

Lesson 24 is about the other document an administrator keeps — the runbook — and the inventory is
where it starts: you cannot write down how to recover a server whose shape you never wrote down.
