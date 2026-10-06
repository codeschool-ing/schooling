---
title: The 27000 family
version: 1
---

**ISO** is the International Organization for Standardization, and **IEC** the International
Electrotechnical Commission. Together they publish a family of standards on information security
numbered from 27000 upwards, and the two most used are the subject of this lesson. In Brazil, ABNT
publishes them in Portuguese as ABNT NBR ISO/IEC 27001 and 27002.

The family is large, and only a few members matter to a beginner:

| standard | what it is | how it is used |
|---|---|---|
| **27000** | overview and vocabulary | the definitions the others rely on |
| **27001** | requirements for an information security management system | **the one an organisation is certified against** |
| **27002** | guidance on the security controls | the catalogue of controls and how to implement each |
| **27005** | guidance on information security risk management | how to do lesson 3's work in the 27001 way |
| **27701** | an extension of 27001 for privacy | used alongside the LGPD of lesson 17 |
| **27017** and **27018** | guidance for cloud services and for personal data in the cloud | for providers and their customers |

### Requirements against guidance

The most important distinction in the family is between **requirements** and **guidance**. 27001 says
what an organisation **shall** do, and only 27001 can be certified against. 27002 says what an
organisation **should** consider when implementing each control; nobody is certified against 27002,
and nobody is obliged to follow its advice word for word.

The current editions are **ISO/IEC 27001:2022** and **ISO/IEC 27002:2022**. The previous edition of
27001 was from 2013, and organisations certified against it had until October 2025 to move to the new
one, so any certificate in force today is against the 2022 edition. The structure of the controls
changed a good deal between the two, which is worth knowing when you read an older policy that cites
control numbers like "A.9.2.6": those are 2013 numbers and do not exist in 2022.

### What certification says, and what it does not

A certificate says that an accredited body audited the organisation's management system against
27001 and found it conforming, **for a stated scope**. The scope is the part people skip. A company can
certify only its data centre, or only one product line, and the certificate is honest about that in
its scope statement. When a customer asks for the shop's certificate, the useful question back is
"for which scope do you need it?", and when you read somebody else's, read the scope first.
