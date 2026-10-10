---
title: The repeat-back test
version: 1
---

A strategy does its work when somebody makes a decision without the page in front of them: a tech
lead planning a sprint, an engineer choosing whether to ship on a Thursday before an on-sale. So the
test of the page is whether people carry it in their heads. **Ask five people to say it back, in
their own words, and listen to what comes out.** A page they cannot repeat is not doing its job,
however well it is written.

## What does not tell you

The usual evidence that a strategy has landed is that it was published. It went to every engineer
in a message, Helena presented it at the all-hands, the document shows that most of the company
opened it. **None of that measures whether anybody can use it.** Opening a document is not reading
it, and reading it is not remembering what it rules out.

Asking "is the strategy clear?" is no better. Almost everybody says yes, partly from politeness and
partly because the question asks them to admit, in front of the author, that they did not follow.
The answer measures the relationship, not the page.

## How to run it

Wait a week or two after the page goes out, long enough for the first read to fade. Pick five
people who did not help write it, across teams and levels: an engineer, a tech lead, somebody from
product, somebody who joined recently. Ask each of them, on their own and without the page, three
questions:

1. In a sentence, what is our technical strategy?
2. Name one thing we are not doing this year because of it.
3. A situation the page does not mention, and what the strategy says about it.

The third question is the one that matters most. A person can memorise a sentence; **only somebody
who understood the policy can apply it to a case it does not list.** For Coreto, Davi used: "Mobile
wants to change the seat-hold timeout in the app the week before a big on-sale. What does the
strategy say?" The answer he was listening for: it touches the seat-hold path, so it needs the
Reservations team's review and a load-test result, and it cannot go out in the 24 hours before the
on-sale.

Write down what each person says, in their words. The paraphrase is the data; a tick in a box loses
the part that tells you what to fix.

## Coreto's first round

The first version of Davi's page had the title *Coreto technical strategy*, the policy in its
second paragraph, and the not list at the bottom, below the measures. Two weeks after it went out,
he asked five people:

| who | question 1, in their words | question 2 | question 3 |
|---|---|---|---|
| Box Office engineer | "Reliability, I think. And paying down tech debt." | could not name one | "Ask the Reservations team?" |
| Mobile tech lead | "Protect the on-sales: nothing on the reservation path without a load test." | no microservices | review, load test, and not in the 24 hours before |
| Data engineer | "The seat holds get their own team." | could not name one | not sure it applied to Mobile |
| Catalogue product manager | "Fix checkout for big on-sales before anything else." | the framework pilot is off | needs the load test first |
| Payments engineer | "We're moving off the monolith, slowly." | could not name one | "Probably fine if it's small." |

Two of the five said back the policy, two named something on the not list, and two applied it to
the timeout correctly. **The two who passed were the two whose work the strategy had changed.** The
Mobile tech lead had been told his gateway was off; the product manager had lost her pilot. The
other three had read the page once, and kept what fitted what they already believed.

The Data engineer remembered an action and took it for the strategy. The Box Office engineer
remembered the words of the first draft, which had circulated for weeks before the second. **The
Payments engineer said the opposite of the page**: no migration this year had become a slow
migration. That answer is the most useful one in the table. It means a version of the strategy is
going round that nobody wrote, and that version will make decisions until it is corrected.

## What Davi changed

The failures pointed at the page and at how it was delivered, not at the five people.

- The policy moved into the title: *Coreto technical strategy: protect the on-sale first.*
  Everybody who opens the page, or sees a link to it, reads the policy before anything else.
- The not list moved above the measures, next to the actions, so that what the company is doing
  and what it is not doing are read together.
- He read the page aloud at each team's next planning meeting and took questions, instead of
  relying on the message and the all-hands. It took a morning of his time across the teams.

A month later he asked five different people the same three questions.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 324\" role=\"img\" aria-label=\"Two grids of five people by three questions: the policy in their own words, one thing on the not list, and the new case about the seat-hold timeout. First round, with the first page: two of five pass each question, the same two people each time. Second round, five different people after the changes: four of five on the policy, four of five on the not list, three of five on the new case.\"><rect x=\"20\" y=\"14\" width=\"330\" height=\"262\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"185\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">First round: the first page</text><text x=\"160\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">policy</text><text x=\"230\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">not list</text><text x=\"300\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">new case</text><text x=\"36\" y=\"96\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">person 1</text><rect x=\"151\" y=\"82\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"221\" y=\"82\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"291\" y=\"82\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"128\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">person 2</text><rect x=\"151\" y=\"114\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"221\" y=\"114\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"291\" y=\"114\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">person 3</text><rect x=\"151\" y=\"146\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"221\" y=\"146\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"291\" y=\"146\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"192\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">person 4</text><rect x=\"151\" y=\"178\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"221\" y=\"178\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"291\" y=\"178\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"224\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">person 5</text><rect x=\"151\" y=\"210\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"221\" y=\"210\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"291\" y=\"210\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><path d=\"M32 242 L338 242\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"160\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">2 of 5</text><text x=\"230\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">2 of 5</text><text x=\"300\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">2 of 5</text><text x=\"36\" y=\"264\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">total</text><rect x=\"370\" y=\"14\" width=\"330\" height=\"262\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"535\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Second round: after the changes</text><text x=\"510\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">policy</text><text x=\"580\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">not list</text><text x=\"650\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">new case</text><text x=\"386\" y=\"96\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">person 1</text><rect x=\"501\" y=\"82\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"571\" y=\"82\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"641\" y=\"82\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"386\" y=\"128\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">person 2</text><rect x=\"501\" y=\"114\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"571\" y=\"114\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"641\" y=\"114\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"386\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">person 3</text><rect x=\"501\" y=\"146\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"571\" y=\"146\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"641\" y=\"146\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"386\" y=\"192\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">person 4</text><rect x=\"501\" y=\"178\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"571\" y=\"178\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"641\" y=\"178\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"386\" y=\"224\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">person 5</text><rect x=\"501\" y=\"210\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"571\" y=\"210\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"641\" y=\"210\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><path d=\"M382 242 L688 242\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"510\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">4 of 5</text><text x=\"580\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">4 of 5</text><text x=\"650\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">3 of 5</text><text x=\"386\" y=\"264\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">total</text><rect x=\"150\" y=\"296\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"172\" y=\"308\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">said it back, or applied it</text><rect x=\"420\" y=\"296\" width=\"14\" height=\"14\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"442\" y=\"308\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">did not</text></svg>", "caption": "Five people, three questions, twice. In the first round the only people who could say the strategy back were the two whose work it had changed; after the page and its delivery changed, most of a new five could."}
```

Four said back the policy, four named something on the not list, and three applied it to the
timeout. The fifth person on question 1 described the load test as the strategy, which is close and
still an action; Davi left it, because a page that four people in five can repeat in their own
words is doing its work.

## Running it again

**People join, and a strategy that was carried in January can be lost by June.** Each quarter, at
the review the page's header promises, ask a new five — including somebody who joined since the
last round. A drop is an early signal that the page has gone stale or that the reasons behind it
have stopped being repeated, and it arrives long before anybody ships something the policy rules
out.

And when the answers come back right but in exactly the page's words, ask the third question
again with a different situation. Recitation passes the first two questions. Only understanding
passes the third.
