---
title: One API, and the signed request every client sends
version: 1
---

**Every way of using AWS ends in the same thing: an HTTPS request to a service's endpoint, signed
with Signature Version 4.** The command line, an SDK, a `curl` typed by hand and the console in a
browser are four programs that build that request; the service cannot tell them apart by anything
but a `User-Agent` header, and it applies the same policies to all of them. This lesson takes the
request apart, sends one by hand, and ends the course.

The wrong picture is that the console is AWS and the command line is a tool on the side. **The API
is AWS**, and every client is a convenience layered over it. That is why a permission works the
same whether a person clicks or a script calls, and why lesson 12's leaked key needs no console to
do damage.

## The request the command line sent

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS. `--debug` prints a few hundred lines for one command. **The `grep` in the command
keeps five of them**, the method and address, the body, and three headers, and cuts everything else
it printed:

```
ana@laptop:~/aws$ aws sts get-caller-identity --debug 2>&1 | grep -oE "'body': \{[^}]*\}|method=POST, url=[^,]*|'(Content-Type|X-Amz-Date|Authorization)': b'[^']*'"
'body': {'Action': 'GetCallerIdentity', 'Version': '2011-06-15'}
method=POST, url=http://localhost:4567/
'Content-Type': b'application/x-www-form-urlencoded; charset=utf-8'
'X-Amz-Date': b'20261016T190152Z'
'Authorization': b'AWS4-HMAC-SHA256 Credential=test/20261016/sa-east-1/sts/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=dd8c5bbd7312a210d418c1ef957215a5aee54248ae42856cba4e9067667c8484'
```

Read it as the request STS received:

- **a `POST` to the endpoint**, `http://localhost:4567/` here because `env.sh` points every service
  at moto, and `https://sts.sa-east-1.amazonaws.com/` against AWS;
- **a body naming the action and the API version**, `Action=GetCallerIdentity` and
  `Version=2011-06-15`, sent as a form;
- **the time**, `X-Amz-Date`, which is part of what is signed, so a captured request cannot be
  replayed for ever: AWS refuses one whose time is too far from its own clock;
- **the `Authorization` header**: the algorithm, the key id with the date, region and service it
  is scoped to, the list of headers that were signed, and the signature itself.

**The secret is not in the request.** The signature is a hash that only somebody holding the secret
could have computed, and AWS, which holds a copy, computes it again and compares.

## How the signature is made

SigV4 builds a **canonical request**, a fixed spelling of the method, path, query, signed headers
and a hash of the body, so that both sides hash exactly the same bytes. `--debug` prints it too:

```
ana@laptop:~/aws$ aws sts get-caller-identity --debug 2>&1 | grep -A9 "CanonicalRequest:" | sed "s/^.* - DEBUG - //"
CanonicalRequest:
POST
/

content-type:application/x-www-form-urlencoded; charset=utf-8
host:localhost:4567
x-amz-date:20261016T190153Z

content-type;host;x-amz-date
ab821ae955788b0e33ebd34c208442ccfc2d406e2edc5e7a39bd6458fbb4f843
```

