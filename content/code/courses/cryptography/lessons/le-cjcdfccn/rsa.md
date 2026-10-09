---
title: RSA, built on multiplying two primes
version: 1
---

**RSA's private key is two large prime numbers, and its public key is their product.** Multiplying
two primes is instant; recovering them from the product, *factoring*, is a problem nobody can solve
for numbers of the size RSA uses. Everything else in RSA is arithmetic that follows from that one
fact, and it is small enough to do by hand once.

## RSA with numbers you can check

`vcrypt toyrsa` runs RSA with the primes of the classic textbook example, 61 and 53, and encrypts
a number. Every line of the arithmetic is in it:

```py
# ~/lab/tools/toyrsa.py
"""vcrypt toyrsa M: RSA with numbers small enough to follow by hand, on the
message M (a number below n). This is textbook RSA, with no padding, which
is NOT how RSA is used; lesson 2 says why."""
import sys

p, q, e = 61, 53, 17
m = int(sys.argv[1])
n, phi = p * q, (p - 1) * (q - 1)
d = pow(e, -1, phi)
print(f"p = {p}, q = {q}         two primes, kept secret")
print(f"n = p*q = {n}           public: the modulus")
print(f"phi = (p-1)(q-1) = {phi}   secret: needs p and q")
print(f"e = {e}                  public exponent")
print(f"d = e^-1 mod phi = {d}   private exponent")
c = pow(m, e, n)
print(f"encrypt m = {m}:  c = m^e mod n = {c}")
print(f"decrypt c = {c}:  m = c^d mod n = {pow(c, d, n)}")
```

Here it encrypts the number 65:

```
ana@lab:~/lab$ vcrypt toyrsa 65
p = 61, q = 53         two primes, kept secret
n = p*q = 3233           public: the modulus
phi = (p-1)(q-1) = 3120   secret: needs p and q
e = 17                  public exponent
d = e^-1 mod phi = 2753   private exponent
encrypt m = 65:  c = m^e mod n = 2790
decrypt c = 2790:  m = c^d mod n = 65
```

Read it from the top:

- the two primes `p` and `q` are the secret;
- their product `n = 3233` is the **modulus**, and it is public;
- `e = 17` is the **public exponent**. The public key is the pair `(n, e)`;
- `d = 2753` is the **private exponent**. Computing it needs `phi`, and computing `phi` needs `p`
  and `q`. That is where the factoring enters: whoever can split `n` into `p` and `q` can compute
  `d`;
- encrypting is raising to the power `e` modulo `n`, and decrypting is raising to the power `d`.
  65 became 2790 and came back as 65.

With `n = 3233` anybody factors the modulus in their head (it is 61 × 53), so this key protects
nothing. With a real key the same steps hold, and only the size changes.

## A real RSA key

The lab's `rsa-2048.key` holds the same fields, each a number hundreds of digits long:

```
ana@lab:~/lab$ openssl pkey -in keys/rsa-2048.key -noout -text | grep -E "^[A-Za-z]"
Private-Key: (2048 bit, 2 primes)
modulus:
publicExponent: 65537 (0x10001)
privateExponent:
prime1:
prime2:
exponent1:
exponent2:
coefficient:
```

`modulus` is `n`, `privateExponent` is `d`, and `prime1` and `prime2` are `p` and `q`. The last
three, `exponent1`, `exponent2` and `coefficient`, are precomputed values that let decryption run
about four times faster using the two primes separately (the Chinese remainder theorem); they add
no secret that the primes did not already contain. The public exponent is the same in practically
every RSA key in use, 65537, chosen because it makes encryption and verification fast. The
modulus is the public part that matters, and its first 32 bytes look like this:

```
ana@lab:~/lab$ openssl rsa -pubin -in keys/rsa-2048.pub -noout -modulus | cut -c1-72
Modulus=D9944C6D90C6575AA00FA9CB1016916C04C1F9DDDA586A2BF4EF4C282F1D56FC
```

A 2048-bit modulus is a number of 617 decimal digits. The largest RSA-style number factored in
public is RSA-250, 829 bits, in 2020, after roughly 2,700 years of processor time. That gap is the
safety margin, and the last section of this lesson says how much of it to keep.

## Why real RSA is not the toy

The toy shows the arithmetic and omits what makes RSA safe to use. **Raw RSA, as above, must never
encrypt or sign anything real**, for two reasons a defender should be able to name:

- it is **deterministic**: the same message always gives the same ciphertext, so an observer can
  test a guess, encrypt "yes" with the public key and compare. That is the ECB problem of lesson 1
  again;
- it is **malleable**: multiplying ciphertexts multiplies plaintexts, so a ciphertext can be turned
  into a related one without the key.

The remedy is **padding** with randomness and structure before the arithmetic. For encryption the
current scheme is **OAEP**, and for signatures **PSS**; the older PKCS#1 v1.5 padding is still
everywhere in signatures, and still acceptable there, but its encryption form has a long history
of attacks against servers that reveal whether the padding was valid. Libraries apply the padding
for you when you name it, and the safe habit is to use an interface where you cannot forget to.

## Where RSA stands now

RSA is still the most common algorithm in certificates, and every browser verifies RSA signatures
all day. But it is losing ground. TLS 1.3 removed RSA as a way of *exchanging keys*, keeping it only
for signatures, for reasons lesson 7 explains (forward secrecy). New designs prefer elliptic curves,
which give the same strength with much smaller keys, and that is the next section.
