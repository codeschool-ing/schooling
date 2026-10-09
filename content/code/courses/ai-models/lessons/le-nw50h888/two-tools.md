---
title: Two ways to run a model at home
version: 1
---

Lesson 3 worked out what it takes to run a model yourself: memory for the weights, a runtime, and
somebody to keep it going. Lessons 10 to 12 showed where open weights come from. Ollama and
LM Studio are the two tools most people use to put the two together on one machine. Ollama is the
one lesson 1 installed, and everything this lesson shows of it ran for real. LM Studio did not: its
site was refused by the network of the machine this course was recorded on, and it is a desktop
application. What this lesson shows of LM Studio is its documentation, read at a pinned commit.

## Ollama

Ollama is a server that runs in the background and a command, `ollama`, that talks to it. It
downloads models from its own library at ollama.com and names them like this:

```
# ollama/ollama@42e911bc docs/api.md
  24: Model names follow a `model:tag` format, where `model` can have an optional namespace
      such as `example/model`. Some examples are `orca-mini:3b-q8_0` and `llama3:70b`. The tag
      is optional and, if not provided, will default to `latest`. The tag is used to identify
      a specific version.
```

The tag carries the size and often the precision: `llama3:70b`, `orca-mini:3b-q8_0`. And **a name
with no tag means `latest`**, which is lesson 2 section 06's alias again: the same name, other
bytes, the day the library updates it. A program that should keep behaving the way it was
evaluated names the full tag.

Underneath, the arithmetic is done by llama.cpp, an open-source runtime built to run quantised
weights, lesson 3 section 04's fewer bits per weight, on ordinary CPUs and GPUs:

```
# ollama/ollama@42e911bc README.md
 141: ## Supported backends
 143: - [llama.cpp](https://github.com/ggml-org/llama.cpp) project founded by Georgi Gerganov.
```

## LM Studio

LM Studio is a desktop application: search Hugging Face, download a model, chat with it, and turn
on a server. It comes in two more forms, and its documentation says what they are for:

```
# lmstudio-ai/docs@9b8bc200 0_app/1_basics/lmstudio-vs-llmster-vs-lms.md
  28: llmster is LM Studio’s headless daemon – a standalone background service that can run
      without a GUI. This means you do not have to download the LM Studio app to use llmster
      via the terminal.
  68: Once the server is running, it listens on http://localhost:1234. Point any SDK or
      compatible tool at our OpenAI or Anthropic-compatible endpoints to use your LM Studio
      models.
```

`llmster` is the one for a machine with no screen, and `lms` is the command line for both. Its
models come straight from Hugging Face, in the GGUF format that llama.cpp reads or, on a Mac, in
Apple's MLX format.

| | Ollama | LM Studio |
|---|---|---|
| what it is | a server and a command | an app, a headless daemon (`llmster`) and a command (`lms`) |
| models from | its own library | Hugging Face |
| listens on | `localhost:11434` | `localhost:1234` |
| its own API | `/api/chat`, `/api/generate` | `/api/v1/chat` |
| OpenAI's shape | `/v1/chat/completions` | `/v1/chat/completions` |

Which one is a matter of taste for a person and of deployment for a program: Ollama on a server
is one install and a service, LM Studio on a desk is a window. The rest of this lesson uses
Ollama's own API first, because it reports more, and then OpenAI's shape, which both accept.
