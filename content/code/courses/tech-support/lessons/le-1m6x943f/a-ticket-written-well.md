---
title: A ticket the next person can use
version: 1
---

Daniel's ticket from lesson 3, written two ways. The first is common:

> *Disk full. Cleaned it. Fixed.*

The second is the same work, recorded:

```localised
Requester:  Daniel (finance), pc1, account daniel
Symptom:    cp: error writing '/srv/shared/reports/september.csv': No space left on device
Impact:     the September report cannot be saved to the shared folder
Checked:    file and folder are Daniel's (fine); echo fails the same way (not the program)
            df /srv/shared: 100% used; du: logs 55M; findmnt: local disk; dmesg: 0 errors
Cause:      logs/export.log grew until the shared disk was full; the program that
            writes it retries a connection forever and logs every try
Done:       kept the log's last 1000 lines, written to /tmp first (the first try,
            on the full disk, failed); df: 1% used
Confirmed:  Daniel saved the report himself
Pending:    owner of the export job told; empty test.txt in reports, from a check
```

The second takes a few minutes longer to write. The next time the shared folder fills, it saves the
afternoon: the cause is named, the command that failed is there so nobody tries it again, and the thing
that will fill it again has a line of its own.
