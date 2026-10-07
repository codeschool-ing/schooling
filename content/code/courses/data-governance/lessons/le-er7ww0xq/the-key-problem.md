---
title: The key is the whole problem
version: 1
---

Lesson 3 ended with a column encrypted perfectly and a key sitting in the server's log. That is
not a pgcrypto story; it is the shape of almost every encryption failure. **The algorithms are
the part nobody gets wrong any more. The keys are the part everybody does.**

Where a key ends up when nobody has decided where it should be:

- **in the code**, as a constant, and therefore in the repository, in every clone, in every fork,
  and in the history long after somebody "removed" it;
- **in a configuration file** beside the application, readable by whoever can read the
  application, and copied into every backup of the server;
- **in an environment variable**, which ends up in process listings, crash reports and the
  output of debugging tools;
- **in the query**, as lesson 3 showed, and from there in every log.

Each of those puts the key **next to the data it protects**, or next to the people it should
protect the data from. An encrypted backup with its key in the same bucket is a backup with an
extra step.

## A key has a life

Treating a key as a value you generate once and paste somewhere misses most of what happens to
it. Every key goes through the same stages, and each stage has a question somebody has to answer:

| stage | the question |
|---|---|
| **generate** | from what randomness, on which machine, seen by whom? |
| **store** | where, protected by what, readable by which process? |
| **use** | who may ask for it to be used, for what operation, and is that recorded? |
| **rotate** | how often is a new version made, and what happens to data encrypted with the old one? |
| **revoke** | how is a version taken out of use when it may have leaked? |
| **destroy** | how is it deleted, and is anything left that it was the only way to read? |

A team that can answer all six for every key it holds is managing keys. A team that can answer
the first and not the others has a secret in a file.

## What this lesson builds

The answer the industry settled on is to stop handing keys out at all. A **key-management
service** keeps the keys and offers their *use*: send it a plaintext and a key's name, receive a
ciphertext, and never see the key. This lesson runs one — **OpenBao**, the open-source fork of
HashiCorp Vault — and uses it for four jobs: encrypting the CPF in the application, encrypting a
backup, rotating a key without losing the data, and destroying a key on purpose. The cloud
providers' services do the same jobs with their own commands, and section 12 maps them.
