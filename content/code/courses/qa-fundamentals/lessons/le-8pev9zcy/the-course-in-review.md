---
title: The course in one page
version: 1
---

**This course started with a sixty-year-old charged the full price, and it has been about one question since: how
does a team come to know that its software is good enough, and how does it make it so?** Twenty-two lessons later,
here is the answer the course has been building, in the order it built it.

## Quality is something a team does

- **Quality is fitness for the people who use the product**, several kinds of people with different needs, and the
  ISO 25010 characteristics are a checklist of what they might need (lessons 1 and 2).
- **Prevention is cheaper than detection, and detection is cheaper the earlier it happens.** A question asked about a
  sentence costs a reply; the same defect found by a customer costs money and trust (lessons 1 and 3).
- **Testing provides information, not guarantees.** It finds defects, it cannot prove their absence, and a tester's
  job is evidence, not suspicion (lessons 4 and 5).
- **The tester is not the guardian of *you cannot ship*.** Quality belongs to the whole team, and the tester's
  particular contribution is the questions, the cases nobody thought of, and the honesty about what is not known
  (lesson 5).

## Techniques for finding what is wrong

- **Black box** cases come from the rule: partitions, boundaries, combinations, and the inputs nobody mentioned
  (lesson 6). **White box** checks look at the code, and coverage measures what ran, not what was checked (lesson 7).
  **Grey box** testing uses what is known about the inside to aim tests from the outside (lesson 8).

## Ways of working

- The **waterfall** and the **V model** put testing at the end and pay the full cost curve (lesson 9). **Iterative**
  development shortens the loop (lesson 10). **Agile** methods make the loop short enough that testing has to be
  continuous, and give it places to happen: Scrum's events and definition of done, Kanban's limits and policies, XP's
  practices, SAFe's System Team (lessons 11 to 14).
- **TDD, BDD and ATDD** move tests before the code, at three levels: a developer's unit, a shared language, the
  story's agreed examples (lessons 15 to 17).

## Judgement

- **Root cause analysis** asks why a defect was possible, so the next one is not (lesson 18).
- **An oracle** is how a tester knows a result is right, and every oracle can be wrong (lesson 19).
- **Prioritisation** spends limited time where the risk is, and says out loud what was left out (lesson 20).
- **Entry and exit criteria** move decisions to calm moments and put the release decision with the person accountable
  for it (lesson 21).
- **Metrics** answer questions, or they turn into theatre (lesson 22).

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 220\" role=\"img\" data-fig=\"l22-course\" aria-label=\"The course in four groups. Quality, lessons 1 to 5: prevent and detect, the cost curve, evidence not suspicion, the whole team. Techniques, lessons 6 to 8: black box, white box, grey box. Ways of working, lessons 9 to 17: waterfall and V, iterative and agile, Scrum, Kanban, XP and SAFe, and TDD, BDD and ATDD. Judgement, lessons 18 to 22: root causes, oracles, priorities, entry and exit, metrics.\"><rect x=\"10.0\" y=\"10.0\" width=\"158.0\" height=\"200.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"89.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">quality</text><text x=\"89.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1–5</text><rect x=\"20.0\" y=\"60.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"89.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">prevent and detect</text><rect x=\"20.0\" y=\"89.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"89.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">the cost curve</text><rect x=\"20.0\" y=\"118.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"89.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">evidence, not suspicion</text><rect x=\"20.0\" y=\"147.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"89.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">the whole team</text><rect x=\"178.0\" y=\"10.0\" width=\"158.0\" height=\"200.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"257.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">techniques</text><text x=\"257.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6–8</text><rect x=\"188.0\" y=\"60.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"257.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">black box</text><rect x=\"188.0\" y=\"89.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"257.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">white box</text><rect x=\"188.0\" y=\"118.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"257.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">grey box</text><rect x=\"346.0\" y=\"10.0\" width=\"158.0\" height=\"200.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ways of working</text><text x=\"425.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">9–17</text><rect x=\"356.0\" y=\"60.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">waterfall and V</text><rect x=\"356.0\" y=\"89.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">iterative and agile</text><rect x=\"356.0\" y=\"118.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">Scrum, Kanban, XP, SAFe</text><rect x=\"356.0\" y=\"147.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">TDD, BDD, ATDD</text><rect x=\"514.0\" y=\"10.0\" width=\"158.0\" height=\"200.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"593.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">judgement</text><text x=\"593.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">18–22</text><rect x=\"524.0\" y=\"60.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"593.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">root causes</text><rect x=\"524.0\" y=\"89.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"593.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">oracles</text><rect x=\"524.0\" y=\"118.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"593.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">priorities</text><rect x=\"524.0\" y=\"147.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"593.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">entry and exit</text><rect x=\"524.0\" y=\"176.0\" width=\"138.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"593.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">metrics</text></svg>", "caption": "Twenty-two lessons, four groups. The first and the last are judgement; the middle is what judgement works with."}
```

## What comes next

The `manual-testing` course takes the practical half of this one further: test plans, test cases somebody else can run
without asking a question, design techniques such as decision tables and state transitions, the kinds of testing from
smoke to acceptance, and defect reports with their severity and priority. Everything there assumes the
vocabulary of this course, and most of all its stance: that a tester's work is to make sure nobody ships without knowing
what they are shipping, and that the best defects are the ones prevented by a question asked early enough.

Lia is still at Cine Aurora. On Monday the next cycle starts, the relations check is in the entry criteria, and Joana has
a new idea for the price board. Lia has four questions about it already.
