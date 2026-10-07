---
id: DR-001
threat: T03
decision: mitigate
owner: daniel
decided: 2026-09-30
review by: 2027-09-30
---

# Require a second factor for every staff sign-in (C1)

## The decision

Staff sign in to the console with a password and a code from an authenticator app. Two hardware
keys per clinic are kept for staff without a suitable phone.

## Why

T03 is more than half of Vereda's expected loss. C1 removes about R$ 60,000 a year of it for
R$ 3,000 a year, and with C5, C8 and C4 it brings the yearly loss curve under the appetite daniel
set in lesson 10.

## Consequences

Every sign-in takes a few seconds longer. A lost phone means a call to bruno, who resets the factor
after checking who is calling. Staff accounts that cannot use a second factor cannot sign in.
