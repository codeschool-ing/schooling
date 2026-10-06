---
title: To keep a secret, use the recipient's public key
version: 1
---

**Whoever wants to send a secret encrypts it with the recipient's public key, and only the
recipient's private key can decrypt it.** The sender needs nothing secret at all. That is the half
of asymmetric cryptography that solves lesson 1's problem: anybody can send Vereda's records
service a letter that only the service can read, without ever having shared a key with it.

In this lesson the lab's `rsa-3072` pair stands for that service. Its public key is published;
its private key never leaves the service.

## Encrypting to the service

Ana encrypts the 170-byte referral letter with the service's public key, twice, using RSA with
OAEP padding (the padding lesson 2 required):

```
ana@lab:~/lab$ cat data/referral.txt | wc -c
170
ana@lab:~/lab$ openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in data/referral.txt -out ref1.rsa
ana@lab:~/lab$ openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in data/referral.txt -out ref2.rsa
ana@lab:~/lab$ wc -c ref1.rsa ref2.rsa; cmp -s ref1.rsa ref2.rsa || echo "the two ciphertexts differ"
384 ref1.rsa
384 ref2.rsa
768 total
the two ciphertexts differ
```

Two things to notice. Each ciphertext is **384 bytes**, the size of the 3072-bit modulus, whatever
the length of the letter. And the two ciphertexts **differ**, although the letter and the key are
the same: OAEP mixes fresh random bytes into every encryption, which is exactly what makes it safe
where the raw RSA of lesson 2 was not. An observer cannot tell that the same letter was sent twice.

The service decrypts with its private key:

```
ana@lab:~/lab$ openssl pkeyutl -decrypt -inkey keys/rsa-3072.key -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in ref1.rsa
Referral 2026-0417. Patient: Marina Duarte, 41.
Lower back pain after lifting, eight weeks. Eight sessions of physiotherapy.
Dr. Paulo Nogueira, CRM-SP 000000 (invented)
```

Ana could not do this herself. She has the letter, of course, but she does not have the private
key, so after encrypting she cannot read her own ciphertext back. Nor can anybody who intercepts it.

## RSA encrypts little, and that is fine

The appointment file is 512 bytes. RSA refuses it:

```
ana@lab:~/lab$ openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in data/slots.dat -out slots.rsa 2>&1 | grep -o "data too large for key size"
data too large for key size
```

With a 3072-bit key and OAEP over SHA-256, the most RSA can encrypt in one operation is 318 bytes:
the 384 bytes of the modulus, minus what the padding needs. RSA is also thousands of times slower
than AES. So nobody encrypts files with RSA. **Asymmetric encryption is used to protect a key, and
the key protects the data**, which is the hybrid scheme of section 04 of this lesson.

## Keeping a secret proves nothing about the sender

Because the public key is public, **anybody** could have produced that ciphertext. When the service
decrypts the letter, it learns what the letter says and nothing about who sent it: Ana, a patient,
or somebody pretending to be Ana's clinic. Encryption to a public key gives confidentiality and
only confidentiality. Knowing who wrote something is the other job, and it uses the keys the other
way round.
