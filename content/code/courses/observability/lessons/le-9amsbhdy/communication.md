---
title: Communication: saying what is known, on a schedule
version: 1
---

During an incident, the people who are not fixing it want three things: **to know it is being handled,
to know what it means for them, and to know when they will hear more.** Silence answers none of them,
and people fill silence with messages to the engineers, which is the worst place for them to go.

An update has a shape, and keeping to it is what makes updates fast to write and fast to read:

| part | example |
|---|---|
| what is affected, from the user's side | Some customers cannot complete checkout; payments fail with an error. |
| since when | Since 17:46 (Brasília time). |
| what we are doing | We have rolled back a payments release made at 17:46 and are watching recovery. |
| what users should do | Customers can retry in a few minutes; no card has been charged twice. |
| next update | In 15 minutes, or sooner if it changes. |

Rules that make the shape work:

- **Say what is known, not what is guessed.** *We have identified the cause* in the first update is
  usually wrong, and a correction costs more trust than the wait. *We are investigating a failure in
  payments* is true and enough.
- **Keep the promise about the next update**, even when there is nothing new; *no change, next update
  in 15 minutes* tells people the incident is still being handled.
- **One channel for the response, another for the updates.** Engineers working the incident should
  not have to read questions, and people asking questions should not have to read engineers thinking
  aloud.
- **The status page is for customers**, in their words: no service names, no error codes, no blame on
  a provider.

The communications lead writes these, the IC approves them, and the scribe records when each was sent.
In the lab there is nobody to update, so the incident's marks on Grafana stand in for the internal
channel; the shape above is what each of them would have said.
