---
title: Signed URLs, and what a URL carries
version: 1
---

**A signed URL is a request that somebody signed in advance and handed over**: whoever holds the URL
can make that one request, with the signer's authority, until it expires. It is how Quitanda lets a
supplier download one invoice without a Google account, and it is not a link to a public object. The
object stays private. What travels is permission, written into a string.

The wrong picture is that the URL is checked against something Cloud Storage keeps, a list of the
links that were issued. Nothing is kept. **The signature is computed on the signer's computer, from a
private key, and Cloud Storage checks it only when the URL is used**, by rebuilding the same request
and verifying the signature with the signer's public key. Making a URL sends nothing to anybody.

## A key for an account that does not exist

Signing needs a private key, and a real one belongs to a real service account. This lab uses neither.
**The key below is made on your laptop by `openssl`, for a service account invented for this lesson,
`report-signer@planner-dev.iam.gserviceaccount.com`, which exists in no project.** Google has never
seen the key and no Google service would accept what it signs; it can sign, which is all the lesson
needs. Never use a real service account's key for an exercise, and never paste one into a terminal
you are recording: `gcp-foundations` lesson 8 is about why a downloaded key is the last resort even
for real work.

```sh
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out signer.pem
```

That is a 2,048-bit RSA private key in `signer.pem`. The client library reads keys in the format of a
service account key file, a JSON document, so a short program wraps it in one:

`make-key.py`:

```python
"""Wrap a key made on this laptop in the shape of a service account key file.

The account does not exist and Google has never seen this key. It can sign a
URL, and no Google service anywhere will accept what it signs.
"""
import json

json.dump({
    'type': 'service_account',
    'project_id': 'planner-dev',
    'private_key_id': 'local-only',
    'private_key': open('signer.pem').read(),
    'client_email': 'report-signer@planner-dev.iam.gserviceaccount.com',
    'client_id': '0',
    'token_uri': 'https://oauth2.googleapis.com/token',
}, open('signer-key.json', 'w'), indent=2)
print('wrote signer-key.json for report-signer@planner-dev.iam.gserviceaccount.com')
```

```
ana@laptop:~/gcp$ python3 make-key.py
wrote signer-key.json for report-signer@planner-dev.iam.gserviceaccount.com
ana@laptop:~/gcp$ python3 -c 'import json; k = json.load(open("signer-key.json")); print(k["client_email"], k["private_key"].splitlines()[0])'
report-signer@planner-dev.iam.gserviceaccount.com -----BEGIN PRIVATE KEY-----
```

**`signer-key.json` now holds a private key, and it is treated like one**: it stays in `~/gcp`, it is
never committed anywhere, and the last command printed only its first line, the PEM header, to show
what kind of file it is. The rest of the key does not go on a screen.

## Signing a URL

The program that signs, saved as `~/gcp/sign.py`, takes an object's name and a number of seconds:

```schooling-example
{"language": "python", "file": "sign.py", "parts": [{"code": "\"\"\"Sign a V4 URL for one object of the curated bucket, on this laptop.\"\"\"\nimport datetime\nimport sys\n\nfrom google.cloud import storage\nfrom google.oauth2 import service_account\n\n", "note": "Two libraries from the course's virtual environment: the Cloud Storage client, and Google's authentication library, which reads a key file."}, {"code": "key, seconds = sys.argv[1], int(sys.argv[2])\ncreds = service_account.Credentials.from_service_account_file('signer-key.json')\nclient = storage.Client(credentials=creds, project='planner-dev')\nblob = client.bucket('quitanda-curated-prod').blob(key)\n\n", "note": "**Nothing here sends a request.** Reading the key file and naming a bucket and an object are local steps; the client does not ask whether either exists."}, {"code": "print(blob.generate_signed_url(version='v4', method='GET',\n                               expiration=datetime.timedelta(seconds=seconds)))\n", "note": "`generate_signed_url` builds the request a reader will make, signs it with the private key, and returns it as a URL. Because `STORAGE_EMULATOR_HOST` is set, the address is the emulator's; on Google it would be `https://storage.googleapis.com/…`."}]}
```

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-curated-prod --location=southamerica-east1
Creating gs://quitanda-curated-prod/...
ana@laptop:~/gcp$ printf 'day,orders,total_cents\n2026-10-29,412,5108840\n' > daily.csv && gcloud storage cp daily.csv gs://quitanda-curated-prod/reports/daily.csv
Copying file://daily.csv to gs://quitanda-curated-prod/reports/daily.csv
  

ana@laptop:~/gcp$ python3 sign.py reports/daily.csv 300 | tr '?&' '\n\n' | cut -c1-120
http://localhost:4443/quitanda-curated-prod/reports/daily.csv
X-Goog-Algorithm=GOOG4-RSA-SHA256
X-Goog-Credential=report-signer%40planner-dev.iam.gserviceaccount.com%2F20261030%2Fauto%2Fstorage%2Fgoog4_request
X-Goog-Date=20261030T185330Z
X-Goog-Expires=300
X-Goog-SignedHeaders=host
X-Goog-Signature=7975368cb0a13301b7547dbd2fc6bc2b4d27febd9c94a11ab2d3a1e1aff92efc3b93be9cd1e3e343b14a823b17398f702834d4a
```

**The URL is the object's address with six parameters**, and they are the whole of the permission:

