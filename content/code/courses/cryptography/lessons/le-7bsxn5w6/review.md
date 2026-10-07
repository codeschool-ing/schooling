---
title: A review in seventeen questions
version: 1
---

**This course has been a set of decisions, each with a reason. Reviewing a system's cryptography is
asking the same questions in the same order, and the answer that should worry you is "I don't know"
more often than "no".** One question per lesson, with the answer to look for:

| lesson | question | what a sound answer sounds like |
| --- | --- | --- |
| 1 | How is data encrypted? | AES-GCM or ChaCha20-Poly1305, unique nonces, failures to open treated as attacks |
| 2 | How large are the asymmetric keys? | RSA of 3072 bits or more for new keys, or P-256 or Ed25519 |
| 3 | Which key does what? | encrypt to the recipient's public key, sign with your own private key |
| 4 | Which hash, for what? | SHA-256 or better; MD5 and SHA-1 nowhere that security depends on |
| 5 | How are passwords stored? | Argon2id or bcrypt, a salt per password, the pepper kept apart |
| 6 | How is integrity checked? | HMAC or signatures, compared in constant time |
| 7 | Is there forward secrecy? | ephemeral Diffie-Hellman, and a plan for post-quantum key exchange |
| 8 | Who issues the certificates? | a known CA, private roots kept offline, issuance logged |
| 9 | Do clients validate them? | chain, name, dates and revocation, with verification never switched off |
| 10 | Which TLS? | 1.3, or 1.2 with forward-secret suites; nothing older offered |
| 11 | Is anything "encrypted" with Base64 or XOR? | no: encoding and obfuscation are labelled as what they are |
| 12 | Which protocols carry credentials? | SFTP or FTPS, LDAPS or StartTLS, never their plain forms |
| 13 | What protects names, calls and mail? | DNSSEC signed and validated, SRTP, S/MIME where mail must stay sealed |
| 14 | What is encrypted at rest, and where is the key? | each layer chosen for a named theft, keys in a KMS, recovery tested |
| 15 | Which Wi-Fi security? | WPA3 or 802.1X; WPA2-Personal only with a random passphrase; never WEP or TKIP |
| 16 | Do clients check the RADIUS server? | a pushed profile naming the CA and the server, or EAP-TLS |
| 17 | Keys in code, homemade schemes, repeated nonces? | scanners in CI, library recipes, nonces chosen by the library and audited |

## Using the table

Ask the questions of somebody who runs the system, not of its documentation, and ask for the evidence
behind each answer: the configuration file, the scanner's last report, the date the key was last
rotated. A written answer that nobody can back with evidence has not been checked.

Most of what a review finds is in the right-hand column of lessons 14 to 17. The algorithms in the
left-hand rows are usually chosen by a library or a vendor and are usually fine. **The keys, the
configurations and the procedures around them are chosen by people, one at a time**, and that is where
this course has spent its last four lessons and where your attention will pay most.
