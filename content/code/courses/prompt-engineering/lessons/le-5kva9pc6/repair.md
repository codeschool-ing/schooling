---
title: Repairing a reply, and knowing when to stop
version: 1
---

When a reply fails, the obvious move is to ask again and hope. **Most failures do not need a model
at all**, and the ones that do need a precise message and a limit on how many times it is sent.
Repair is a short sequence of cheap steps, each tried only when the one before it failed:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A flow. The reply is parsed as it is; if that fails, the text from the first brace to the last is cut out and parsed; if no object is found, the failure is recorded. A parsed object is checked against the schema. Valid: use it. Invalid: if attempts are left, the errors are sent back to the model and the new reply starts the flow again; if not, give up and record it.\"><defs><marker id=\"rep-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the reply</text><path d=\"M130 52 L168 52\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><rect x=\"170\" y=\"30\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1 · parse as it is</text><path d=\"M320 52 L358 52\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><rect x=\"360\" y=\"30\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2 · cut from first { to last }</text><path d=\"M460 74 L460 106\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><text x=\"582\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no object:</text><text x=\"582\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">record the failure</text><rect x=\"360\" y=\"108\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 · check against the schema</text><path d=\"M245 74 L245 130 L358 130\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><path d=\"M560 130 L618 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><rect x=\"620\" y=\"108\" width=\"80\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"660\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">use it</text><path d=\"M460 152 L460 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><text x=\"468\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">invalid</text><text x=\"589\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">valid</text><rect x=\"380\" y=\"190\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">attempts left?</text><path d=\"M380 210 L232 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><text x=\"306\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">yes</text><rect x=\"90\" y=\"190\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">send the errors back,</text><text x=\"160\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ask again</text><path d=\"M160 190 L160 160 L75 160 L75 76\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><path d=\"M540 210 L588 210 L588 248\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><text x=\"604\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><rect x=\"500\" y=\"250\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">give up and record it</text></svg>", "caption": "The repair loop. Steps 1 to 3 cost nothing and call no model; only an invalid object goes back, and only while attempts are left."}
```

`repair` on the workbench runs the first three steps and stops before calling anything: it either
prints a valid object or prints the message that would go back. What happens after that is the
calling program's decision, which is the right place for it.

## A reply wrapped in a fence and two sentences

This reply has a correct object in it, inside a Markdown code fence, with a sentence before and
after. `cat -n` numbers the lines so the wrapping is easy to see:

```
ana@lab:~/pe$ cat -n replies/fenced.txt
     1	Here is the triage for the complaint:
     2	
     3	```json
     4	{"category": "wrong_item", "refund": true, "refund_amount": 14, "summary": "Ordered an oat flat white, got cow's milk."}
     5	```
     6	
     7	Let me know if you need anything else!
ana@lab:~/pe$ repair schema.json replies/fenced.txt; echo "exit $?"
step 1: not JSON (Expecting value: line 1 column 1 (char 0))
step 2: parsed characters 47 to 166
step 3: valid against schema.json
{"category": "wrong_item", "refund": true, "refund_amount": 14, "summary": "Ordered an oat flat white, got cow's milk."}
exit 0
```

Step 1 fails exactly as lesson 18's parser did, on the first character. Step 2 takes the text from
the first `{` to the last `}`, characters 47 to 166 of the file, which leaves out the sentence, the
fence and the sign-off. That parses, and step 3 finds it valid. **No second request was made**, and
none was needed: the model gave the right answer in the wrong wrapping.

Step 2 is a heuristic, and it is honest about it. It works when the reply holds one object. A reply
that held two, or a sentence containing a `}` after the object, would cut out something that does
not parse, and `repair` would say `still not JSON` rather than guess further. When step 2 does
succeed, what it cut out goes through the same schema check as any other reply, so the heuristic
never lets an unchecked object through.

## A reply that parses and is wrong

```
ana@lab:~/pe$ cat replies/wrong-enum.txt
{"category": "drinks", "refund": true, "refund_amount": 14, "summary": "Ordered an oat flat white, got cow's milk."}
ana@lab:~/pe$ repair schema.json replies/wrong-enum.txt; echo "exit $?"
step 1: parsed as it is
step 3: 1 problem; the follow-up message would be:

Your last reply did not match the schema:
- category: 'drinks' is not one of ['wrong_item', 'cold_or_late', 'allergen', 'billing', 'other']
Reply again with only the corrected JSON object.
exit 1
```

Nothing to cut out this time: the object parsed as it was. It fails the schema on one field, and
`repair` prints the follow-up message instead of an object. **The message carries the validator's
own words, with the path**, so the model is told which field and why. "That was wrong, try again"
gives it nothing to go on; this names `category` and lists the five allowed values.

The program sends that message as the next turn of the same conversation, with the bad reply still
in it, and checks the new reply with the same steps.

## Retry limits

The loop in the figure has one exit that is easy to forget: **attempts left?** A program that
retries until the reply is valid will one day meet a reply that is never valid. A complaint that
truly fits none of the five categories, a schema with a mistake in it, a model that is having an
outage. Without a limit, that request runs forever and is charged for every attempt.

So the number of attempts is written down, and it is small. The sketch below allows three in all,
the first reply and two retries, on the reasoning that a model which got it wrong twice with the
errors in front of it is unlikely to get it right on the fourth. When the attempts run out, the program **records the
failure and moves on**: the complaint goes to a person's queue unsorted, with the last reply and
the errors attached. That is a slower path for one complaint, not a silent hole in the data.

This is a sketch of the loop in Python, written for the lesson and not run, since the workbench has
no model to call:

```python
MAX_ATTEMPTS = 3

def triage(complaint):
    messages = [prompt_for(complaint)]
    for attempt in range(MAX_ATTEMPTS):
        reply = call_model(messages)
        result = repair(SCHEMA, reply)
        if result.valid:
            return result.data
        messages += [reply, result.follow_up]
    record_failure(complaint, reply, result.errors)
    return None
```

`range(MAX_ATTEMPTS)` is what makes it end. The function returns `None` after recording the failure,
and the caller has to handle that, which is the point: the failure is visible in the code that
uses the result.

## When the provider checks the shape for you

At the time of writing (2026), several model providers offer a **structured output** mode: you
pass a JSON Schema with the request, and the model's choice of each next token is restricted to
tokens that keep the output valid against that schema. This is called **constrained decoding**.
The model can no longer write `Sure!` first, because no valid object starts with `S`.

It changes how often each step of the loop is needed, and it does not remove the loop. The exact
parameter names differ between providers and change between versions, so take them from the
provider's documentation, and check which parts of JSON Schema it supports: some modes accept only
a subset. And **a reply that fits the schema can still be wrong**. Constrained decoding makes the
category one of five words; it does not make it the right one of the five.
