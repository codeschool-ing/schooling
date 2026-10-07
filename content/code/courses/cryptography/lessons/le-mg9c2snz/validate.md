---
title: Checking the server before saying anything
version: 1
---

**Everything in the last section rests on two lines of the profile, `ca_cert` and
`domain_suffix_match`. Anybody can set up an access point that broadcasts `Vereda-Equipe` and a
RADIUS server behind it. The only thing that tells a laptop it has reached Vereda's server rather
than that one is the certificate, and only if the laptop checks it.** This section points the same
laptop at an impostor twice.

## The certificate the laptop expects

Vereda's RADIUS certificate is an ordinary server certificate from lesson 9, issued by the clinic's
own CA for one name:

```
ana@lab:~/lab$ openssl x509 -in pki/radius.pem -noout -subject -issuer -ext subjectAltName,extendedKeyUsage
subject=C = BR, O = Vereda Fisioterapia, CN = radius.vereda.example
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
X509v3 Extended Key Usage: 
    TLS Web Server Authentication
X509v3 Subject Alternative Name: 
    DNS:radius.vereda.example
ana@lab:~/lab$ openssl verify -attime 1781535600 -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/radius.pem
pki/radius.pem: OK
```

## An impostor with the same names

The lab has a second RADIUS server, at 127.0.0.2, standing in for a fake access point in the car park.
Its certificate claims every name Vereda's does, including an issuer called `Vereda Root CA`. It was
made by the lab's impostor root of lesson 9, which anybody can create with one command:

```
ana@lab:~/lab$ openssl x509 -in pki/radius-impostor.pem -noout -subject -issuer -ext subjectAltName
subject=C = BR, O = Vereda Fisioterapia, CN = radius.vereda.example
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA
X509v3 Subject Alternative Name: 
    DNS:radius.vereda.example
```

With the profile from the last section, the laptop refuses it before sending anything:

```
ana@lab:~/lab$ eapol_test -c peap.conf -a 127.0.0.2 -s lab-only-radius-secret | vcrypt eap-log
outer identity, in clear:  anonymous@vereda.example
method:                    PEAP
TLS version:               TLSv1.2
server certificate:        depth 0  /C=BR/O=Vereda Fisioterapia/CN=radius.vereda.example
                           depth 0  name DNS:radius.vereda.example
certificate REFUSED:       depth 0, unable to get local issuer certificate
                           alert sent to the server: unknown CA
result:                    FAILURE
```

The names matched. The **signature** did not: no chain led from this certificate to the root in
`pki/root.pem`, so the TLS handshake ended with an `unknown CA` alert. The inner identity and the
MSCHAPv2 exchange never left the laptop. This is the outcome to aim for, and it costs nothing at the
moment it happens. The person sees a network that would not connect.

Now the same laptop with a careless profile, the one a person ends up with after clicking through a
settings screen. The only difference is the two lines:

```
ana@lab:~/lab$ diff peap.conf peap-lax.conf
9,10d8
< 	ca_cert="pki/root.pem"
< 	domain_suffix_match="radius.vereda.example"
```

```
ana@lab:~/lab$ eapol_test -c peap-lax.conf -a 127.0.0.2 -s lab-only-radius-secret | vcrypt eap-log
outer identity, in clear:  anonymous@vereda.example
method:                    PEAP
TLS version:               TLSv1.2
server certificate:        depth 0  /C=BR/O=Vereda Fisioterapia/CN=radius.vereda.example
                           depth 0  name DNS:radius.vereda.example
inside the tunnel:         inner identity sent
                           MSCHAPv2 challenge answered
result:                    FAILURE
```

**The laptop accepted the impostor's certificate, opened the tunnel to it and answered its MSCHAPv2
challenge.** The result says `FAILURE` only because this impostor did not know ana's password and
could not complete the exchange. It did not need to. It now holds a challenge and a response computed
from that password, which the previous section said can be tested against guesses offline, and the
laptop's owner saw nothing worse than a network that failed to connect.

## Why both lines

- **`ca_cert` alone** accepts any certificate that chains to that root. With Vereda's private root,
  that is enough in practice. With the system's list of public CAs instead, it would accept any
  certificate any of those hundreds of authorities issued for any name.
- **`domain_suffix_match` alone** checks a name with no chain behind it, and the impostor had the
  right name. A name proves nothing until a trusted signature vouches for it, which was lesson 9's
  whole argument.
- **Together** they say: a certificate for this name, issued by this CA. Using a private CA that
  issues nothing but the RADIUS certificate narrows it further.

## Getting the profile onto every device

The weak point is never the server. It is the profile on each device, and the setting screens of
the main operating systems make it easy to get wrong. Windows asks whether to "connect" when it meets
an unknown server certificate, Android has offered "do not validate" as a choice, and the answer to
"do you trust this?" is always yes. The defence is to **remove the question**:

- Managed laptops and phones receive the Wi-Fi profile from the device-management system, with the CA
  and the server name already filled in and the prompt switched off. On Windows that means **Verify
  the server's identity by validating the certificate**, the server name in **Connect to these
  servers**, Vereda's root ticked under **Trusted Root Certification Authorities**, and **Don't
  prompt user to authorize new servers**.
- Devices that cannot be managed join a separate network, never the staff one.
- Where every device is managed, **EAP-TLS** removes the password from the picture: a client that
  talks to an impostor gives it a certificate, which is public anyway, and nothing to guess.

On the network side, wireless monitoring that alerts on any access point broadcasting `Vereda-Equipe`
from an unknown hardware address finds the impostor that the profiles defeat.
