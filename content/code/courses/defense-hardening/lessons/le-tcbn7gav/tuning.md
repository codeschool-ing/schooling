---
title: Tuning, so that prevention stays switched on
version: 1
---

**Every HIPS setting trades a missed attack against a blocked colleague.** The numbers in
`jail.local` are that trade written down, and each one moves it:

| setting | lower | higher |
|---|---|---|
| `maxretry` | bans sooner, and catches the colleague who mistypes twice | lets a guesser try more before the ban |
| `findtime` | forgets failures sooner, so a slow guesser spread over hours never reaches the count | remembers longer, and counts unrelated mistakes together |
| `bantime` | the guesser is back sooner | a locked-out colleague waits longer |

There is no right value, only a right reason. On `web`, SSH accepts keys and no passwords once
lesson 1's hardening is in place, so guessing achieves nothing and fail2ban's job is to keep the log
readable and the connections cheap; short bans are enough. On a server that still accepts passwords
from the internet, bans get longer and repeat offenders get longer still, which fail2ban's
`recidive` jail does by watching its own log for addresses banned again and again.

## Never ban the people who fix things

**`ignoreip` lists the addresses fail2ban will never ban**, and it belongs in every jail
configuration that reaches production. On Jatobá's network it would hold `admin`, and the jump
server lesson 15 builds, so that a mistyped key on the administrators' own machine never locks the
administrators out of the server they are trying to fix:

```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 192.168.60.30 192.168.60.40
```

The cost is that an intruder on `admin` is never banned either, which is one more reason lesson 15
treats the administrators' machines as the best-protected in the firm.

## Watching the protection itself

Three checks keep a HIPS honest, and each catches a failure that looks like silence:

- **Does the action take effect?** After any change to a jail, cause one ban on purpose, from a
  test machine, and confirm the address is refused, as this lesson did from `desk`. The error
  messages of a failed action go to `fail2ban.log`, and nobody reads that log unprompted.
- **Is the jail reading the right log?** A jail whose log moved, or whose service now logs to the
  journal, counts nothing and bans nobody, forever. `fail2ban-client status` showing a total of zero
  failures for months on a server reachable from the internet is not good news.
- **Is the integrity database still the approved one?** A database rebuilt after an unexplained
  change has approved that change. Rebuilding is a decision, and the change log should say who made
  it and why.
