---
title: Pydantic models: a class whose annotations are the rules
version: 1
---

Lesson 6 described the shape of an event with a serializer. FastAPI's equivalent is a **Pydantic
model**: a class whose type annotations say what each field is, checked whenever an instance is
built. Save the API's shapes as `app/schemas.py`:

```schooling-example
{"language": "python", "file": "app/schemas.py", "parts": [{"code": "# app/schemas.py\nfrom datetime import datetime\n\nfrom pydantic import BaseModel, EmailStr, Field\n\n\n", "note": "**A Pydantic model is a class whose annotations are the rules.** `Field` adds what a type cannot say: a pattern, a length, a range."}, {"code": "class EventIn(BaseModel):\n    slug: str = Field(pattern=r\"^[a-z0-9-]+$\", max_length=50)\n    title: str = Field(min_length=1, max_length=200)\n    starts_at: datetime\n    venue: str = Field(min_length=1, max_length=200)\n    capacity: int = Field(ge=1, le=1000)\n    description: str = \"\"\n\n\n", "note": "`EventIn` is what a client sends to create an event. The slug's pattern is the same set of characters Django's `SlugField` allows, lower case only."}, {"code": "class EventOut(EventIn):\n    taken: int\n\n\n", "note": "**`EventOut` inherits every field and adds `taken`**, which the server computes and a client never sends."}, {"code": "class RegistrationIn(BaseModel):\n    name: str = Field(min_length=1, max_length=100)\n    email: EmailStr\n\n\n", "note": "`EmailStr` validates an address properly, which is why the project installed `pydantic[email]`."}, {"code": "class RegistrationOut(RegistrationIn):\n    created_at: datetime\n\n\n", "note": "What the person who registered gets back: their own data, and the time."}, {"code": "class RegistrationPublic(BaseModel):\n    name: str\n    created_at: datetime\n", "note": "**What everybody else may see: a name and a time, no address.** The next sections use it."}]}
```

## Building one from untrusted data

This script, saved as `validate.py` in `~/agenda-api`, builds one event from strings as JSON would
deliver them, and one registration that is wrong twice:

```python
# validate.py
from pydantic import ValidationError

from app.schemas import EventIn, RegistrationIn

event = EventIn(
    slug="pycon-watch",
    title="PyCon talks, watched together",
    starts_at="2026-12-03T19:00:00-03:00",
    venue="Public Library, lab 2",
    capacity="15",
)
print(repr(event.starts_at), repr(event.capacity))

try:
    RegistrationIn(name="", email="not-an-address")
except ValidationError as error:
    print(error.error_count(), "errors")
    for e in error.errors():
        print(e["loc"], e["type"], "-", e["msg"])
```

```
ana@vm:~/agenda-api$ uv run python validate.py
datetime.datetime(2026, 12, 3, 19, 0, tzinfo=TzInfo(-10800)) 15
2 errors
('name',) string_too_short - String should have at least 1 character
('email',) value_error - value is not a valid email address: An email address must have an @-sign.
```

**`"15"` became the integer 15**, and the date string became a `datetime` with its offset. Pydantic
**converts** a value when the conversion is unambiguous, which is called *lax* mode and is its
default; a model declared with `strict=True` refuses the string instead. The registration failed on
**both** fields, and both errors are in one `ValidationError`, each with the field's name, a type
code a program can test and a message a person can read.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Four JSON values on the left each pass through the rule their field declares: a slug matched against a pattern, a date parsed, the string 15 converted to the integer 15, and an email address with no at sign, which fails. When every field passes the result is a model with typed values; when any fails, every error is listed and FastAPI answers 422.\"> <defs><marker id=\"pd-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"pd-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"110\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">what arrived</text> <rect x=\"20\" y=\"34\" width=\"180\" height=\"132\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"30\" y=\"58\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"slug\": \"pycon-watch\"</text> <text x=\"30\" y=\"88\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"starts_at\": \"2026-12-…\"</text> <text x=\"30\" y=\"118\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"capacity\": \"15\"</text> <text x=\"30\" y=\"148\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"email\": \"not-an-address\"</text> <text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the field's type and rules</text> <rect x=\"240\" y=\"42\" width=\"240\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"58\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">str, pattern ^[a-z0-9-]+$</text> <path d=\"M200 54 L234 54\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pd-a)\"></path> <rect x=\"240\" y=\"72\" width=\"240\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">datetime: parsed</text> <path d=\"M200 84 L234 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pd-a)\"></path> <rect x=\"240\" y=\"102\" width=\"240\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"118\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">int, ge=1: \"15\" becomes 15</text> <path d=\"M200 114 L234 114\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pd-a)\"></path> <rect x=\"240\" y=\"132\" width=\"240\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.15\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"148\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">EmailStr: no @-sign</text> <path d=\"M200 144 L234 144\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pd-b)\"></path> <rect x=\"520\" y=\"34\" width=\"180\" height=\"54\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"610\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">all pass: a model,</text> <text x=\"610\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">typed values inside</text> <rect x=\"520\" y=\"112\" width=\"180\" height=\"54\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.15\" stroke=\"var(--amber)\"></rect> <text x=\"610\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">any fail: every error</text> <text x=\"610\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">listed, then 422</text> <path d=\"M480 61 L514 61\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pd-a)\"></path> <path d=\"M480 139 L514 139\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pd-b)\"></path> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">The function never runs with data that failed; its arguments are already the right types.</text> </svg>", "caption": "Validation is per field and complete: one request with two mistakes gets both back at once."}
```

When a conversion is not unambiguous, it fails, and the exception's own text says how:

```
ana@vm:~/agenda-api$ uv run python -c "from app.schemas import EventIn; EventIn(slug=\"x\", title=\"x\", starts_at=\"tomorrow\", venue=\"x\", capacity=\"fifteen\")" 2>&1 | tail -7
pydantic_core._pydantic_core.ValidationError: 2 validation errors for EventIn
starts_at
  Input should be a valid datetime or date, input is too short [type=datetime_from_date_parsing, input_value='tomorrow', input_type=str]
    For further information visit https://errors.pydantic.dev/2.14/v/datetime_from_date_parsing
capacity
  Input should be a valid integer, unable to parse string as an integer [type=int_parsing, input_value='fifteen', input_type=str]
    For further information visit https://errors.pydantic.dev/2.14/v/int_parsing
```

## The same job as a serializer, said differently

| | DRF serializer | Pydantic model |
|---|---|---|
| declared with | field objects: `serializers.IntegerField(min_value=1)` | type hints: `capacity: int = Field(ge=1)` |
| knows about the database | `ModelSerializer` reads the model | nothing; it is plain Python |
| error codes | a message per field | a message and a machine-readable `type` per field |
| used outside the web | possible, rarely done | everywhere: settings in lesson 15, any data that crosses a boundary |

The last row matters. Pydantic is not part of FastAPI, it is a library FastAPI uses, and the same
models validate a configuration file, a message from a queue or a row from a CSV file.
