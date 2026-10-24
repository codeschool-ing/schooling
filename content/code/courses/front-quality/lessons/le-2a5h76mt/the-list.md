---
title: The OWASP Top 10, read from the front-end
version: 1
---

**The OWASP Top 10 is a list of the kinds of failure that most often let somebody do what they should
not, ranked from data about real applications.** It is a list of risks, not of requirements: it says
where to look, and the current edition is the **Top 10:2025**. Most of it happens on servers. Read from
the browser's side, it looks like this:

| | category | where the front-end meets it |
|---|---|---|
| A01 | Broken Access Control | hiding a button is not access control: the server must refuse, as lesson 5's 401 does |
| A02 | Security Misconfiguration | headers missing, debug tools shipped, the policy of lesson 8 absent |
| A03 | Software Supply Chain Failures | every package in `node_modules` runs with the page's rights; a section of this lesson |
| A04 | Cryptographic Failures | tokens in readable storage, cookies without `Secure`; lesson 6 |
| A05 | Injection | text that becomes code in the page: **cross-site scripting**, the first half of this lesson |
| A06 | Insecure Design | a defence nobody designed, such as a sign-out that does not end the login |
| A07 | Authentication Failures | lessons 5 and 6 |
| A08 | Software or Data Integrity Failures | a script loaded from a CDN with nothing to check it has not changed |
| A09 | Security Logging and Alerting Failures | CSP reports nobody collects, errors nobody hears about |
| A10 | Mishandling of Exceptional Conditions | an error page that prints a stack trace, a failure that leaves the page half done |

This lesson takes the three attacks that belong to the browser more than to anything else.
**Cross-site scripting** turns a person's text into code in somebody's page. **Cross-site request
forgery** makes a person's browser send a request they never meant to send, with their cookies. And
**clickjacking** puts a page inside another so that a click lands where the person did not see. Each is
shown in the planner with a witness that does nothing but prove the flaw, then closed, with a test that
holds it closed.

The section on the supply chain comes last, because it is the one no test of the planner's own code can
cover.
