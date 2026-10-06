---
title: Not all second factors are equal
version: 1
---

Any second factor is much better than none. They are not equally good, though, and the differences
come from how each one can be defeated. Four in common use, from weaker to stronger:

| factor | how it works | how it is defeated |
|---|---|---|
| **SMS code** | a code texted to a phone number | **SIM swap**: an attacker persuades the carrier to move the number to their SIM, and receives the texts |
| **push approval** | the app asks "is this you?" and you tap yes | **MFA fatigue**: the attacker triggers request after request until the victim taps yes to make it stop |
| **TOTP code** | the six digits of the previous sections | a fake login page asks for the code too and uses it within the thirty seconds |
| **security key or passkey** | a device or the phone proves possession of a key, for this exact site | the key answers only to the real site's address, so a fake page gets nothing usable |

The third row is the important one to understand. TOTP stops a password stolen **last month** from a
breach. It does not stop a phishing page **right now**: the victim types the password and then the
code into the fake page, which passes both to the real site within seconds. The attacker never needed
the secret, only one fresh code. A one-time code is phishable because a human reads it and types it
wherever they are asked.

### Phishing-resistant authentication

The last row works differently. A **security key** (hardware such as a USB key) or a **passkey**
(the same idea stored in a phone or laptop) uses the standards **FIDO2** and **WebAuthn**. The key
holds a private key per site and proves possession by signing a challenge, and the browser includes
the address of the site in what is signed. A fake site at a look-alike address receives a signature
for the wrong address, which the real site rejects. There is no code for the human to type into the
wrong place, so there is nothing to phish. `cryptography` lesson 3 explains the public and private
keys underneath.

For that reason these are called **phishing-resistant**, and they are what security guidance now
recommends for administrators and for anything valuable.

### Making push and codes better

Push approvals are improved by **number matching**: the login page shows a number and the app asks
the person to type it, which defeats fatigue because tapping yes to make the noise stop no longer
works. A limit on how many prompts can be sent in a short time helps too.

### What the shop chooses

For the nine staff, an authenticator app with TOTP on every account is the first step, because it is
free and defeats the reused password, which is the shop's realistic attacker from lesson 2. For ana's
administrator accounts and for the owners' access to the bank, security keys, because those are the
accounts a targeted phishing email would aim at. SMS only where a service offers nothing better,
because a weak second factor is still a second factor.
