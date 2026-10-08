---
title: The working copy
version: 1
---

Lesson 16 ended with an image in `evidence/` and a custody record. That image is never opened. The analysis
starts by making a **working copy** and proving it is the same:

```
root@soc:~/case# cp evidence/files-data.dd work.dd
root@soc:~/case# sha256sum evidence/files-data.dd work.dd
4b5b35a873e1fcd4ac5199ee979949dbe57696b42da1ee379ae64cb17a85d6de  evidence/files-data.dd
4b5b35a873e1fcd4ac5199ee979949dbe57696b42da1ee379ae64cb17a85d6de  work.dd
```

Two lines, one hash. From here on everything reads `work.dd`, and if anything goes wrong, a tool that writes
where it should not or a command typed against the wrong file, the cost is one more `cp`. The hash is different
from the one in lesson 16 because the lab's disk was made again; it is the match between the two lines that
counts.

Lesson 16's disk needs to exist for this lesson. If you removed it, run that lesson's commands again, from
`python3 make_disk.py` to the `dd`.
