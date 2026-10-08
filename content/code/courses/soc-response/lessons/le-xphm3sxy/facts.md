---
title: Facts, with their sources
version: 1
---

A fact in a report is a sentence and a source. For the numbers, the source is best made a file: one query per
number, numbered, so the report can say "57 guesses (fact 1)" and an auditor can run fact 1 again. Write this as
`facts.sql` in `~/week`:

```sql
-- facts.sql: every number the report states, each from one query, numbered so the report can cite it
.headers on
.mode column
SELECT 1 AS n, 'password guesses from 203.0.113.66' AS fact, count(*) AS value
  FROM logs WHERE src_ip = '203.0.113.66' AND action = 'failure'
UNION ALL
SELECT 2, 'accounts those guesses named', count(DISTINCT user)
  FROM logs WHERE src_ip = '203.0.113.66' AND action = 'failure'
UNION ALL
SELECT 3, 'successful logins from 203.0.113.66', count(*)
  FROM logs WHERE src_ip = '203.0.113.66' AND action = 'success'
UNION ALL
SELECT 4, 'hosts reached by bruno that night', count(DISTINCT host)
  FROM logs WHERE user = 'bruno' AND action = 'success'
   AND timestamp BETWEEN '2026-09-17 05:00' AND '2026-09-17 06:30'
UNION ALL
SELECT 5, 'bytes from files to 203.0.113.200', sum(bytes)
  FROM logs WHERE product = 'flow' AND src_ip = '192.168.20.10' AND dst_ip = '203.0.113.200'
UNION ALL
SELECT 6, 'the same, in MB (10^6 bytes)', round(sum(bytes) / 1e6)
  FROM logs WHERE product = 'flow' AND src_ip = '192.168.20.10' AND dst_ip = '203.0.113.200';
```

Each `SELECT` is one fact, and `UNION ALL` stacks them into one table. Run it against lesson 4's SIEM, and hash
both the database and the queries, so the appendix can name exactly which data and which questions the numbers
came from:

```
ana@soc:~/week$ sqlite3 siem.db < facts.sql
n  fact                                 value    
-  -----------------------------------  ---------
1  password guesses from 203.0.113.66   57       
2  accounts those guesses named         19       
3  successful logins from 203.0.113.66  2        
4  hosts reached by bruno that night    2        
5  bytes from files to 203.0.113.200    612408119
6  the same, in MB (10^6 bytes)         612.0    
ana@soc:~/week$ sha256sum siem.db facts.sql
8804ccde7f44b2db5934be6be962e31dd42f006b566bf5d45e0a1bc629a9ea8d  siem.db
c65f6fdec8c26b0f6e82160d85770d9f277df831ba2fd4b8baf38561e03a49a8  facts.sql
```

Six facts, and the report's body can now state them plainly: **57 password guesses** from one address, naming **19
accounts**; **2 successful logins** from it, both bruno's; **2 company hosts** reached; and **612,408,119 bytes**,
612 MB, sent from the file server to `203.0.113.200`. Fact 6 says what "MB" means, because a report that mixes
decimal megabytes and binary mebibytes is wrong by five percent in the direction nobody notices.

Facts that are not numbers get the same treatment, with the source named: "bruno logged in normally from his usual
address at 08:35 (SIEM, sshd log of `gw`)"; "the deleted export of client contacts was recovered from the file
server's disk image (image 001, inode 24, SHA-256 in appendix C)".

**A fact is what the evidence shows, and nothing more.** "Bruno's password was guessed" is an inference, a very
strong one: 57 failures across 19 accounts, then success on one. The report can say it, with the word
"inferred" and the reason, and keep it apart from the measured facts above it.
