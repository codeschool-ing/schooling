---
title: Following it
version: 1
---

The same runbook, followed on `pc1`, where Elisa's two invoices are stuck. Step 1:

```
ana@pc1:~$ lpstat -p office
printer office disabled since Sat Sep 26 01:15:43 2026 -
        paper jam, tray 2
```

`disabled`, with the reason `paper jam, tray 2`: this runbook applies. Step 2:

```
ana@pc1:~$ lpstat -o office
office-1                unknown           1024   Sat Sep 26 01:15:44 2026
office-2                unknown           1024   Sat Sep 26 01:15:44 2026
```

Two jobs waiting. The owners show as `unknown` because who printed what is private without `sudo`,
lesson 2; the count is what this step needs. Step 3 is a conversation, not a command: somebody by the
printer clears the jam and says so. Step 4:

```
ana@pc1:~$ sudo cupsenable office && sleep 3 && lpstat -p office
printer office is idle.  enabled since Sat Sep 26 01:15:50 2026
```

`idle` and `enabled`. Step 5:

```
ana@pc1:~$ lpstat -o office | wc -l; sudo lpstat -W completed -o office | head -3
0
office-1                elisa             1024   Sat Sep 26 01:15:50 2026
office-2                elisa             1024   Sat Sep 26 01:15:50 2026
```

**0** jobs waiting, and both invoices, Elisa's, completed. The runbook said what each step should
show, so at every step there was a way to know it had worked, and one place to stop if it had not.
