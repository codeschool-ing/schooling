---
title: Encryption in transit, and refusing the requests without it
version: 1
---

**Encryption in transit is TLS between whoever sends a request and whoever answers it. In the cloud
there are two different stretches to protect: the one to the provider's API, and the ones between
your own machines.** The first is the provider's to offer and yours to insist on. The second
is entirely yours.

The wrong idea is that traffic inside the cloud is private because nobody outside can reach it. The
`cloud` course's lesson 6 built networks whose private subnets nobody on the internet can reach,
and that is true. It does not make the traffic between two of your machines encrypted; it makes it
unreachable from one direction, which is a different property. A misrouted peering connection, a
compromised machine in the same network, or a provider's own engineer are all inside.

## The stretch to the API

Every AWS API endpoint answers over HTTPS, and AWS's documentation sets TLS 1.2 as the minimum its
endpoints accept. The AWS command line, the SDKs and the console all use it, so the requests you send
to a real account are encrypted without your asking. The `cryptography` course's lesson 10 walked
through what that handshake does and how it fails.

**Your lab is the exception, and on purpose.** `env.sh` points the command line at
`http://localhost:4567`: plain HTTP, to a program on the same computer, over the loopback interface
that never leaves the machine. Nothing in it crosses a network, so nothing in it needs TLS; the same
URL pointed at another machine would send your requests, keys and signatures included, in the open.

## Insisting on it, per bucket

S3 is reachable over plain HTTP as well as HTTPS, for old clients. A bucket can refuse every request
that did not arrive over TLS, with a condition key AWS sets on every request,
`aws:SecureTransport`, which is `false` when the request came without it:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TLSOnly",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::clinic-records",
        "arn:aws:s3:::clinic-records/*"
      ],
      "Condition": { "Bool": { "aws:SecureTransport": "false" } }
    }
  ]
}
```

Two details make it work. **It is a `Deny` with `"Principal": "*"`**, so it binds every caller,
administrators included, and no `Allow` anywhere can undo it. And **it names the bucket and its
objects as two resources**, because `s3:*` covers actions on both and an ARN without `/*` matches
only the bucket. Requests for objects under a KMS key already need TLS, as the section on two locks
said they need a signature; this policy makes the same rule hold for every object in the bucket.
moto stores this policy and ignores its condition, so **its effect was not run here**; it is taken
from S3's documentation of the key.

## The stretches between your machines

Inside a VPC, encryption is what you configure:

- **a load balancer** terminates TLS from the internet, and then either forwards plain HTTP to the
  machines behind it or opens a second TLS connection to them. The second costs a certificate on
  each machine and closes the gap between the balancer and the application;
- **a database** connection is encrypted only if the client asks for it and the server requires it.
  Managed databases offer a setting that refuses unencrypted connections, and on some engines it
  starts switched off;
- **traffic between services** inside one network is plain unless something wraps it. A service
  mesh, or TLS in the application, are the two ways.

Each of those is one more setting, and the thread of this course holds here too: **in the cloud, the
encryption exists; whether a given connection uses it is a configuration somebody chose.**
