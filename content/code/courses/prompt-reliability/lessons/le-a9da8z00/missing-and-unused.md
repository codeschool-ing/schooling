---
title: Missing and unused values
version: 2
---

The harness is loud about a value in two situations, and both deserve it. The first you have seen:
a hole with no value stops the render. The second is the opposite, a value with no hole:

```
ana@lab:~/triage$ pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio --var language=English --var tone=warm > /dev/null
pl: warning: {{tone}} is not in the template
```

The `> /dev/null` throws the rendered prompt away so that only the warning is left. Somebody passed
`tone=warm`, and the template has no `{{tone}}`. The prompt rendered correctly, and that is
exactly the problem.

## A missing value

**Many template engines do not refuse a missing value.** They fill the hole with something and carry
on, and what they fill it with depends on the engine. Jinja2, by default, renders an undefined
variable as an empty string. Mustache renders a missing key as an empty string too. Python's
`string.Template`, with `safe_substitute`, leaves the placeholder in the text exactly as written.

So the reply prompt with no language becomes either *"Write in ."* or the same sentence with its
placeholder still in it, and the model gets a sentence that is broken in a way it has to guess
around. Neither shows up as an error. The reply comes back in some language, perhaps the right one,
and the defect stays in place until a customer in another country receives English. **A missing
value has to stop the run**, because nothing downstream of the render can tell an empty hole from a
short sentence.

## An unused value

An unused value looks harmless, since the prompt is correct without it. What it shows is a person
who believes they are setting something they are not. Somebody wanted warmer replies, passed
`tone=warm`, read a few replies, decided they sounded a little warmer, and moved on. **The value
never reached the model**, and the replies that sounded warmer are the ones they read hoping they
would.

It also happens the other way round: a template is edited, `{{tone}}` is renamed to `{{register}}`,
and every script that still passes `tone` is now passing nothing. A warning on an unused value is
the only symptom that rename will ever produce.

## When the harness says it

`render()` in `pl.py` warns every time it fills a template, and `pl run` fills it once per case, so
a run repeats the warning for every message:

```
ana@lab:~/triage$ pl run prompts/reply.txt cases/three.jsonl --out runs/reply-warm.jsonl --var shop=Folio --var language=English --var tone=warm
pl: warning: {{tone}} is not in the template
pl: warning: {{tone}} is not in the template
pl: warning: {{tone}} is not in the template
3 calls, prompt 13304d8d, llama3.2:3b, written to runs/reply-warm.jsonl
```

Three warnings for three messages, and then the run goes ahead, because a warning is not a
refusal. On a run of forty they scroll past in a block, which is easy to stop reading. **Render one
case before you run a template you have just changed**, and read what comes out; it costs no call
and it shows the warning once, on its own.
