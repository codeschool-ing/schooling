---
title: An object store, and what it does not do
version: 1
---

**An object store keeps *objects*: a key, a value of any size, and a little metadata.** You write an
object whole, in one request; you read it, or a range of its bytes; you delete it; you list keys by
prefix. That is nearly the whole interface, and it is what Amazon S3 offered in 2006 and what every
cloud's equivalent offers now. Google Cloud Storage and Azure Blob Storage differ in details and
share the model.

It looks like a filesystem from a distance, because keys contain slashes, and it is not one. What it
does not have is the subject of this section and the next:

- **No directories.** `raw/clicks/day=2025-01-01/part-0.csv.gz` is one key. Nothing called
  `raw/clicks/` exists, and "listing a directory" is asking for keys that start with it.
- **No rename.** A new name is a new object: copy, then delete the old one.
- **No append, no edit.** Changing a byte means writing the whole object again.

What it has instead is what made it win in the cloud: storage that grows without anybody adding
disks, priced per gigabyte per month, kept in several copies by the provider, and reachable from
any number of machines at once. A cluster can be shut down at night and its data is still there,
because the data was never on it. Lesson 14 counts what that saves.

## A stand-in on your machine

No company's object store is needed to see the model. `moto` is a Python library that answers the S3
API locally; it is meant for testing programs, keeps everything in memory, and loses it when it
stops, which makes it the right size for a demonstration and the wrong thing to keep data in.
`boto3` is the Python client for S3. Install both in a virtual environment of their own and start
the server in the background:

```sh
python3 -m venv ~/s3-env
~/s3-env/bin/pip install "moto[server]==5.2.3" boto3==1.43.111
setsid ~/s3-env/bin/moto_server -p 9090 > ~/moto.log 2>&1 < /dev/null &
```

`setsid` starts the server in a session of its own, so that closing the terminal does not stop it.
Then this program uploads January, lists it, and moves it, the only way an object store allows. Save
it as `~/big/s3_demo.py`:

```schooling-example
{
  "language": "python",
  "file": "s3_demo.py",
  "parts": [
    {
      "code": "\"\"\"What an object store does differently: upload a month of the clicks, list\nthem, and 'rename' the month the only way an object store can.\"\"\"\nimport glob\nimport time\n\nimport boto3\n\n"
    },
    {
      "code": "s3 = boto3.client(\"s3\", endpoint_url=\"http://localhost:9090\", region_name=\"us-east-1\",\n                  aws_access_key_id=\"test\", aws_secret_access_key=\"test\")\ns3.create_bucket(Bucket=\"pontofinal-lake\")\n\n",
      "note": "The S3 API, pointed at the local stand-in instead of Amazon. The keys are the two words moto accepts; a real store would want real credentials, and the code would be the same."
    },
    {
      "code": "for path in sorted(glob.glob(\"data/raw/clicks/day=2025-01-*/*.csv.gz\")):\n    day = path.split(\"/\")[3]\n    with open(path, \"rb\") as f:\n        s3.put_object(Bucket=\"pontofinal-lake\", Key=f\"raw/clicks/{day}/part-0.csv.gz\", Body=f)\n\n",
      "note": "**An object is written whole, in one request, under a key.** The key looks like a path, slashes and all, and the store does not care: there is no directory `raw/clicks/` anywhere, only thirty-one keys that start with those characters."
    },
    {
      "code": "listing = s3.list_objects_v2(Bucket=\"pontofinal-lake\", Prefix=\"raw/clicks/\", Delimiter=\"/\")\nprint(\"folders:\", len(listing[\"CommonPrefixes\"]), \"first:\", listing[\"CommonPrefixes\"][0][\"Prefix\"])\n\n",
      "note": "Listing asks for keys with a prefix. With a `Delimiter`, the store groups the keys by what comes before the next slash and answers with those groups, which is how a client draws folders that do not exist."
    },
    {
      "code": "start = time.time()\nkeys = [o[\"Key\"] for o in s3.list_objects_v2(Bucket=\"pontofinal-lake\", Prefix=\"raw/\")[\"Contents\"]]\nfor key in keys:\n    s3.copy_object(Bucket=\"pontofinal-lake\", Key=\"archive/\" + key,\n                   CopySource={\"Bucket\": \"pontofinal-lake\", \"Key\": key})\n    s3.delete_object(Bucket=\"pontofinal-lake\", Key=key)\nprint(f\"moved {len(keys)} objects with {2 * len(keys)} requests in {time.time() - start:.2f} s\")\n",
      "note": "**There is no rename.** Moving the month to `archive/` means copying every object to its new key and deleting the old one, one request each, with the month half in each place while it runs."
    }
  ]
}
```

```
ana@lab:~/big$ ~/s3-env/bin/python s3_demo.py
folders: 31 first: raw/clicks/day=2025-01-01/
moved 31 objects with 62 requests in 0.56 s
```

**Thirty-one "folders" that are thirty-one key prefixes, and a move that took sixty-two requests.**
In memory on your own machine, that is about half a second. Against a real object store across a
network, each request costs some tens of milliseconds, so a move of 50,000 objects one at a time is
100,000 requests and the better part of an hour. The same move in HDFS:

```
ana@lab:~/big$ time hdfs dfs -mv /raw/clicks-2025.csv /raw/clicks-2025-moved.csv

real	0m2.754s
user	0m5.333s
sys	0m0.322s
```

**One request to the namenode, whatever the size of the file**: the 2.8 seconds are almost all the
time Java takes to start. A rename in HDFS changes one entry in the namenode's memory, and it is
*atomic*: anyone looking sees the old name or the new one, never half of each.

**Spark reads an object store with the same code**, `s3a://bucket/key` in place of `hdfs://`, through
a connector Hadoop provides. That connector and the Amazon library under it come to over 600 MB of
jars, so this lab does not install them, and no Spark job in this course was run against an object
store. Everything this section showed about objects is true of what Spark would see through the
connector, and the next section is about the place where it hurts.
