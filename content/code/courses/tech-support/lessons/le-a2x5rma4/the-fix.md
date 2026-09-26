---
title: The fix, and the fix that failed first
version: 1
---

The plan was to keep the log's last thousand lines, which is what anyone investigating the database
problem would want, and drop the rest:

```
ana@pc1:~$ sudo tail -n 1000 /srv/shared/logs/export.log | sudo tee /srv/shared/logs/export.log.keep >/dev/null && sudo mv /srv/shared/logs/export.log.keep /srv/shared/logs/export.log && df -h /srv/shared
tee: /srv/shared/logs/export.log.keep: No space left on device
ana@pc1:~$ sudo tail -n 1000 /srv/shared/logs/export.log > /tmp/export.log.keep && sudo cp /tmp/export.log.keep /srv/shared/logs/export.log && df -h /srv/shared
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       56M   92K   52M   1% /srv/shared
ana@pc1:~$ sudo -u daniel cp /home/daniel/september.csv /srv/shared/reports/ && ls -l /srv/shared/reports/
total 4
-rw-r--r-- 1 daniel daniel 34 Sep 26 00:38 september.csv
-rw-rw-r-- 1 daniel daniel  0 Sep 26 00:38 test.txt
```

**The first attempt failed for the reason it was needed.** Keeping the lines meant writing a new file
on the same disk, and the disk was full. The second attempt writes the kept lines to `/tmp`, on another
file system, and copies them back over the log; replacing the file's contents frees its space at once.
`df` now says **1%**, and Daniel's report saves.

Three things are left, and they belong in the ticket:

- **`test.txt` is empty.** It was created by the check in section 04 before the write failed. A failed
  write can leave an empty file behind, and an empty report in a shared folder is worse than none.
- **The program is still the cause.** Whatever writes `export.log` retries forever and logs every try.
  In the lab nothing is running any more; in an office, the disk fills again tomorrow unless the owner of
  that program is told, lesson 7.
- **Deleting other people's data** is a decision. This log was kept in part and nothing else was
  touched; when space is short, it is tempting to remove what looks unimportant, and lesson 14 is about
  when that is not yours to decide.
