---
title: A task says what to do; an outcome says what has to be true
version: 1
---

Delegating is the first managerial skill a new manager reaches for, and the usual first attempt is
handing over tasks. **A task tells somebody what to do. An outcome tells them what has to be true
when they are finished, and leaves the doing to them.** The difference sounds like wording and
turns out to decide whether delegating saves the manager any time at all.

## The same work, delegated twice

In her second month Renata needed somebody to deal with a complaint from clinics: patients were
getting two reminder messages for the same appointment. She gave it to Paula, and the message she
first drafted was this:

> Can you add a check in the reminder job so it skips appointments that already had a reminder sent
> in the last 24 hours? Use the `sent_at` column. Should be a small change.

That is a task. It is precise, and it carries Renata's diagnosis, Renata's design and Renata's
estimate. If any of the three is wrong, Paula will build the wrong thing correctly, or come back
with questions only Renata can answer. **Renata has kept the thinking and handed over the typing.**

She deleted it and wrote this instead:

> Clinics are reporting that some patients get two reminders for one appointment, and two of them
> have said patients now ignore the messages. By the end of next week I'd like every appointment to
> produce exactly one reminder, and a way for us to know if that stops being true. I haven't looked
> at the cause. Helena knows which clinics complained.

That is an outcome. It says what has to be true (one reminder per appointment), how anyone will
know (a way to detect it), why it matters (patients ignoring messages), and by when. It says
nothing about the reminder job, the column, or the size of the change.

## What Paula found

The cause was not what Renata had guessed. Duplicates came from clinics that rescheduled an
appointment: the old one was cancelled and a new one created, and both had reminders queued. A
check on `sent_at` within twenty-four hours would have caught some of them and missed every case
where the reschedule happened more than a day before the appointment. Paula fixed it where
reschedules were handled, and added an alert on duplicate sends per day.

**The task version would have shipped, passed review and left about half the duplicates in
place**, and the clinics would have complained again in a month. Nobody would have been to blame,
because Paula would have done exactly what was asked.

## Why outcomes are harder to write

Writing the outcome took Renata longer than writing the task, and that is the general pattern.
To state an outcome you have to know what you actually want, which is often less clear than the
first fix that comes to mind. "Skip recent reminders" is a solution. "One reminder per appointment,
and we'd know if not" is the thing the solution was for.

Three tests catch a task disguised as an outcome:

- **Does it name a mechanism?** A table, a column, a library, a screen. If so, the design has been
  decided for the person.
- **Could it be done exactly as written and still fail?** The `sent_at` check could. "Exactly one
  reminder per appointment" could not.
- **Would the person need to come back to you if the first idea did not work?** With a task, yes,
  because the plan was yours. With an outcome, they try the next idea.

## When a task is the right thing

None of this makes tasks wrong. A task is the right way to hand over work when the person is
learning and needs the steps, when the steps are genuinely fixed (a regulatory change with one
correct implementation), or when it is small enough that explaining the outcome costs more than
doing it. "Add the new escalation number to the on-call document" is a perfectly good task, and
turning it into an outcome would waste everybody's time.

What goes wrong is treating every piece of work as a task by default, because that is how the
manager thinks about it. **The manager then becomes the bottleneck on every design decision in the
team**, which is the opposite of what delegating was for. The next section is about what has to go
with an outcome so that the person can actually own it.