| parameter | what it says |
|---|---|
| `X-Goog-Algorithm` | the signing method: Google's V4 signing, with an RSA key and SHA-256 |
| `X-Goog-Credential` | who signed, the date, the location and the service |
| `X-Goog-Date` | the moment it was signed |
| `X-Goog-Expires` | how many seconds after that moment it stays valid |
| `X-Goog-SignedHeaders` | which headers the signature covers, here only `host` |
| `X-Goog-Signature` | the RSA signature over all of it, in hexadecimal, shown cut to the line here |

Two consequences follow from that table. **The signer's identity is in the URL**: a signed URL
pasted into a chat tells everybody who reads it which service account signed it. The key is not in
it. And **the URL says nothing about who may use it**: no address, no account, no password.
Possession is the whole check. `auto` in the credential is the location the Python library writes;
the command line, below, writes the bucket's region instead, and Cloud Storage accepts both.

## Using it, and what the emulator checks

```
ana@laptop:~/gcp$ curl -s -w '%{http_code}\n' "$(python3 sign.py reports/daily.csv 300)"
Not Found
404
ana@laptop:~/gcp$ curl -s -w '%{http_code}\n' -H 'Host: storage.googleapis.com' "$(python3 sign.py reports/daily.csv 300)"
day,orders,total_cents
2026-10-29,412,5108840
200
ana@laptop:~/gcp$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: storage.googleapis.com' "$(python3 sign.py reports/no-such-report.csv 300)"
404
```

**The first `curl` was answered `Not Found`, and the second, with one header added, got the
report.** fake-gcs-server serves an address of the form `/bucket/object` only when the request says
it is for Google's host, `storage.googleapis.com`; the client library wrote the emulator's address
into the URL, and `-H 'Host: …'` puts Google's name back on the request. That is a detail of the
emulator, and from here on every request to a signed URL carries the header. The third command used a
URL for a report that does not exist: it was signed without complaint, because signing asked nobody,
and only using it found the `404`.

Now the three requests Cloud Storage exists to refuse:

```
ana@laptop:~/gcp$ url=$(python3 sign.py reports/daily.csv 1); sleep 3; curl -s -w '%{http_code}\n' -H 'Host: storage.googleapis.com' "$url"
day,orders,total_cents
2026-10-29,412,5108840
200
ana@laptop:~/gcp$ url=$(python3 sign.py reports/daily.csv 300); curl -s -w '%{http_code}\n' -H 'Host: storage.googleapis.com' "${url%?}x"
day,orders,total_cents
2026-10-29,412,5108840
200
ana@laptop:~/gcp$ curl -s -w '%{http_code}\n' -H 'Host: storage.googleapis.com' http://localhost:4443/quitanda-curated-prod/reports/daily.csv
day,orders,total_cents
2026-10-29,412,5108840
200
```

**A URL valid for one second was used three seconds later, and the emulator served the report.** The
URL with the last character of its signature changed to `x` was served too, and so was the plain
address with no signature at all. fake-gcs-server does not read the signature: it serves any object
to any request. On Cloud Storage all three would be refused: the first with an error saying the
request has expired, the second with one saying the signature does not match, and the third because
the object is private and the request is signed by nobody. None of those answers was produced here; they are the documented behaviour of
cloud.google.com/storage/docs/access-control/signed-urls.

**So in this lab a signed URL can show its shape and nothing about its safety.**

## The limits, which are checked before anything is sent

```
ana@laptop:~/gcp$ python3 sign.py reports/daily.csv 604801 2>&1 | tail -1
ValueError: Max allowed expiration interval is seven days 604800
ana@laptop:~/gcp$ gcloud storage sign-url gs://quitanda-curated-prod/reports/daily.csv --private-key-file=signer-key.json --duration=8d 2>&1 | head -1
ERROR: (gcloud.storage.sign-url) argument -d/--duration: value must be less than or equal to 7d; received: 8d
ana@laptop:~/gcp$ gcloud storage sign-url gs://quitanda-curated-prod/reports/daily.csv --private-key-file=signer-key.json --duration=10m 2>&1 | cut -c1-100 | head -6
---
expiration: '2026-10-30 19:03:37'
http_verb: GET
resource: gs://quitanda-curated-prod/reports/daily.csv
signed_url: https://quitanda-curated-prod.storage.googleapis.com/reports/daily.csv?x-goog-signature=
ERROR: gcloud crashed (ConnectionError): HTTPSConnectionPool(host='quitanda-curated-prod.storage.goo
```

**Seven days is the longest a V4 signature may live**, 604,800 seconds, and both the library and
the command line refuse one second more on your laptop, before any request exists. The last command
signs with the command line, and its output shows two things. The URL it printed is Google's form,
`https://quitanda-curated-prod.storage.googleapis.com/…`, because `sign-url` does not follow the
emulator variables. And the `ERROR` after it is the command line trying, once the URL was printed, to
reach Google with a second URL valid for 60 seconds, to check that the signer can read the object. On
a laptop with no route to Google that check fails; the URL above it was complete before the check
began.

## What makes a signed URL safe

The habits come from Google's documentation, and they are cheap:

- **the shortest expiry that does the job**: minutes for a download a person clicks now, never days;
- **a signer that can read only what it signs for**. Cloud Storage checks the signer's permissions
  when the URL is used, so a service account that may read `reports/` and nothing else signs URLs
  worth one prefix. Removing that permission, or deleting the key, makes every URL it signed stop
  working at once;
- **no key file at all where possible.** `gcloud storage sign-url --impersonate-service-account`
  signs through Google's IAM credentials service, with no private key on any disk; the command
  line's own help limits such URLs to 12 hours, because the key Google uses for them may not remain
  valid for longer;
- **never a URL in a place that is kept**: a ticket, a log line, a commit. The URL is the permission,
  for as long as it lives.
