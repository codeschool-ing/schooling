---
title: Obfuscation hides from the casual reader, and from nobody else
version: 1
---

**Obfuscation transforms data so that it is hard to read at a glance, by a method that is written
into the software that reads it.** It has a "key" only in the sense that the program knows the
trick. Whoever has the program, or its manual, or one example, has the trick too.

## A vendor's "protected" password

Vereda's appointment scheduler is a product bought from a vendor. Its configuration file keeps the
database password "protected":

```
ana@lab:~/lab$ cat data/scheduler.ini
[database]
host = db.vereda.example
user = scheduler
; password is protected (ROT13 then Base64, see the vendor's manual)
password = SS1xby1mM3BlcmctMjAyNg==
```

The comment says what the protection is, because the vendor's own manual does. Undoing the second
step:

```
ana@lab:~/lab$ grep '^password' data/scheduler.ini | cut -d' ' -f3 | base64 -d; echo
I-qo-f3perg-2026
```

That is not the password yet, but it is clearly a shifted version of one: same shape, same digits,
letters moved along the alphabet. ROT13 replaces each letter with the one thirteen places on, so
applying it again undoes it:

```
ana@lab:~/lab$ grep '^password' data/scheduler.ini | cut -d' ' -f3 | base64 -d | tr 'A-Za-z' 'N-ZA-Mn-za-m'; echo
V-db-s3cret-2026
```

Two commands and no key. Every installation of the scheduler, in every clinic in the country,
"protects" its password the same way, so learning the trick once opens all of them.

## Where obfuscation turns up

- **Configuration files** with "encrypted" passwords whose key is a constant inside the product. Some
  are XOR with a fixed byte string, some are AES with a key compiled into the binary. In both cases the
  key ships with every copy and is extracted once, by somebody, and published.
- **Minified or obfuscated JavaScript** in a web page. It is shipped to every visitor's browser, so
  anything in it, an API key included, is public.
- **Mobile apps** that hide an API key inside the compiled app. A decompiler recovers it.
- **"Proprietary encoding"** in a file format, which lesson 17 calls by its proper name: rolling your
  own algorithm.

## Is obfuscation ever worth anything?

It raises the effort for a casual reader, and that is all it does. It is reasonable for things that
were never secret, such as making licence checks a little more tedious to remove, or keeping a
colleague from reading a password over your shoulder. It is never a control in a risk assessment,
because its strength is the time it takes somebody to search for the vendor's name and the word
"decrypt". When an auditor finds an obfuscated password, the finding is written as **plaintext
password in configuration**.
