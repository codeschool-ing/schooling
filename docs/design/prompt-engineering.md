---
format: 5
course: prompt-engineering
---

# prompt-engineering

**Prompt Engineering** · `co-9gbjdww5` · 60 h declared · beginner · 31 lessons · `ai` · paid

## Reach

In **3 tracks** — `ai`(4), `prompt`(2), `security`(15).

**Depends on it:** `ai-models`, `ai-security`, `prompt-reliability`

## Assumes, and leaves ready

**Assumes:** **nothing.** No `requires`, beginner, and it is position 2 of `prompt` and 4 of `ai`. It assumes somebody who has used a chat interface and never thought about why it answered that way.

**Leaves ready:** the vocabulary three courses require by name — `ai-models`, `ai-security` and `prompt-reliability`. **The entry point of the whole category**, and the only course in it that takes no prerequisite.

## Shape

| | |
|---|---|
| declared hours | 60 h |
| lessons | 31 |
| **hours per lesson** | **1.94** |
| section budget | ~129, about 4.2 a lesson |
| exercises | ~610, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **an API key with a bill attached** — a metered third party, not a machine |
| browser · database | no · no |
| exercises **blocked** | **~400 (65%)** — a prompt is judged by what came back |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~55 — tokenisation shown on a real sentence, a context window filling up, temperature as a distribution flattening, chain of thought against tree of thoughts |

## Ageing

**Low for the mechanics, severe for lesson 12.** Tokens, temperature, few-shot and chain of thought are stable ideas. *"Models by provider: OpenAI, Google, Anthropic, Meta and xAI"* is a list that will be wrong within a year, and it is one lesson.

## Flags

**1 ·** **Thirty-one lessons in sixty hours — 1.94 hours each, third-lowest in the catalogue** after `kubernetes` (1.67) and `docker` (1.79). The budget puts it at 4.2 sections a lesson, on the floor, and that is right rather than thin: *"Stop sequences"* is one lesson and does not want six sections. **The section design should accept the floor here instead of padding to a category average.**

**2 ·** **The exercises need a model to answer them, and that is a new kind of environment.** Not a runtime, not a GPU, not a cluster — a **metered third-party API**. It is cheap per call and impossible to avoid: prompt engineering cannot be taught without something to prompt. It is also non-deterministic, so `expected-output` would not grade it even if that grader existed.

**3 ·** **Roughly a third of it grades today with what exists.** Which sampling parameter makes output more deterministic, what a token is, what temperature 0 does, which of these four prompts leaks the system instruction — `quiz`, `multiple-choice` and `numeric` on the mechanics. The **craft** half does not, and no grader in any plan reads a prompt and says whether it is good.
