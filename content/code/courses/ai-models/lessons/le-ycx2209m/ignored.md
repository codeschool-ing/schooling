---
title: Accepted is not obeyed
version: 1
---

Anthropic's documentation of its compatible endpoint is unusually frank about what the shape
promises, and it is worth reading as a description of every compatible API, not only this one:

```
ana@desk:~/desk$ sources quote claude-openai-compat "silently ignored|not considered a long-term"
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-05
  62: This compatibility layer is primarily intended to test and compare model capabilities,
      and is not considered a long-term or production-ready solution for most use cases. While
      it is intended to remain fully functional and not have breaking changes, the priority is
      the reliability and effectiveness of the
 184: Most unsupported fields are silently ignored rather than producing errors. These are all
      documented in the following sections.
```

**Silently ignored.** The request is accepted, the answer comes back, and a field that would have
changed the answer elsewhere changed nothing. The documentation then lists the fields one by one.
Two of them matter to the work this course has done:

```
ana@desk:~/desk$ sources lines claude-openai-compat 283 284
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-05
 283| response_format
 284| Ignored. For JSON output, use
```

```
ana@desk:~/desk$ sources lines claude-openai-compat 293 294
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-05
 293| seed
 294| Ignored
```

`response_format` is how Chat Completions asks for JSON, the counterpart of lesson 16's
`text.format`. Sent here, it is dropped,
and the model writes whatever its prompt leads it to; a parser downstream finds out. `seed` is a
request for repeatable sampling, the property lesson 5 section 08 measured, and here it does
nothing. Two
more change values rather than dropping them, or take a feature away:

```
ana@desk:~/desk$ sources quote claude-openai-compat "Values greater than 1|Prompt caching is not supported"
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-05
 181: Prompt caching is not supported, but it is supported in the
 276: Between 0 and 1 (inclusive). Values greater than 1 are capped at 1.
```

A `temperature` of 1.5 tuned against OpenAI arrives as 1.0. Lesson 17's caching is not there at
all through this endpoint. And lesson 14 found the same shape of gap at Ollama, from the other
direction: a setting its own API has and OpenAI's shape has no room for:

```
ana@desk:~/desk$ sources quote ollama-openai "does not have a way of setting the context size"
# ollama/ollama@42e911bc docs/api/openai-compatibility.mdx
 386: The OpenAI API does not have a way of setting the context size for a model. If you need
      to change the context size, create a `Modelfile` which looks like:
```

So the rule for a program that talks to several providers through one shape:

- **The shape carries the common part.** Messages, the model's name, a limit, a temperature in the
  range everybody accepts, the text that comes back.
- **Everything else is per provider**, and is read in that provider's documentation: structured
  output, caching, seeds, context windows, rate-limit headers, how an error is worded.
- **The evaluation is per provider too**, run through the path the program will actually use.
  Lesson 5's numbers for a model through its own API say nothing certain about the same model
  through a compatible endpoint that ignores half the request.

The shape is the cheapest way to *compare* providers, which is what Anthropic says its endpoint is
for. Whether to *stay* on it is the trade lesson 16 put to OpenAI's own newer API: reach against
features, decided with the features you actually use written down.
