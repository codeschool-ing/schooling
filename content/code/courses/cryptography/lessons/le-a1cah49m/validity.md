---
title: Validity: the dates, and the clock that reads them
version: 1
---

**A certificate is valid only between its `Not Before` and `Not After` dates, and a client refuses
it outside them, however correct everything else is.** Expiry is the single commonest reason a
working site suddenly stops working, and it is entirely predictable: the date is printed in the
certificate from the day it is issued.

## Three certificates, three end dates

```
ana@lab:~/lab$ for c in portal agenda files; do printf "%-7s " $c; openssl x509 -in pki/$c.pem -noout -enddate; done
portal  notAfter=Nov 17 00:00:00 2026 GMT
agenda  notAfter=Apr 10 00:00:00 2026 GMT
files   notAfter=Aug 20 00:00:00 2026 GMT
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A calendar from January to December 2026 with the lab&#x27;s present, 15 June, marked. agenda.vereda.example ran from 10 January to 10 April and has expired. files.vereda.example runs from 1 February to 20 August but was revoked on 20 May. portal.vereda.example runs from 1 May to 17 November and is valid now, with 154 days left.\"><polyline points=\"160.0,26 160.0,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><text x=\"163.0\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jan</text><polyline points=\"293.1506849315068,26 293.1506849315068,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><text x=\"296.1506849315068\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Apr</text><polyline points=\"427.7808219178082,26 427.7808219178082,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><text x=\"430.7808219178082\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jul</text><polyline points=\"563.8904109589041,26 563.8904109589041,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><text x=\"566.8904109589041\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Oct</text><text x=\"20\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">agenda.pem</text><rect x=\"173.31506849315068\" y=\"40\" width=\"133.15068493150685\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"179.31506849315068\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">expired</text><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">files.pem</text><rect x=\"205.86301369863014\" y=\"86\" width=\"295.8904109589041\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"211.86301369863014\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">revoked 20 May</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">portal.pem</text><rect x=\"337.5342465753425\" y=\"132\" width=\"295.89041095890406\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"412.1095890410959\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">valid, 154 days left</text><polyline points=\"365.64383561643837,86 365.64383561643837,114\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></polyline><polyline points=\"404.1095890410959,30 404.1095890410959,200\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></polyline><text x=\"404.1095890410959\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">now: 15 June 2026</text></svg>", "caption": "Three certificates against one instant: expired, revoked, valid."}
```

The lab's present is 15 June 2026. The agenda server's certificate ended on 10 April, and checking
it now says so:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/agenda.pem
C = BR, O = Vereda Fisioterapia, CN = agenda.vereda.example
error 10 at 0 depth lookup: certificate has expired
error pki/agenda.pem: verification failed
```

The same certificate, checked as of 1 March, when it was within its dates, passes:

```
ana@lab:~/lab$ openssl verify -attime $(date -d "2026-03-01 12:00 -03" +%s) -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/agenda.pem
pki/agenda.pem: OK
```

Nothing about the certificate changed between the two commands. Only the clock did. That is worth
remembering when a check fails on one machine and passes on another: a server whose clock is wrong,
often a virtual machine restored from an old snapshot or a device that lost its battery, rejects
valid certificates and can accept expired ones.

## How long is left

The portal's certificate is fine today. How fine:

```
ana@lab:~/lab$ echo $(( ($(date -d "$(openssl x509 -in pki/portal.pem -noout -enddate | cut -d= -f2)" +%s) - 1781535600) / 86400 )) days left on portal.pem
154 days left on portal.pem
```

154 days. A monitoring check should compute exactly this for every certificate a team is
responsible for, including internal ones, and alert well before zero: thirty days is common, which
leaves time to notice a renewal that failed silently. With the maximum lifetime dropping to 100 and
then 47 days (lesson 8), renewal stops being a yearly task somebody remembers and becomes a job that
runs on its own, through ACME, and is watched.

## Expiry is a security property, not paperwork

It is tempting to treat expiry as an inconvenience and to issue internal certificates for ten
years. The dates are there because nothing else bounds a mistake: a private key that leaked without
anybody noticing, a certificate issued for a name somebody no longer controls, an algorithm that
weakened. Revocation, two sections on, is supposed to handle those and often does not. **The
`Not After` date is the one limit every client enforces**, so a shorter one is a stronger guarantee.
