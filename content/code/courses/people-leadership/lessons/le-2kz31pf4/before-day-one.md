---
title: Before day one
version: 1
---

Onboarding starts the day the offer is accepted, not the day the person arrives. **What happens in
the weeks between decides whether the first day is spent working or waiting**, and whether the new
person arrives already feeling expected or wondering whether anybody remembered.

## The gap

Lucas accepted in the second week of October and started in mid-November, after his thirty days'
notice. A month is long enough to prepare everything, and long enough to forget about him entirely.
At Caju, before Renata, new engineers had typically spent their first two days waiting for a laptop,
an email account and access to the code. That is two days of somebody's first impression of the
company spent watching other people work.

## Renata's list

Renata keeps a list for every new hire, and works through it in the weeks before they arrive:

| when | what |
|---|---|
| the week of acceptance | a message from Renata welcoming him, saying what the first week will look like |
| two weeks before | laptop ordered, accounts requested: email, chat, code hosting, the issue tracker |
| one week before | a buddy chosen and told; first small task chosen and written up |
| the Friday before | a short message from the buddy introducing themselves |
| day one | everything above working before he arrives at 9:00 |

None of it is difficult. **All of it depends on somebody remembering**, which is why it is a list and
not a habit.

## The buddy

A buddy is somebody on the team, not the manager, who is the new person's first point of contact for
anything: where things are, how the deploy works, who to ask about the billing code, whether it is
normal that the tests take nine minutes. Lesson 13 described onboarding as glue work, and the buddy
role is where most of it lands.

Renata chose Paula for Lucas, for three reasons. She owned the reminder service that Lucas would take
over, so she was the person he would need most anyway. Lucas's hiring record said his weakest area was
explaining things to people outside engineering, and Paula was the best on the team at it. And the
buddy role was no longer automatically Paula's, since lesson 13's rotation: this time it was her turn
by the rota, which mattered, because it meant nobody was assuming she would do it.

**The buddy needs time to do it.** Renata took a third of Paula's planned work out of the sprint for
Lucas's first two weeks, and said so in planning. A buddy who is expected to onboard somebody on top
of a full load does it in the gaps, and the new person learns to stop asking.

## The first task, chosen in advance

The most important single preparation is the first piece of work. Renata chose it a week before Lucas
arrived: a small, real bug in the reminder service, reported by a clinic, where a reminder showed the
appointment time in the wrong time zone for clinics in Manaus. It was:

- **real**, so finishing it would matter to somebody;
- **small**, a few lines once found, so it could reach production in the first week;
- **in the area he would own**, so it taught him the code he would spend months in;
- **written up**, with how to reproduce it and who reported it, so he could start without a briefing.

The next section is about why the first change reaching production matters so much, and how quickly
it can.
