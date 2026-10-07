---
title: What a framework adds, and what it hides
version: 1
---

Four programs in this lesson, two frameworks, and one cover sent three times. What each side of the trade looked like, in this lab:

| a framework gave | a framework hid |
|---|---|
| one message type for several providers (LangChain's standard block) | the request that went out, until a private method printed it |
| `ImageBlock(path=...)`, base64 done for you | a default address of `api.openai.com`, ignoring the variable the SDK reads |
| a chain, `RunnableLambda` and the pipe operator, for transcribe then extract | a table of model names that refused a new one |
| structured output into a Pydantic class | nothing about whether the values were heard |
| a vector store and documents with metadata | nothing about which language the embedding model reads |

None of the right-hand column is a reason not to use a framework. It is a list of things to check **because** you use one. Three habits cover most of it:

- **Count the tokens of one image with and without the framework.** Here it was 765 every time. A framework that resized, re-encoded or sent `detail: high` by default would show up as a different number, and on a bill.
- **Pin the versions**, as lesson 1's `setup.sh` does. Content blocks are recent in both packages and still moving; `langchain-core` 1.x changed how they are spelt, and a minor release of an integration can change what is sent.
- **Keep the provider's SDK within reach.** The chain above already uses it for transcription, because that is where the endpoint is. A step a framework does not cover is a function, not a reason to wait.

When is a framework the wrong tool? When the program makes one call. A cover description, a transcript, a generated image: the SDK call is three lines, and lessons 8 to 10 showed them. The framework starts paying for itself when there are **several providers, several steps, or retrieval**: the shapes of this lesson's last two programs.
