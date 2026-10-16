---
title: x
version: 1
---

```python
# thumbs.py
from urllib.parse import unquote_plus


def handler(event, context):
    done = []
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        print(f'would resize s3://{bucket}/{key}')
        done.append(key)
    return {'resized': done}
```
