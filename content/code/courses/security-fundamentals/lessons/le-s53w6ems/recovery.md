---
title: Recovery, the door around the lock
version: 1
---

Every MFA system has to answer one question: **what happens when somebody loses their phone?** The
answer is the account recovery process, and an attacker reads it as carefully as the login page,
because a recovery that is easier than the login is the real way in.

### Recovery codes

When MFA is turned on, a good system also issues a handful of **recovery codes**: long random codes,
each usable once, to be printed or stored somewhere safe and away from the phone. Losing the phone
then means using one code and setting up the new phone. Recovery codes are a factor in their own
right, something you have, and they should be protected like one: not in a note on the same phone,
not in the email account they would help recover.

### The help desk

When there are no codes, the fallback is a person: somebody calls the help desk and asks for MFA to be
reset. That call is the most attacked step in the whole system, because it turns a technical control
back into a conversation, and conversations can be manipulated. A caller who knows the employee's name,
manager and a few details from social media can sound exactly like a stressed colleague who lost their
phone before a meeting.

The defences are procedural:

- **verify through a channel the caller did not choose**: call back on the number in the staff
  records, or confirm with the person's manager, never on the number the caller gives;
- **require more for more**: resetting an administrator's MFA needs more than resetting a regular
  user's, ideally a person in front of somebody they know;
- **record and notify**: every reset is logged with who approved it, and the account's owner is told
  by a second channel, so a reset they did not ask for is noticed the same day;
- **make it slow on purpose**: a short delay before a reset takes effect gives the real owner time to
  object.

`attacks-threats` lessons 1 and 5 take apart how a caller builds a pretext; this lesson needs only
the defender's side.

### Weak recovery undoes strong login

Security questions, recovery by SMS to a number that can be swapped, and "click here to reset" emails
to an inbox with a weak password are all common, and each one turns a strong login into a weak one,
because an attacker simply chooses the weaker door. **An account is as strong as the easiest way to
get into it**, and that includes the way back in. When the shop set up MFA, ana listed every way an
account could be recovered and closed the ones weaker than the login.
