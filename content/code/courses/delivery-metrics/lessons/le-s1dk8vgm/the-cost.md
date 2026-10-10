---
title: What a false page costs
version: 1
---

Lesson 14's timeline of 30 September starts at 17:20, with the release. The pager had already spoken half an hour earlier. At 16:52, the alert called **card provider p99 over 2 s** paged Rafa, who was on call: at least one charge in every hundred was taking more than two seconds. Rafa looked at it, saw the alert he had seen many times before, and acknowledged it. In the postmortem he said it plainly: **"I saw the alert and thought it was the usual noise."**

He was right that it was the usual alert, and right that most of its pages needed nothing. He was wrong about that afternoon, because the provider's slowness was exactly the condition that made the new retry fire twenty-eight minutes later. Nobody in the postmortem thought Rafa should have known; lesson 15 is clear about that. The question it left for this lesson is a different one: **why had the team taught its on-call engineer that this alert could be ignored?**

## Alert fatigue

**Alert fatigue** is what happens to people who are paged often for things that need nothing. Each false page teaches a little more that pages can wait, and the lesson is learnt whether anybody intends it or not. The symptoms are familiar to anyone who has carried a busy pager:

- **acknowledging without reading**, to stop the noise, and meaning to look later;
- **muting** an alert for an hour, then a day, then forgetting it is muted;
- **a slower answer to every page**, including the rare one that matters, because the expected value of looking has fallen;
- **people leaving the rota**, which lesson 17 showed is the last symptom rather than the first.

Hospitals know the same thing as **alarm fatigue**: monitors at a patient's bedside that sound so often for nothing that staff stop hearing them, and in 2013 the Joint Commission, which accredits American hospitals, issued a formal warning about it, after a run of deaths in which alarms had been silenced, turned down or not heard. The mechanism is the same in a ward and on a pager, and it is not a weakness of the people involved. **A person exposed to a signal that is usually wrong learns to discount it, correctly, almost every time.**

## The cost is paid twice

A false page costs the obvious thing: somebody's sleep, or an hour of their afternoon. That cost is visible, and teams sometimes accept it as the price of safety.

The second cost is the one that matters and nobody records. Every false page lowers the credibility of every other page, including the true ones. A team with twenty alerts, sixteen of them noisy, does not have four good alerts and sixteen annoying ones. It has twenty alerts that nobody fully believes. **The noise does not sit beside the signal; it spends the signal's credibility.**

That is why the fix is not "be more careful when acknowledging". Asking people to stay alert against a signal that is usually wrong asks them to fight what experience teaches them. The fix is to make the signal worth believing again, and the rest of this lesson is how.
