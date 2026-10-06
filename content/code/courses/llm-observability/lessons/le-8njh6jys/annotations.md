---
title: Annotations
version: 1
---

Phoenix's word for a score is an **annotation**: a label, a number, or both, with an explanation, put
on a span by an annotator of one of three kinds, `HUMAN`, `LLM` or `CODE`. The three kinds are the
three kinds of evaluation this course builds next: a rule in code (lesson 8), a model judge (lesson 9)
and a person (lesson 10). Recording which kind produced a verdict is what lets a team later ask how
often the model judge and the people agreed.

The thumbs are a human's verdict. Phoenix annotates spans rather than traces, so `px_thumbs.py` puts
each thumb on its trace's root span, which it finds in `spans.jsonl` by trace id:

```python
"""px_thumbs.py: each thumb in feedback.jsonl, as an annotation on its trace's root span in Phoenix."""
import json

import pandas as pd
from phoenix.client import Client

root = {s["trace"]: s["span"] for s in map(json.loads, open("spans.jsonl")) if s["parent"] is None}
thumbs = [f for f in map(json.loads, open("feedback.jsonl")) if f["kind"] == "thumbs"]
rows = pd.DataFrame({"span_id": [root[f["trace"]] for f in thumbs], "label": [f["value"] for f in thumbs],
                     "score": [1 if f["value"] == "up" else 0 for f in thumbs]})
client = Client(base_url="http://127.0.0.1:6006")
client.spans.log_span_annotations_dataframe(dataframe=rows, annotation_name="thumbs", annotator_kind="HUMAN", sync=True)
got = client.spans.get_span_annotations_dataframe(span_ids=rows["span_id"], project_identifier="default")
print(len(rows), "sent;", len(got), "read back:", got["result.label"].value_counts().to_dict())
```

```
ana@lab:~/obs$ python px_thumbs.py
20 sent; 20 read back: {'up': 11, 'down': 9}
```

Twenty thumbs from Sunday, eleven up and nine down, now on the spans they judge. In Phoenix's screens
they appear beside each trace, and a filter can list the traces with a thumbs down.

The join was by id twice: the thumb carried the trace id, and `spans.jsonl` turned it into the root
span's id, both written by OpenTelemetry when the request ran and identical in Phoenix. The same thumbs
went to Langfuse in lesson 6 by the same route. That is the point of joining by id from the start:
**the feedback is not tied to any tool**, and moving it to a new one is a loop.
