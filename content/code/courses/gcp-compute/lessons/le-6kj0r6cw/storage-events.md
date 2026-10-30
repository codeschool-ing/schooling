---
title: An object lands, a function runs
version: 1
---

Cloud Storage has announced its changes in two ways for years, and both are still in use. **The
older one writes a notification to a Pub/Sub topic you choose; the newer one is the Eventarc
trigger of section 02**, which delivers a `google.cloud.storage.object.v1.finalized` event with the
object's metadata as its data. The metadata is the same JSON in both. Only the envelope differs.

The first is the one a laptop can run, because fake-gcs-server, the open-source imitation of Cloud
Storage you pulled in lesson 1, can publish notifications in Cloud Storage's own format to the
Pub/Sub emulator. **fake-gcs-server is not Google's**, and it imitates the storage API rather than
running it; what it publishes follows the format Google documents for Pub/Sub notifications, which
is what this section reads.

## The two emulators

The Pub/Sub emulator first, exactly as in lesson 17, with the variable set and the topic the
bucket will write to:

```
ana@laptop:~/gcp$ docker run -d --name pubsub --network host gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators gcloud beta emulators pubsub start --host-port=0.0.0.0:8085 --project=planner-dev
b44651b57aa618e675b7a02c7336ee35894972d9e5af206650b8595ae9a7579e
ana@laptop:~/gcp$ export PUBSUB_EMULATOR_HOST=localhost:8085
ana@laptop:~/gcp$ python3 pubsub.py topic photo-uploads
projects/planner-dev/topics/photo-uploads
```

Then fake-gcs-server, on the same network, told where the Pub/Sub emulator is and which topic to
publish to. `-event.list` names the changes worth announcing:

```
ana@laptop:~/gcp$ docker run -d --name gcs --network host -e PUBSUB_EMULATOR_HOST=localhost:8085 fsouza/fake-gcs-server:1.56.1 -scheme http -port 4443 -backend memory -event.pubsub-project-id planner-dev -event.pubsub-topic photo-uploads -event.list finalize,delete
2b863ead44c23640e7de1b16a9ea4378cbc9450f757c0f86b9f39ff36932451d
```

## The function

The notification puts the object's metadata, as JSON, in the message's data, and a summary in its
attributes. **Create `~/gcp/thumbnails` and save this as `main.py` in it:**

```python
# thumbnails/main.py
import base64
import json

import functions_framework


@functions_framework.cloud_event
def on_upload(event):
    message = event.data['message']
    attrs = message['attributes']
    obj = json.loads(base64.b64decode(message['data']))
    print(f"{attrs['eventType']} gs://{attrs['bucketId']}/{attrs['objectId']}"
          f" {obj['size']} bytes {obj['contentType']}", flush=True)
```

It makes no thumbnail: what matters here is what it is told. Start it in the second terminal, and
point a push subscription at it from the first, with `pubsub.py` from lesson 17:

```
ana@laptop:~/gcp/thumbnails$ functions-framework --target on_upload --signature-type cloudevent
```

```
ana@laptop:~/gcp$ python3 pubsub.py push thumbnails photo-uploads http://localhost:8080/
projects/planner-dev/subscriptions/thumbnails -> http://localhost:8080/
```

## The upload

Without an account neither `gcloud storage` nor anything else of Google's will talk to the
imitation, so **curl does the uploading**, speaking the Cloud Storage JSON API to fake-gcs-server:
first the bucket, then a photo, then its removal:

```
ana@laptop:~/gcp$ curl -s -X POST 'localhost:4443/storage/v1/b?project=planner-dev' -H 'content-type: application/json' -d '{"name": "shop-photos"}' | jq -r .name
shop-photos
ana@laptop:~/gcp$ head -c 48213 /dev/urandom > 1042.jpg
ana@laptop:~/gcp$ curl -s -X POST --data-binary @1042.jpg -H 'content-type: image/jpeg' 'localhost:4443/upload/storage/v1/b/shop-photos/o?uploadType=media&name=products/1042.jpg' | jq -r '.name, .size'
products/1042.jpg
48213
ana@laptop:~/gcp$ curl -s -o /dev/null -w '%{http_code}\n' -X DELETE localhost:4443/storage/v1/b/shop-photos/o/products%2F1042.jpg
200
```

And in the function's terminal:

```
OBJECT_FINALIZE gs://shop-photos/products/1042.jpg 48213 bytes image/jpeg
OBJECT_DELETE gs://shop-photos/products/1042.jpg 0 bytes image/jpeg
```

**Two events, one for each change**, each naming the bucket and the object in its attributes, so a
function that only needs to know what changed never has to decode the data. The data carries the
rest: size, content type, checksums and the object's generation, which is the number that tells
two versions of `products/1042.jpg` apart. One detail belongs to the imitation: it reports a
deleted object's size as 0, so read nothing into the size of a deletion here.

Stop both emulators when you are done:

```sh
docker rm -f gcs pubsub
```

## What changes on Google Cloud

With the Eventarc trigger of section 02, the event arrives as `google.cloud.storage.object.v1.finalized`
with the object's JSON as the CloudEvent's data, and the bucket as its `subject`; there is no
`message` to unwrap. With a Pub/Sub notification instead, your code reads exactly what it read
here. **The work in both is the same and the parsing differs**, which is a reason to keep the
parsing in one small function and the work in another.
