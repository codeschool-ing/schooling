---
title: The standard as a file
version: 1
---

ASVS is published as a PDF and a Word document for reading, and as a **CSV file** for working with:
one row per requirement, with its chapter, section, identifier, text and level. A file can be
searched, counted and turned into a checklist, which is how a team uses it day to day.

This lesson's folder is `~/sc/asvs`. Download the CSV of version 5.0.0 from the project's
repository and look at its first lines:

```
(.venv) ana@vm:~/sc$ mkdir asvs
(.venv) ana@vm:~/sc$ cd asvs
(.venv) ana@vm:~/sc/asvs$ curl -sSLO https://raw.githubusercontent.com/OWASP/ASVS/v5.0.0/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.csv
(.venv) ana@vm:~/sc/asvs$ head -n 2 OWASP_Application_Security_Verification_Standard_5.0.0_en.csv | cut -c 1-100
chapter_id,chapter_name,section_id,section_name,req_id,req_description,L
V1,Encoding and Sanitization,V1.1,Encoding and Sanitization Architecture,V1.1.1,"Verify that input i
```

### A small program to read it

Python's `csv` module reads it directly. This program prints the counts per level and per chapter
when run with no argument, and every requirement whose identifier starts with a prefix when given
one. Save it as `asvs.py`:

```python
# asvs.py
import csv
import sys
from collections import Counter

FILE = "OWASP_Application_Security_Verification_Standard_5.0.0_en.csv"
ROWS = list(csv.DictReader(open(FILE, encoding="utf-8")))

if len(sys.argv) == 1:
    new = Counter(row["L"] for row in ROWS)
    print(f"{len(ROWS)} requirements")
    total = 0
    for level in "123":
        total += new[level]
        print(f"  level {level}: {new[level]:3} new, {total:3} to meet in all")
    for chapter, count in Counter(f"{r['chapter_id']} {r['chapter_name']}" for r in ROWS).items():
        print(f"  {count:3}  {chapter}")
else:
    prefix = sys.argv[1].upper()
    for row in ROWS:
        if row["req_id"].startswith(prefix):
            print(f"{row['req_id']} (L{row['L']}) {row['req_description']}")
```

```
(.venv) ana@vm:~/sc/asvs$ python3 asvs.py
345 requirements
  level 1:  70 new,  70 to meet in all
  level 2: 183 new, 253 to meet in all
  level 3:  92 new, 345 to meet in all
   30  V1 Encoding and Sanitization
   13  V2 Validation and Business Logic
   31  V3 Web Frontend Security
   16  V4 API and Web Service
   13  V5 File Handling
   47  V6 Authentication
   19  V7 Session Management
   13  V8 Authorization
    7  V9 Self-contained Tokens
   36  V10 OAuth and OIDC
   24  V11 Cryptography
   12  V12 Secure Communication
   21  V13 Configuration
   13  V14 Data Protection
   21  V15 Secure Coding and Architecture
   17  V16 Security Logging and Error Handling
   12  V17 WebRTC
```

**345 requirements in 17 chapters.** Level 1 asks for 70 of them; level 2, the portal's target,
for 253. The chapters follow the shape of an application: what comes in and goes out (V1, V2),
the browser (V3), files (V5), who you are (V6), sessions (V7), what you may do (V8), and so on to
logging (V16).

### Reading one section

Identifiers have three parts: chapter, section, requirement. `V2.2.1` is chapter V2, *Validation
and Business Logic*, section 2, *Input Validation*, requirement 1. Ask for the whole section by its
prefix, with the trailing dot so `V2.2` does not also match `V2.20`:

```
(.venv) ana@vm:~/sc/asvs$ python3 asvs.py v2.2.
V2.2.1 (L1) Verify that input is validated to enforce business or functional expectations for that input. This should either use positive validation against an allow list of values, patterns, and ranges, or be based on comparing the input to an expected structure and logical limits according to predefined rules. For L1, this can focus on input which is used to make specific business or security decisions. For L2 and up, this should apply to all input.
V2.2.2 (L1) Verify that the application is designed to enforce input validation at a trusted service layer. While client-side validation improves usability and should be encouraged, it must not be relied upon as a security control.
V2.2.3 (L2) Verify that the application ensures that combinations of related data items are reasonable according to the pre-defined rules.
```

Read V2.2.1 and V2.2.2 again with lessons 2 and 3 in mind. **Positive validation against an allow
list**, at a trusted service layer, with client-side validation encouraged for usability and never
relied upon: the course arrived at the same sentences the standard writes, which is the point of
having a standard. The next section maps every lesson to its chapter.
