---
title: From abuse case to test
version: 1
---

An abuse case on a slide is read once. An abuse case in the test suite is read every time the code
changes. **The cheapest place for a threat to be caught is a failing test on the day somebody
breaks the control**, and abuse cases are already almost in the shape of one: an actor, an action,
and what the system should do instead.

### Written as acceptance criteria

Teams that write their features as scenarios, in the *given, when, then* form, can write abuse
cases the same way, beside the feature they abuse. A3 and A9 become:

```
Scenario: a patient asks for another patient's exam
  Given patient P1 is signed in
  And exam E2 belongs to patient P2
  When P1 asks for exam E2
  Then the answer is the same as for an exam that does not exist
  And the attempt is recorded with P1's account and the time

Scenario: the phone number is changed
  Given a patient is signed in
  When they change the phone number on their account
  Then the change waits for a code sent to the old number
  And an e-mail tells them the number is being changed
```

The scenarios are written in the product's vocabulary, which is the point: the product owner can
read them, disagree with them, and put them in the definition of done. Neither mentions an attack
technique. The first does not say "IDOR" and the second does not say "account takeover"; they say
what the portal must do, and a test that checks it will catch the flaw whichever way it is reached.

### Three habits that make them work

1. **Test the refusal, not only the success.** A test suite that only checks that patients can
   see their own exams passes on a portal that shows everybody's. The abuse case adds the test
   that a request for somebody else's exam is refused.
2. **Make the refusal indistinguishable.** "The same as for an exam that does not exist" is
   deliberate: an answer that says *forbidden* tells the asker that exam E2 exists, which is an
   output in the sense of lesson 6.
3. **Record the attempt.** A refusal nobody sees is a defence nobody learns from. The second line
   of the first scenario is what lets bruno notice that somebody is trying exam numbers in order.

### Back into the model

The three new threats from the previous section go into `threats.csv`, so that lesson 8 gives them
requirements like the others:

```
(.venv) ana@vm:~/tm/portal-model$ git diff --stat
 threats.csv | 3 +++
 1 file changed, 3 insertions(+)
(.venv) ana@vm:~/tm/portal-model$ tail -n 3 threats.csv
T15,Staff console,S,A former employee signs in months after leaving because nobody switched the account off.
T16,Sign in and book,I,Someone who knows a patient's password keeps reading their agenda and nothing tells the patient another session is open.
T17,Sign in and book,S,Whoever holds a session changes the phone number with no second confirmation and receives the reminders and the password resets.
(.venv) ana@vm:~/tm/portal-model$ cut -d, -f3 threats.csv | tail -n +2 | sort | uniq -c
      2 D
      3 E
      4 I
      2 R
      5 S
      1 T
(.venv) ana@vm:~/tm/portal-model$ git commit -qam 'Add the threats the abuse cases found'
(.venv) ana@vm:~/tm/portal-model$ git log --oneline -2
72b7507 Add the threats the abuse cases found
23e3e45 Draw the console as it is: reachable from the internet
```

The count by letter is worth a second look. **Spoofing went from three to five**, and both new
ones are about who holds an account: a former employee and whoever has a patient's session. Lesson
3's STRIDE pass asked who an element talks to; the abuse cases asked who the people are, and found
what the first question could not.
