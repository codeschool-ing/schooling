---
title: The course, chapter by chapter
version: 1
---

Each lesson of this course is a small part of ASVS, taught from the inside. The table maps them,
at the level of the section, so that a project using the course can find the requirements to
check against:

| lesson | subject | ASVS 5.0.0 sections |
|---|---|---|
| 1 | where flaws are born | V2.1, V15.1 (documenting what the application must do) |
| 2 | allowlist validation | V2.2, and V1.1 for decoding to a canonical form once |
| 3 | client and server validation | V2.2 |
| 4 | escaping by context | V1.1, V1.2 |
| 5 and 6 | injection | V1.2 |
| 7 | XSS | V1.2, V1.3, V3.2 |
| 8 | Content Security Policy | V3.4 |
| 9 | CSRF | V3.5 |
| 10 | sessions | V7.2 to V7.4, and V3.3 for cookies |
| 11 | passwords | V6.2 |
| 12 and 13 | access control, IDOR | V8.2, V8.3 |
| 14 | deserialisation and uploads | V1.5, V5.2, V5.3 |
| 15 | errors and logs | V13.4, V16.2 to V16.5 |
| 16 | secrets | V13.3 |
| 17 | dependencies | V15.2 |
| 18 and 19 | review and automated checks | how each requirement above is verified |

### Two sections, read against two lessons

Session termination is where the course's lesson 10 meets the standard's V7.4:

```
(.venv) ana@vm:~/sc/asvs$ python3 asvs.py v7.4.
V7.4.1 (L1) Verify that when session termination is triggered (such as logout or expiration), the application disallows any further use of the session. For reference tokens or stateful sessions, this means invalidating the session data at the application backend. Applications using self-contained tokens will need a solution such as maintaining a list of terminated tokens, disallowing tokens produced before a per-user date and time or rotating a per-user signing key.
V7.4.2 (L1) Verify that the application terminates all active sessions when a user account is disabled or deleted (such as an employee leaving the company).
V7.4.3 (L2) Verify that the application gives the option to terminate all other active sessions after a successful change or removal of any authentication factor (including password change via reset or recovery and, if present, an MFA settings update).
V7.4.4 (L2) Verify that all pages that require authentication have easy and visible access to logout functionality.
V7.4.5 (L2) Verify that application administrators are able to terminate active sessions for an individual user or for all users.
```

V7.4.1 is level 1 and says what lesson 10 is about: when a session ends, **the server stops
accepting it**, and an application whose sessions are self-contained tokens needs extra
machinery to manage that. V7.4.3 is the same idea applied to a password change.

And lesson 17's subject, in V15.2:

```
(.venv) ana@vm:~/sc/asvs$ python3 asvs.py v15.2.
V15.2.1 (L1) Verify that the application only contains components which have not breached the documented update and remediation time frames.
V15.2.2 (L2) Verify that the application has implemented defenses against loss of availability due to functionality which is time-consuming or resource-demanding, based on the documented security decisions and strategies for this.
V15.2.3 (L2) Verify that the production environment only includes functionality that is required for the application to function, and does not expose extraneous functionality such as test code, sample snippets, and development functionality.
V15.2.4 (L3) Verify that third-party components and all of their transitive dependencies are included from the expected repository, whether internally owned or an external source, and that there is no risk of a dependency confusion attack.
V15.2.5 (L3) Verify that the application implements additional protections around parts of the application which are documented as containing "dangerous functionality" or using third-party libraries considered to be "risky components". This could include techniques such as sandboxing, encapsulation, containerization or network level isolation to delay and deter attackers who compromise one part of an application from pivoting elsewhere in the application.
```

V15.2.1 is level 1, and it does not say "no known vulnerabilities". It says the components have
not **breached the documented update and remediation time frames**: the project writes down how
quickly it acts on an advisory, and then keeps to it. That is lesson 17's routine, stated as a
requirement somebody can check.
