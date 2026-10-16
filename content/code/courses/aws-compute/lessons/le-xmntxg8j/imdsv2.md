---
title: "IMDSv2: a token before every read"
version: 1
---

The first version of the metadata service, IMDSv1, answered any `GET` that reached it. That
sounds harmless when "reached it" means "came from the instance". **The trouble is that a great
deal of software on an instance will send a request to an address somebody else chose.** Think of a
web application that fetches a picture from a URL the user typed, a webhook sender, a PDF
renderer following links, or a misconfigured reverse proxy. Given `http://169.254.169.254/...` as
the address, each of them makes the request from the instance, and the metadata service sees the
instance asking.

That class of flaw is called server-side request forgery, SSRF, and against IMDSv1 it was a short
path from a bug in one application to the role's credentials. It is not hypothetical. In 2019 a
misconfigured firewall in front of Capital One's application was made to request the
credentials path, and the role's keys it returned were used to copy the records of about a
hundred million people out of S3. **The flaw was in the application; what made it expensive was a
metadata service that trusted any request.**

## Two requests instead of one

IMDSv2, which AWS released in November 2019, makes every session start with a `PUT`:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 356\" role=\"img\" aria-label=\"A sequence between three parties: the metadata service at 169.254.169.254, a process on the instance, and a container behind a bridge one hop further away. The process sends a PUT to /latest/api/token with a TTL header and receives a token, then sends a GET for the role's credentials with the token in a header and receives the role name. The container sends the same PUT, but the reply is dropped at the bridge because the hop limit of 1 is used up.\"><defs><marker id=\"imds-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"12\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">metadata service</text><text x=\"110\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">169.254.169.254</text><path d=\"M110 58 L110 318\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><rect x=\"280\" y=\"12\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">a process on the instance</text><text x=\"380\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the CLI, an SDK, your script</text><path d=\"M380 58 L380 318\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><rect x=\"515\" y=\"12\" width=\"190\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">a container</text><text x=\"610\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">behind a bridge, one hop more</text><path d=\"M610 58 L610 318\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\" fill=\"none\"></path><text x=\"245\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PUT /latest/api/token</text><path d=\"M380 96 L112 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#imds-ah)\"></path><text x=\"245\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">header: token lifetime, 300 s</text><text x=\"245\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a token</text><path d=\"M110 140 L378 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#imds-ah)\"></path><text x=\"245\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the reply's IP TTL is the hop limit</text><text x=\"245\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET …/security-credentials/</text><path d=\"M380 188 L112 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#imds-ah)\"></path><text x=\"245\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">token in a header</text><text x=\"245\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the role's name</text><path d=\"M110 234 L378 234\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#imds-ah)\"></path><text x=\"495\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PUT /latest/api/token</text><path d=\"M610 274 L112 274\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#imds-ah)\"></path><path d=\"M110 302 L440 302\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M444 294 L460 310 M460 294 L444 310\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"470\" y=\"302\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">dropped at the bridge</text><text x=\"360\" y=\"338\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">with a hop limit of 1, the token reply cannot survive one more hop</text></svg>", "caption": "A token before every read. The PUT asks for a token and says how long it should live; every GET then carries it. The reply to the PUT leaves with an IP time-to-live equal to the hop limit, so with a limit of 1 it reaches a process on the instance and dies at the first bridge a container sits behind."}
```

1. A `PUT` to `/latest/api/token`, with a header `X-aws-ec2-metadata-token-ttl-seconds` saying how
   long the token should live, from 1 second to 21,600, which is six hours. The answer is the
   token.
2. Every read afterwards carries it, in a header `X-aws-ec2-metadata-token`. A read with a wrong
   or expired token gets `401 Unauthorized`.

The first section's `first-boot.sh` did exactly this with `curl`, and the CLI did it on its own in
the last section. Here are the same two steps by hand against moto's placeholders:

```
ana@laptop:~/aws$ TOKEN=$(curl -s -X PUT localhost:4567/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
ana@laptop:~/aws$ echo "$TOKEN"
fake-imdsv2-token
ana@laptop:~/aws$ curl -s -H "X-aws-ec2-metadata-token: $TOKEN" localhost:4567/latest/meta-data/iam/security-credentials/; echo
default-role
ana@laptop:~/aws$ curl -s -H "X-aws-ec2-metadata-token: not-a-token" localhost:4567/latest/meta-data/iam/security-credentials/; echo
default-role
```

**moto hands out a constant and checks nothing**: the token is the string `fake-imdsv2-token`,
and the request carrying `not-a-token` was answered as if it were valid. On AWS the token is an
opaque value tied to that one instance, and the last request above gets `401`. Nothing in this
lab can show the refusal, so the rest of this section is AWS's documented behaviour and was not
run.

## What the token stops, and how

**Each of the three defences is aimed at a way SSRF reached the old service.**

The first is the method and the header. The requests a forged URL produces are almost always
`GET`s, with headers the vulnerable program chose rather than the attacker. A `PUT` with a
custom header is something most of those programs cannot be made to send, so they never get a
token, and without one the reads fail.

The second is aimed at proxies. An open or misconfigured reverse proxy forwards whatever method it
is given, but it adds an `X-Forwarded-For` header naming the original client. **The metadata
service refuses a token `PUT` that carries `X-Forwarded-For`**, so the proxy that relays a request
also announces that it is a relay and is turned away.

The third is the **hop limit**, `HttpPutResponseHopLimit`, and it is the one that needs a picture.
The reply to the `PUT` leaves with its IP time-to-live set to the hop limit. Every router or
bridge it crosses lowers that by one, and at zero the packet is dropped. With the limit at 1, the
reply reaches a process on the instance itself and nothing further: a container on a Docker
bridge network sits one hop away, and its token request is answered with a packet that dies on
the way.

That last point cuts both ways, which is why the limit is a setting rather than a constant. **A
container that cannot get a token cannot borrow the instance's role**, which is what you want when
the containers are somebody else's code. It is also why an agent in a container that legitimately
needs the instance's metadata fails with a timeout rather than an error. AWS's advice for instances
that run containers is a hop limit of 2. The better answer for a container that needs AWS
credentials is a role of its own rather than the instance's: an ECS task role, in lesson 8, and a
pod's role through IRSA, in lesson 13.

## What it does not stop

IMDSv2 removes the cheap path. It does not make the credentials secret from the instance. **Any
program running on the instance that sends its own requests can still send the `PUT`.** Code an
attacker has managed to run there, rather than merely trick into fetching a URL, reads the role's
keys exactly as the CLI did. The defence for that limits what the role can do once it is read. It
means a role with only the permissions the instance needs, which is `aws-foundations` lesson 7's
least privilege, and nothing on the instance that runs code it was not meant to.
