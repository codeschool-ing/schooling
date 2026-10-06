---
title: Three kinds of evidence
version: 1
---

Lesson 8 called authentication proving a claim. There are only three kinds of evidence a person can
offer, and they are called **factors**:

| factor | what it is | examples | how it is lost |
|---|---|---|---|
| **something you know** | a secret in your head | a password, a PIN, an answer to a security question | phishing, reuse on a breached site, guessing, a shoulder |
| **something you have** | an object in your possession | a phone with an authenticator app, a security key, a smart card | theft, loss, a SIM swap |
| **something you are** | a property of your body | a fingerprint, a face, a voice | hard to change once copied |

**Multi-factor authentication (MFA)** asks for evidence of **more than one kind**. **Two-factor
authentication (2FA)** is the most common case: exactly two. The point is in the word *kind*. Each
kind is lost in a different way, so an attacker who has one, ana's password from a breached site,
still lacks the other, her phone in her pocket. That is lesson 4's independence of layers, applied to
a login.

### What does not count

**Two passwords are one factor.** A password and a security question ("your mother's maiden name")
are both something you know, and both are lost the same way: a phishing page asks for both, and a
researcher finds the second on social media. The login is longer, and no stronger in kind.

**A code sent to your email is a weak "something you have".** It proves you can read the mailbox,
and if the mailbox uses the same password as the account, both fall together.

**Location and behaviour are signals, not factors.** "The request comes from Brazil" or "she types
at her usual speed" can raise or lower suspicion, as the Zero Trust decisions of lesson 7 do, but
nobody proves who they are by being somewhere.

### Why it matters so much

Most account takeovers start with a password the attacker already has: reused from another site's
breach, guessed, or typed by the victim into a fake login page. Microsoft reported in 2019 that MFA
would have blocked over 99.9% of the account compromise attacks it saw. The exact figure depends on
what is counted, and the direction is not in doubt: **a second factor turns a stolen password from a
breach into a failed login.**

That is also why it is the first step of the Zero Trust order in lesson 7, and the first mitigation
of the shop's R1 in lesson 3: the portal's password stops being the whole lock.
