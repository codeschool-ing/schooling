---
title: The lab this course runs on
version: 1
---

Every command in this course was run, and every line of output is what the command printed. The
machine it ran on is a lab, built by `lab.sh` beside the course's files: one Linux computer, one
developer called ana, and her project.

```
ana@dev:~/shop$ python --version
Python 3.11.15
ana@dev:~/shop$ git log --oneline
b88cbb3 README
c2b5d79 Coupons
fe437dd A cart with lines, a discount and shipping
33fefcf Prices are integer cents
ana@dev:~/shop$ python -m pytest -q
........                                                                 [100%]
8 passed in 0.57s
```

**`~/shop` is the cart, the prices and the coupons of a small online shop**, with its tests, in
git. Money is integer cents everywhere. The lessons add to it: an assistant's suggestions in
lessons 3 to 5, a support handbook to search in lesson 6, tools for a model to call in lessons 7
and 8.

## What is real, and what was written for the course

A course about calling models has a problem a networking course does not. **No model API was
reachable from the machine this course was recorded on**, and even if one had been, an API key is
a bill attached to somebody's card. So the lab has a stand-in provider, and it is important to know
exactly where the line between the real and the stand-in falls.

| | what it is |
|---|---|
| real | the providers' own Python SDKs (`anthropic`, `openai`, `google-genai`), the MCP SDK, `tiktoken` with OpenAI's real encodings, the WordLlama embedding model, numpy, pytest and hypothesis |
| the lab's | **labllm**, a server on `127.0.0.1:8400` that speaks the wire format of the Anthropic, OpenAI and Gemini APIs closely enough that the three SDKs talk to it unmodified |
| the lab's | **`tiny-1`**, one of labllm's two models: `tinylm`, the token-counting model of lesson 1 section 02. Its text is real output of a real, very small model |
| the lab's | **`scripted-1`**, the other: replies **written by the course**, chosen by simple rules. It exists so that the code around a model (tool loops, validation, retrieval, streaming) can run for real |

**Every lesson that shows a reply from `scripted-1` says it was written by the course.** Nothing in
this course presents the stand-in's text as something a language model said. What the course does
claim is that the code around those replies is exactly the code you would write against a real
provider: the same SDK calls, the same request bodies, the same parsing of the same response
shapes.

The versions, pinned in `lab.sh`:

```
ana@dev:~/shop$ pip list 2>/dev/null | grep -iE "^(anthropic|openai|google-genai|mcp|tiktoken|wordllama|numpy|pytest|hypothesis) "
anthropic                 1.11.0
google-genai              2.27.0
hypothesis                6.168.3
mcp                       2.2.0
numpy                     2.4.6
openai                    3.23.0
pytest                    9.1.1
tiktoken                  0.14.0
wordllama                 0.4.0.post1
```

## How the SDKs find labllm

Each SDK reads its key and, for two of them, its base URL from the environment. Pointing them
at the lab is three pairs of variables, and the keys are the lab's own, which open nothing
anywhere else:

```
ana@dev:~/shop$ env | grep -E "_(BASE_URL|API_KEY)=" | sort
ANTHROPIC_API_KEY=lab-anthropic-key-0001
ANTHROPIC_BASE_URL=http://127.0.0.1:8400
GEMINI_API_KEY=lab-google-key-0001
GEMINI_BASE_URL=http://127.0.0.1:8400
OPENAI_API_KEY=lab-openai-key-0001
OPENAI_BASE_URL=http://127.0.0.1:8400/v1
```

**To run this course's code against a real provider, you change these variables and nothing
else**, apart from the model name. `GEMINI_BASE_URL` is the lab's invention: the Gemini SDK takes
its address in code rather than from the environment, and lesson 10 shows the one line.

A request by hand, with `curl`, shows labllm answering in Anthropic's format:

```
ana@dev:~/shop$ curl -s http://127.0.0.1:8400/v1/messages -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H "content-type: application/json" -d "{\"model\": \"tiny-1\", \"max_tokens\": 12, \"messages\": [{\"role\": \"user\", \"content\": \"Return the\"}]}" | python -m json.tool
{
    "id": "msg_lab_0004",
    "type": "message",
    "role": "assistant",
    "model": "tiny-1",
    "content": [
        {
            "type": "text",
            "text": " number of data.\nmode                Mode (most common values of"
        }
    ],
    "stop_reason": "max_tokens",
    "stop_sequence": null,
    "usage": {
        "input_tokens": 5,
        "output_tokens": 12,
        "cache_creation_input_tokens": 0,
        "cache_read_input_tokens": 0
    }
}
```

`stop_reason` and `usage` are the two fields this course reads most; lesson 2 starts with them.

## What labllm decides for itself

Where a real provider has a rule, labllm has one too, and its rules are its own. The lessons name
them wherever they matter, and they are all here in one place:

- it counts tokens with `o200k_base`, plus 3 for each message;
- `tiny-1` has a context window of 2,048 tokens and `scripted-1` one of 32,768, small on purpose,
  so that lesson 2 can reach them;
- it takes 40 milliseconds to "generate" each token, so that lesson 9 has something to measure;
- it allows 50 requests a minute per key, lowered in lesson 10 to show what happens past it.

The corpus `tinylm` counted is the docstrings of fifty modules of the standard library:

```
ana@dev:~/shop$ python -c 'import tiktoken; t = open("/opt/aidev/share/corpus.txt").read(); print(len(t.split()), "words,", len(tiktoken.get_encoding("o200k_base").encode(t)), "tokens")'
51699 words, 78351 tokens
ana@dev:~/shop$ python -c 'import tiktoken; print(tiktoken.get_encoding("o200k_base").n_vocab, "tokens in o200k_base")'
200019 tokens in o200k_base
```

Large models are trained on many trillions of tokens. This one saw under eighty thousand, and
lesson 1 has shown what that buys.
