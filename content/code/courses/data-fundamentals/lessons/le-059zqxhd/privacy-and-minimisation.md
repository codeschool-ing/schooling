---
title: Collecting only what the question needs
version: 1
---

**Every column of personal data you collect is something you then have to protect, explain, hand
over when its owner asks, and answer for if it leaks.** So what to collect is decided by what the
question needs, and nothing past that.

That is also the law. Brazil's **LGPD**, the Lei Geral de Proteção de Dados (Law 13.709 of 2018),
lists its principles in article 6, and two of them decide collection. **Purpose**: personal data is
processed for a purpose that is legitimate, specific and told to the person. **Necessity**: no more of
it than that purpose requires. The ANPD, the national data protection authority, enforces it. A
column collected "in case it is useful one day" has no purpose yet, and fails the first test before
anybody has read it.

## Three ways to need less

Caio's demand model needs rides per station per hour. The rides table holds much more: the customer,
their phone number, the exact second, the card used to pay. Before any of it is copied:

- **leave out** what no question needs. The model never reads the phone number or the card, so the
  copy does not have them;
- **coarsen** what is needed only roughly. Rides per hour need the hour, not the second; a customer's
  age band, not their date of birth;
- **pseudonymise** what is needed only to tell people apart. Counting rides per customer needs to
  know that two rides were by the same customer, not who that customer is.

## A hash is not a disguise

To **pseudonymise** is to replace an identifier with a stand-in that is the same every time for the
same person, so joins and counts still work, and that cannot be turned back without something kept
apart from the data. The common mistake is to think a plain hash does that. **A plain hash of a phone
number is the same number in disguise**, for two reasons.

The first is that anybody can compute it. SHA-256 has no secret in it, so a partner holding a list of
phone numbers can hash the list and look for matches in your "anonymous" column. The second is that
there are not many phone numbers. A mobile number in Curitiba is `+55 41 9` followed by eight digits:
one hundred million candidates, a list short enough to hash in full and keep, after which every plain
hash of a Curitiba mobile number can be looked up.

A **keyed hash** fixes both. HMAC mixes a secret key into the hash, so without the key nobody can
compute the stand-in for a number, and a list of guesses matches nothing. The program below
pseudonymises three customers both ways, then plays the partner: it hashes its own list of numbers
with plain SHA-256, the only way it can, and looks for them. The key is read from the environment,
never written in the program, which is how a secret is kept out of code. Save it as
`collect/pseudo.py`:

```python
# collect/pseudo.py
import hashlib
import hmac
import os

KEY = os.environ["RODA_PSEUDO_KEY"].encode()    # kept apart from the code and the data


def plain(phone):
    return hashlib.sha256(phone.encode()).hexdigest()[:16]


def keyed(phone):
    return hmac.new(KEY, phone.encode(), hashlib.sha256).hexdigest()[:16]


customers = {"C0001": "+5541900000101", "C0002": "+5541900000202",
             "C0003": "+5541900000303"}
print("customer  plain hash        keyed hash")
for customer, phone in customers.items():
    print(f"{customer}     {plain(phone)}  {keyed(phone)}")

# a partner has its own list of phone numbers, and no key
partner = ["+5541900000202", "+5541900000999", "+5541900000303"]
guesses = {plain(p) for p in partner}
print("partner's guesses found among plain hashes:",
      sum(plain(p) in guesses for p in customers.values()))
print("partner's guesses found among keyed hashes:",
      sum(keyed(p) in guesses for p in customers.values()))
```

In the lab the key is a value you type; at Roda Livre it lives in a secret store, readable by the
pipeline and nobody else:

```
ana@lab:~/roda/collect$ RODA_PSEUDO_KEY=lab-key-not-a-secret python pseudo.py
customer  plain hash        keyed hash
C0001     727cde8c0392b39e  bdda5187e6a17a41
C0002     cb072d5af983448a  957123a6462942b7
C0003     4b1e901121ca526b  4c0a9b09f320c5b1
partner's guesses found among plain hashes: 2
partner's guesses found among keyed hashes: 0
```

**Two of the partner's three numbers are found among the plain hashes, and none among the keyed
ones.** The partner now knows that two of its customers ride with Roda Livre, from a column that held
no phone number at all.

## Still personal data

A keyed hash is a pseudonym, not an anonymisation. Whoever holds the key can compute the stand-in for
any number and re-link it, and the LGPD's definition of anonymised data, in article 12, excludes data
that can be re-identified by reasonable means. So the pseudonymised copy is still personal data, with
everything that means: it needs a purpose, it is protected, and it is erased when its owner asks.
Pseudonymising lowers the harm of a leak; it does not take the data out of the law.

The key is now the most sensitive thing in the pipeline. Lose it and the pseudonyms can never be
linked again; change it and every stand-in changes, so this year's customers no longer join to last
year's. Both are decisions to make before the first copy, with whoever answers for privacy at the
company, which at Roda Livre is a question Davi takes to the founders rather than one he settles.