The `sed` strips the log prefix from the first line. The canonical request is hashed and put into a
**string to sign** with the date and the scope `20261016/sa-east-1/sts/aws4_request`. The key that
signs it is not the secret itself but one **derived** from it in four steps, the date, the region,
the service and the fixed word `aws4_request`, so a signing key leaked from one day, region and
service is good for nothing else.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l26-sigv4\" aria-label=\"How a Signature Version 4 signature is made, in two columns. On the left, the request: the canonical request (method, path, query, signed headers and a hash of the body) is hashed and put into the string to sign with the date and the scope. On the right, the key: the secret is combined with the date, then the region, then the service, then the word aws4_request, giving the signing key. The signing key signs the string to sign, and the result goes into the Authorization header. The secret itself is never sent.\"><defs><marker id=\"l26-sigv4-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l26-sigv4-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l26-sigv4-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"170.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">the request</text><text x=\"540.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">the key</text><rect x=\"60.0\" y=\"44.0\" width=\"220.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">canonical request</text><text x=\"170.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST / host x-amz-date</text><path d=\"M170.0 102.0 L170.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-paper-dim)\"></path><text x=\"180.0\" y=\"121.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SHA-256</text><rect x=\"60.0\" y=\"142.0\" width=\"220.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">string to sign</text><text x=\"170.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20261016/sa-east-1/sts</text><rect x=\"460.0\" y=\"28.0\" width=\"160.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">secret</text><rect x=\"460.0\" y=\"72.0\" width=\"160.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+ 20261016</text><rect x=\"460.0\" y=\"116.0\" width=\"160.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+ sa-east-1</text><rect x=\"460.0\" y=\"160.0\" width=\"160.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+ sts</text><rect x=\"460.0\" y=\"204.0\" width=\"160.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">+ aws4_request</text><path d=\"M540.0 61.0 L540.0 71.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-paper-dim)\"></path><path d=\"M540.0 105.0 L540.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-paper-dim)\"></path><path d=\"M540.0 149.0 L540.0 159.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-paper-dim)\"></path><path d=\"M540.0 193.0 L540.0 203.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-paper-dim)\"></path><text x=\"630.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">HMAC</text><text x=\"552.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">signing key</text><rect x=\"240.0\" y=\"262.0\" width=\"240.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Authorization: … Signature=…</text><path d=\"M170.0 200.0 L170.0 284.0 L238.0 284.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-phosphor)\"></path><path d=\"M540.0 237.0 L540.0 284.0 L482.0 284.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-sigv4-af-ah-amber)\"></path><text x=\"360.0\" y=\"322.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">the secret signs; it is never sent</text></svg>", "caption": "Both sides compute the same signature: the client from its secret, AWS from its copy."}
```

## Signing by hand with `curl`

`curl` has known SigV4 since version 7.75: `--aws-sigv4` names the provider, region and service,
and `--user` gives the key id and secret. That is the whole of an AWS client, in one command:

```
ana@laptop:~/aws$ curl -s --aws-sigv4 "aws:amz:sa-east-1:sts" --user test:test -d 'Action=GetCallerIdentity&Version=2011-06-15' http://localhost:4567/; echo
<GetCallerIdentityResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/"><GetCallerIdentityResult><UserId>AKIAIOSFODNN7EXAMPLE</UserId><Account>123456789012</Account><Arn>arn:aws:sts::123456789012:user/moto</Arn></GetCallerIdentityResult><ResponseMetadata><RequestId>3TDb3dzK2QmumYo7ZldnIn1yTcYAUa7IjkwdkKxaAxRIyDDVRGn8</RequestId></ResponseMetadata></GetCallerIdentityResponse>
ana@laptop:~/aws$ curl -s -o /dev/null -v --aws-sigv4 "aws:amz:sa-east-1:sts" --user test:test -d 'Action=GetCallerIdentity&Version=2011-06-15' http://localhost:4567/ 2>&1 | grep -iE "^> (POST|authorization|x-amz-date)"
> POST / HTTP/1.1
> Authorization: AWS4-HMAC-SHA256 Credential=test/20261016/sa-east-1/sts/aws4_request, SignedHeaders=host;x-amz-date, Signature=ac65559ddf52040c5090812a8e6c82daa8f9832bb58188e7694bbf7621c7c51d
> X-Amz-Date: 20261016T190153Z
```

**The answer is XML**, the raw form the command line turned into the JSON it prints. The second
command shows the headers `curl` sent, with an `Authorization` of the same shape the command line
built and a shorter `SignedHeaders`, since `curl` chose to sign only two. moto accepted both. Here
it checks no permissions, so it would accept an unsigned request as well; lesson 7's checking is
what makes the signature matter in the lab, and AWS always does.

Signing by hand is how to call AWS from a language or a tool with no SDK, and how to understand
what an SDK does. **For anything that runs every day, use an SDK**, which also handles the
retries, the pages and the credential chain that the rest of this lesson and lesson 10 describe.
