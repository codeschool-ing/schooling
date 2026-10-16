---
title: A model behind an address
version: 1
---

A file on disk is useful to programs written in Python, on this machine, by somebody who knows to
import `churn_model`. The retention team's system is none of those. What it can do is send a request to
an address and read the answer, and that is what an **API** is here: a small program that listens on a
port, takes a subscriber described in **JSON**, and answers with a chance.

**FastAPI** builds that program from ordinary Python functions, and **Uvicorn** is the server that runs
it, both already installed by lesson 1's `requirements.txt`. The whole service is one file. Save this as
`app.py`:

```schooling-example
{
  "language": "python",
  "file": "app.py",
  "parts": [
    {
      "code": "# app.py\nimport json\nimport time\nfrom typing import Literal\n\nimport pandas as pd\nfrom fastapi import FastAPI\nfrom pydantic import BaseModel, Field\n\nimport stored\nfrom feira import CREDIT, KEPT, SAVED\n\nMODEL, CARD = stored.load(\"churn-2025-12\")\nCUT = CREDIT / (SAVED * KEPT)\napp = FastAPI(title=\"Feira em Casa churn\")\n",
      "note": "The model is loaded **once, when the server starts**, through `stored.load`, so a server on the wrong versions refuses to start rather than answering."
    },
    {
      "code": "\nclass Subscriber(BaseModel):\n    customer_id: str\n    city: str\n    age: int = Field(ge=18, le=99)\n    app_user: Literal[0, 1]\n    payment: str\n    plan: str\n    box: str\n    channel: str\n    tenure_months: int = Field(ge=0)\n    price_month: float = Field(gt=0)\n    orders_90d: int = Field(ge=0)\n    skips_90d: int = Field(ge=0)\n    late_90d: int = Field(ge=0)\n    complaints_90d: int = Field(ge=0)\n    support_calls_90d: int = Field(ge=0)",
      "note": "**The request, described as a class.** Every column the pipeline reads, with its type and the range it may take. FastAPI checks each request against it before any of your code runs, and refuses what does not fit."
    },
    {
      "code": "    rating_90d: float | None = Field(ge=1, le=5)\n    days_since_login: float | None = Field(ge=0)\n",
      "note": "**`float | None` with no default** means the field must be sent, and may be `null`. A subscriber with no rating is a fact the model knows how to read; a request that forgot the field is a mistake, and the two must not look alike."
    },
    {
      "code": "\n@app.get(\"/health\")\ndef health():\n    return {\"model\": CARD[\"name\"], \"trained_to\": CARD[\"to\"], \"cut\": round(CUT, 4)}\n",
      "note": "**A health check** answers which model is loaded, which is the first question anyone asks of a server that is behaving oddly."
    },
    {
      "code": "\n@app.post(\"/score\")\ndef score(subscriber: Subscriber):\n    rows = pd.DataFrame([subscriber.model_dump()])\n    chance = float(MODEL.predict_proba(rows)[0, 1])",
      "note": "**One subscriber in, one answer out.** `model_dump` turns the checked request back into a dictionary, and the dictionary becomes a table of one row, the shape the pipeline was fitted on."
    },
    {
      "code": "    answer = {\"customer_id\": subscriber.customer_id, \"chance\": round(chance, 4),\n              \"credit\": chance >= CUT, \"model\": CARD[\"name\"]}\n    with open(\"scores.jsonl\", \"a\") as log:\n        log.write(json.dumps({\"at\": time.strftime(\"%Y-%m-%dT%H:%M:%S\"), **answer}) + \"\\n\")\n    return answer",
      "note": "The answer carries the **decision and the model's name** as well as the chance, and every answer is written to `scores.jsonl`, one line each. Lesson 22 is about why that file matters."
    }
  ]
}
```

Most of the file is the description of a subscriber, and that is the right proportion. **The model
trusts its input completely**: given an age of −3 or a rating of 40 it returns a chance without a
murmur, because lesson 15's pipeline only knows how to transform numbers, not how to doubt them. A
spreadsheet that types a rating as `"4,2"`, a client that sends ages in months, a field renamed in
somebody else's release: each of these becomes a confident, wrong chance unless something at the door
checks. `Subscriber` is that check, and it costs nothing at the moment a request arrives.

Three choices in it are worth stating:

- **The words are plain `str`**, not a list of the values the model knows. A list would refuse the
  monthly plan, which arrived in February 2026 and which the pipeline handles: lesson 15's
  `handle_unknown="ignore"` gives it zeros. The cost is that a typo in a plan name is accepted too, and
  scored as an unknown plan. The next section sends one.
- **The ranges are the ones a person would defend**: 18 to 99 for age, 1 to 5 for a rating, nothing
  negative where a count is meant.
- **The decision travels with the chance.** The caller is told whether to send the credit, from the
  same `CUT` every lesson has used, so the break-even arithmetic lives in one place and not in every
  system that asks.
