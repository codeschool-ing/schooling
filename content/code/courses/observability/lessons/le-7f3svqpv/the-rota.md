---
title: The rota
version: 1
---

**On-call means one named person is responsible for answering pages during a period**, and everybody
else is allowed to stop thinking about production. Both halves matter: a rota where nobody is clearly on
call means everybody half-watches the alert channel all the time, which is on-call for everybody with
none of the rest.

A rota for a small team usually looks like this:

| decision | common choice | why |
|---|---|---|
| length of a shift | one week | long enough to learn the week's problems, short enough to recover from |
| who is on it | everybody who ships to production | the people who write the code feel what it costs to run |
| handover | a fixed time on a weekday, in person or on a call | the outgoing person passes on what is still open |
| secondary | a second person each shift | somebody to escalate to, and to cover an hour off |
| follow the sun | only with teams in several time zones | so that nobody is paged at night |

A rota needs **at least five or six people** to be sustainable. With fewer, each person is on call too
often to recover, and the night pages land on the same few. A team of three that runs production around
the clock should know it is making a trade, and should keep its pages very rare.

Two things make the shift fair, and both are decisions rather than tools:

- **The load is measured and limited.** The pages per shift from lesson 16 are reviewed at every
  handover, and a shift with more than two incidents is a sign that the alerts or the system need work,
  not that the person should try harder.
- **Being on call is paid or given back in time.** A night spent on an incident is followed by a late
  start; a week on call is compensated. In Brazil, the labour courts treat hours in which an employee
  must stay reachable and ready to act as *sobreaviso*, paid at a third of the normal hourly rate. A rota that relies on goodwill runs out of it.

The handover is short and always has the same three parts: **what happened** during the shift, **what
is still open**, and **what is coming**, such as a migration on Thursday or a sale on Friday.
