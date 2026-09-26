---
title: Fixing it, and saying what happened
version: 1
---

The fix is one command, as Bruno, and the check is his own print:

```
ana@pc1:~$ sudo -u bruno lpoptions -d office >/dev/null && sudo -u bruno lpstat -d
system default destination: office
ana@pc1:~$ sudo -u bruno bash -c "cd ~ && lp report.txt"
request id is office-5 (1 file(s))
```

His default is `office` again, and `report.txt` went to `office`. What is left is telling him, and the
words decide whether he opens the next ticket or struggles alone:

- **Describe the setting, not the mistake.** *"Your computer was set to send documents to the PDF
  printer, so they were saved as files instead of printed. I've set it back."* Everything in it is
  true, and nobody in it did anything wrong.
- **Show him where it happened**, so the next time the window appears he knows what it asks. That is a
  minute, and it is what stops the same ticket next month.
- **Thank him for the detail about the window.** It was the most useful thing anyone said in the
  ticket, and people repeat what gets thanked.

Lesson 4 is about explaining without jargon and without belittling anyone, and it starts from here.
