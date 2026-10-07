---
title: Planning poker
version: 1
---

**Planning poker** is a way for a team to agree on a size together without the first person to speak deciding it for everybody. James Grenning described it in 2002, and Mike Cohn's book *Agile Estimating and Planning* (2005) made it the standard.

## A round

Each person holds a deck of cards with the scale on them: 0, ½, 1, 2, 3, 5, 8, 13, 20, 40, 100, and usually a **?** for *I have no idea* and a coffee cup for *I need a break*.

1. The Product Owner reads the story and answers questions about it.
2. Everybody chooses a card **privately**.
3. Everybody turns their card over **at the same moment**.
4. If the cards agree, that is the size. If they differ, the people with the **highest and lowest** cards explain why.
5. The team discusses briefly and votes again, usually converging in two or three rounds.

## Why the cards are hidden

The rule that matters most is the simultaneous reveal. Amos Tversky and Daniel Kahneman showed in 1974 that people's numerical judgements are pulled towards any number they hear first, even an obviously irrelevant one; they called it **anchoring**. In a meeting where the most senior developer says "that's a 3" before anybody else has thought about it, the team's estimate is that developer's estimate with extra steps. Hidden cards give every person's judgement a chance to be heard.

## The disagreement is the value

When one developer shows 3 and another shows 13, the useful part of the meeting is about to happen. Usually one of them knows something the other does not: the 13 knows the payment provider requires a separate approval for each new clinic; the 3 knows there is already a library that handles it. **The conversation uncovers the assumption, and the second vote is better informed than either first card.** A team that skips the explanation and takes the average has thrown that away.

## Its ancestor

Planning poker is a lightweight form of **Wideband Delphi**, a method Barry Boehm described in the 1970s, which adapted the RAND Corporation's Delphi technique for forecasting: experts estimate independently, the spread is discussed, and they estimate again. The idea is old because it works: independent judgement first, then discussion, then revision.
