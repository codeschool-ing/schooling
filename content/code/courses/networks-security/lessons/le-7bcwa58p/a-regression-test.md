---
title: A test that runs the whole matrix
version: 1
---

Every mistake in this lesson has one thing in common: **the rule set loaded, and the network still
seemed to work.** The shadowed quarantine, the wide mask, the impossible rule, the unreachable one;
each was found only because somebody tried the specific traffic. That is lesson 4's matrix test, and
the step that turns it from a habit into a safety net is writing it down and running it after every
change.

The expected result of each cell is a text file, one line per cell, from where the traffic starts:

```
$ cat matrix.expected
remote  www:443      open
remote  app:8080     blocked
remote  db:5432      blocked
laptop  app:8080     open
laptop  app:22       blocked
laptop  db:5432      blocked
admin   app:22       open
admin   app:8080     blocked
www     app:8080     open
www     db:5432      blocked
```

The test is a short script that tries each line from the machine it names and prints only the cells
whose result differs:

```schooling-example
{"language": "sh", "file": "matrix-test.sh", "parts": [{"code": "#!/bin/bash\n# Try every cell of matrix.expected from the machine it starts on,\n# and print each cell whose result differs from what was expected.\nfail=0", "note": "Silence means the matrix holds. A test that prints every passing cell buries the one that failed."}, {"code": "while read -r from target want; do\n  got=$(bash /var/tmp/nslab.sh exec \"$from\" ana \"probe $target\" | awk '{print $2}')", "note": "In the lab, `lab.sh exec` runs `probe` on the machine in the first column, so the connection really starts in that zone. On real equipment this line is an SSH command to a small test machine in each zone, or a monitoring agent that can open connections."}, {"code": "  if [ \"$got\" != \"$want\" ]; then\n    printf '%-7s %-12s expected %-8s got %s\\n' \"$from\" \"$target\" \"$want\" \"$got\"\n    fail=1\n  fi\ndone < matrix.expected\nexit $fail", "note": "Any difference is printed and makes the exit code 1, so the test can gate an automated change: if it fails, the change is rolled back before anybody is paged."}]}
```

It runs on the lab's own host, the one machine that can start a connection from every zone. Against
the rule set that still carries the `/16` mistake of this lesson's second section:

```
$ bash matrix-test.sh; echo "exit $?"
laptop  app:22       expected blocked  got open
exit 1
```

**One line: the cell that the wide mask opened**, and an exit code of 1. After reloading the baseline:

```
$ bash matrix-test.sh; echo "exit $?"
exit 0
```

Silence, and 0. Ten cells take a few seconds. A real matrix has more, and the test grows with it; the
cost of running it is always smaller than the cost of the one cell nobody tried.
