---
title: The rota
version: 1
---

Somebody has to answer when card charges break at two in the morning. **On-call** is the arrangement that decides who, in advance, so that the answer is never "whoever happens to see the message". The person on call carries the pager, which today is a phone app, and agrees to answer it within minutes, at any hour, for the length of a shift.

## The shape of a rota

A **rota** is the order in which people take turns. Most teams use the same few pieces:

- **a primary**, who is paged first and is expected to answer;
- **a secondary**, who is paged if the primary does not acknowledge, and who can be called in when one person is not enough;
- **a shift length**, most often a week, because shorter shifts mean more handovers and longer ones wear people down;
- **a handover day** in the middle of the week, Wednesday or Thursday, so that nobody starts a shift on a Monday morning straight into everything the weekend left behind.

The Billing team's rota is one week each, in turn, handing over on Wednesdays: Duda, Inês, Rafa, Téo, Caio, and round again. The secondary is the person who was primary the week before, because they know what happened last. Bia, the tech lead, is the last level of escalation and not on the rota, which is a choice the next sections come back to.

## How big a rota has to be

Two numbers from Google's SRE book are the usual reference, and both are about people rather than systems.

- **Nobody should spend more than a quarter of their time on call.** Beyond that, on-call stops being a duty and becomes the job, and the rest of the job does not get done.
- **A rota that covers every hour from one place needs about eight people** to keep the first rule and leave room for holidays, sickness and the week somebody's child is born.

The Billing team has five. One week in five is 20%, inside the first rule, but only while all five are present: one holiday makes it one week in four, and two at once make it one in three. A team of five can carry a pager, and it does so with no margin, which is worth saying out loud before somebody plans a holiday in December.

## What a rota is not

A rota is not a list of who to blame. The person on call is the first to answer, not the person who has to fix everything alone. **Their job is to acknowledge, assess and, if the problem is bigger than one person, call for help**: the incident roles of lesson 13 exist for exactly that, and the primary is very often the one who declares the incident and hands command to somebody else.

Nor is it a reason to stop fixing things. A rota that pages every night is not a staffing problem to be solved with more people; it is a system telling the team where to work, and lesson 18 is about listening to it.
