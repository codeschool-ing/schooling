---
title: Answering why
version: 1
---

*Why did you do it that way?* has a good answer in four steps, and it takes about twenty seconds:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"An answer to the question why SQLite, in four steps from left to right. The choice: SQLite, one file. The alternative: a database server. The reason: one room, one server, and a backup is a copy. What would change it: several schools sharing one instance.\"><defs><marker id=\"an20-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">&quot;Why SQLite?&quot;</text><rect x=\"20\" y=\"40\" width=\"160\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the choice</text><text x=\"32\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">SQLite, one file</text><path d=\"M181 85 L195 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#an20-ah)\"></path><rect x=\"196\" y=\"40\" width=\"160\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"208\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the alternative</text><text x=\"208\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a database server</text><path d=\"M357 85 L371 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#an20-ah)\"></path><rect x=\"372\" y=\"40\" width=\"160\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"384\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the reason</text><text x=\"384\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one room, one server,</text><text x=\"384\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">backup is a copy</text><path d=\"M533 85 L547 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#an20-ah)\"></path><rect x=\"548\" y=\"40\" width=\"160\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">what would change it</text><text x=\"560\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">several schools</text><text x=\"560\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sharing one instance</text></svg>", "caption": "Four steps, about twenty seconds spoken. The last one is the one that turns a defence into a conversation: it tells the interviewer you know where the choice stops being right."}
```

**The choice**, in a few words, so the interviewer knows you understood the question. **The alternative**
you had, which shows you knew there was one: a database server, a framework, accounts. **The reason**, in
the project's own facts, not in general truths: *one room, one server, and a backup is a copy of a file*,
not *SQLite is simpler*. And **what would change it**: the condition under which the other choice becomes
right.

The fourth step is the one most candidates leave out, and it does the most work. Without it, the answer is
a defence of a choice, and the interviewer's next question is an attack on it: *but what if there were a
thousand users?* With it, you have already said where the choice stops being right, and the next question
becomes a conversation about that point, which is exactly the conversation they want.

Two ways to spoil it. **Arguing that the alternative is bad**: *database servers are overkill* is a claim
about the world, and the interviewer may run one for a living. And **saying you did not have a reason**
when you did: *I just used what I knew* is honest when true, and it is worth adding *and here is when I
would not*. The README's decisions section, lesson 16, is where these answers were first written; read it
before every interview.
