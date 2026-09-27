---
title: Why not fix it yourself
version: 1
---

The fix looks like one command: make the file readable by `sales`. The technician has `sudo` on `srv1`
and could run it in a second. There are three reasons not to:

- **The file is not yours.** It belongs to the team that runs the sales system. Somebody set it to `600`,
  and you do not know whether that was a mistake or a security decision, such as a password added to it
  this morning.
- **You would not be the last to touch it.** Their next deployment may set it back, and the system falls
  over again with nobody knowing why it worked for a day.
- **Your change would be in their incident**, without their knowledge. When they investigate, they find a
  permission they did not set, and lose time on it.

**Access is not authority.** Having `sudo` on a machine means you can change it, not that its owner has
agreed to what you change. Lesson 14 comes back to this. Here, the right move is the one in the tiers
figure: functional escalation, to the owners, with everything you found.
