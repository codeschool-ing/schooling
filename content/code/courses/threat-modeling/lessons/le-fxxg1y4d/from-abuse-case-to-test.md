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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l07-refusal\" aria-label=\"The refusal an abuse-case test demands. Patient P1 asks for exam E2, which belongs to patient P2, and separately for an exam that does not exist. The portal gives the same answer to both, so the asker learns nothing about whether E2 exists, and the first attempt is recorded with P1’s account and the time.\"><defs><marker id=\"l07-refusal-tm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-refusal-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"28.0\" width=\"280.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">P1 asks for E2 (P2’s exam)</text><path d=\"M300.0 50.0 L400.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-refusal-tm-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"108.0\" width=\"280.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">P1 asks for an exam that does not exist</text><path d=\"M300.0 130.0 L400.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-refusal-tm-ah-paper-dim)\"></path><rect x=\"400.0\" y=\"65.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"480.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the same answer</text><rect x=\"400.0\" y=\"150.0\" width=\"300.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recorded: P1’s account and the time</text><path d=\"M330.0 62.0 L400.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-refusal-tm-ah-amber)\"></path><text x=\"630.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">nothing learnt</text></svg>", "caption": "A “forbidden” would confirm that E2 exists. Answering as for a missing exam turns the refusal into nothing an asker can use."}
```

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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l07-by-letter\" aria-label=\"Threats in threats.csv by STRIDE letter after the abuse cases: S 5, T 1, R 2, I 4, D 2, E 3. Spoofing went from three to five, both new ones about who holds an account.\"><rect x=\"80.0\" y=\"30.0\" width=\"60.0\" height=\"140.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"110.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">S</text><rect x=\"180.0\" y=\"142.0\" width=\"60.0\" height=\"28.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"210.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">T</text><rect x=\"280.0\" y=\"114.0\" width=\"60.0\" height=\"56.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"310.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">R</text><rect x=\"380.0\" y=\"58.0\" width=\"60.0\" height=\"112.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"410.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">I</text><rect x=\"480.0\" y=\"114.0\" width=\"60.0\" height=\"56.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"510.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">D</text><rect x=\"580.0\" y=\"86.0\" width=\"60.0\" height=\"84.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"610.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">E</text><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">S was 3 before the abuse cases; T15 and T17 made it 5</text></svg>", "caption": "STRIDE asked who an element talks to; the abuse cases asked who the people are, and the S column grew."}
```
