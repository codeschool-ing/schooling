---
title: A bucket on the laptop
version: 2
---

The S3 interface is HTTP, so it can be imitated. **moto** is a Python program written for testing
code that talks to AWS: `moto_server` listens on a port of the laptop and answers S3's requests the
way S3 answers them, keeping the objects in its own memory. This section points the real AWS CLI at
it, which shows the shape of the interface: the requests, the answers, what a key and a prefix are.
**It says nothing about S3's latency, durability or price.** Nothing it stores leaves the laptop, and
it accepts credentials AWS would refuse.

Lesson 1 installed moto in the course's virtual environment. Start it in the background, with its
log going to a file this section reads later, and make two small files to upload: a "photo" of a
hundred bytes, all of them `x`, which S3 has no opinion about, and a report of one line:

```
ana@laptop:~/cloud$ moto_server -p 5000 > moto.log 2>&1 &
ana@laptop:~/cloud$ head -c 100 /dev/zero | tr '\0' 'x' > cat.jpg
ana@laptop:~/cloud$ printf 'hello\n' > report.txt
ana@laptop:~/cloud$ wc -c cat.jpg report.txt
100 cat.jpg
  6 report.txt
106 total
```

The `&` at the end of the first line runs moto in the background, so the same terminal stays free
for the rest of the session; an interactive shell answers it with a job number and a process id.
Give it a second to start before the next command. When you finish with this lesson, `kill %1`
stops it, and its objects go with it, because it kept them in memory. Then close the terminal, or
`unset` the four variables the next block exports: the later lessons expect a CLI with no
credentials, and these would send its requests to a moto that is no longer there.

The CLI has to be told where to send its requests and needs some credentials to sign them with.
Four variables do both: the word `test` as the key pair, a region, and moto's address instead of
AWS's. The rest is ordinary `aws s3` commands:

```
ana@laptop:~/cloud$ export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=sa-east-1 AWS_ENDPOINT_URL=http://127.0.0.1:5000
ana@laptop:~/cloud$ aws s3 mb s3://ana-uploads
make_bucket: ana-uploads
ana@laptop:~/cloud$ aws s3 cp --no-progress cat.jpg s3://ana-uploads/photos/2026/cat.jpg
upload: ./cat.jpg to s3://ana-uploads/photos/2026/cat.jpg
ana@laptop:~/cloud$ aws s3 cp --no-progress report.txt s3://ana-uploads/reports/q3.txt
upload: ./report.txt to s3://ana-uploads/reports/q3.txt
```

`mb` made a bucket. Each upload became one `PUT`, and the key is the whole string after the bucket
name; nothing had to exist at `photos/` or `photos/2026/` first.

Now list it three ways:

```
ana@laptop:~/cloud$ aws s3 ls s3://ana-uploads
                           PRE photos/
                           PRE reports/
ana@laptop:~/cloud$ aws s3 ls s3://ana-uploads --recursive
2026-10-07 07:57:11        100 photos/2026/cat.jpg
2026-10-07 07:57:12          6 reports/q3.txt
ana@laptop:~/cloud$ aws s3api list-objects-v2 --bucket ana-uploads --query 'Contents[].Key'
[
    "photos/2026/cat.jpg",
    "reports/q3.txt"
]
```

**The first listing, without `--recursive`, asked the store to cut the keys at `/`.** It returned two
`PRE` lines, prefixes, and no objects, because every key has a slash in it. The second listed every
key in full. The third, through the lower-level `s3api` command, shows what the bucket holds: two
keys, strings with slashes in them, and nothing called `photos/`.

## Renaming is a copy and a delete

`aws s3 mv` looks like `mv`. What it sends is in moto's own log, which records one line per HTTP
request, and `grep` picks out the method and the path of every line about `reports`:

```
ana@laptop:~/cloud$ aws s3 mv --no-progress s3://ana-uploads/reports/q3.txt s3://ana-uploads/reports/2026-q3.txt
move: s3://ana-uploads/reports/q3.txt to s3://ana-uploads/reports/2026-q3.txt
ana@laptop:~/cloud$ grep -o '[A-Z]* /ana-uploads/reports[^ ]*' moto.log
PUT /ana-uploads/reports/q3.txt
HEAD /ana-uploads/reports/q3.txt
PUT /ana-uploads/reports/2026-q3.txt
DELETE /ana-uploads/reports/q3.txt
```

Read the log from the top. The first `PUT` is the upload from earlier. Then the move: a `HEAD` to
read the source object's metadata, a `PUT` to the new key, and a `DELETE` of the old one. The middle
request is a copy: the CLI sends it as a `PUT` carrying a header that names the source object, so
the bytes are copied inside the store rather than downloaded and uploaded again.

**Three requests for one rename**, and between the copy and the delete both keys exist. A program
renaming ten thousand objects sends thirty thousand requests, pays for every one, and can be
interrupted halfway, leaving some objects under both names. That is why data laid out for an object
store picks its keys once. A key that carries something likely to change, such as a customer's name
or the team that owns a report, is a key that will be copied and deleted on the day it changes.
