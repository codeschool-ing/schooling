---
title: A licence for the code is not a licence for the weights
version: 1
---

A model's repository usually holds two different things: the **code** that loads and runs it, and
the **weights**, or instructions for getting them. They can be under different licences, and the
badge at the top of the page names only one.

DeepSeek-V3's README says it outright:

```
ana@desk:~/desk$ sources quote deepseek-v3-readme "^This code repository is licensed"
# deepseek-ai/DeepSeek-V3@9b4e9788 README.md
 345: This code repository is licensed under [the MIT License](LICENSE-CODE). The use of
      DeepSeek-V3 Base/Chat models is subject to [the Model License](LICENSE-MODEL).
      DeepSeek-V3 series (including Base and Chat) supports commercial use.
```

The code is MIT, which sets no conditions. The models are under a separate **Model License**, and
that one does set conditions. Its preamble says what kind:

```
ana@desk:~/desk$ sources quote deepseek-v3-licence "use-based restrictions not"
# deepseek-ai/DeepSeek-V3@9b4e9788 LICENSE-MODEL
  13: In short, this license strives for both the open and responsible downstream use of the
      accompanying model. When it comes to the open character, we took inspiration from open
      source permissive licenses regarding the grant of IP rights. Referring to the downstream
      responsible use, we added use-based restrictions not permitting the use of the model in
      very specific scenarios, in order for the licensor to be able to enforce the license in
      case potential misuses of the Model may occur. At the same time, we strive to promote
      open and responsible research on generative models for content generation.
```

So a team that reads "MIT" in the repository and stops there has read the wrong licence. The use-
based restrictions are in an attachment to the Model License, and the paragraph above says they
travel with every derivative.

## A model built from another model

The same thing happens one level down. DeepSeek also released smaller models trained to imitate
R1, and its README is careful about where each one came from:

```
ana@desk:~/desk$ sources quote deepseek-r1-readme "^- DeepSeek-R1-Distill"
# deepseek-ai/DeepSeek-R1@0cf78561 README.md
 259: - DeepSeek-R1-Distill-Qwen-1.5B, DeepSeek-R1-Distill-Qwen-7B, DeepSeek-R1-Distill-
      Qwen-14B and DeepSeek-R1-Distill-Qwen-32B are derived from [Qwen-2.5
      series](https://github.com/QwenLM/Qwen2.5), which are originally licensed under [Apache
      2.0 License](https://huggingface.co/Qwen/Qwen2.5-1.5B/blob/main/LICENSE), and now
      finetuned with 800k samples curated with DeepSeek-R1.
 260: - DeepSeek-R1-Distill-Llama-8B is derived from Llama3.1-8B-Base and is originally
      licensed under [Llama3.1 license](https://huggingface.co/meta-
      llama/Llama-3.1-8B/blob/main/LICENSE).
 261: - DeepSeek-R1-Distill-Llama-70B is derived from Llama3.3-70B-Instruct and is originally
      licensed under [Llama3.3 license](https://huggingface.co/meta-
      llama/Llama-3.3-70B-Instruct/blob/main/LICENSE).
```

R1 itself is MIT (section 02). **These are not**, or not only: each one started as somebody else's
model, and keeps that model's licence. The 8B distill is a Llama 3.1 underneath and carries the
Llama terms from section 03, including *Built with Llama* if you ship it. A fine-tune inherits the
same way, and that includes one ana might make from any base in lesson 1 section 07.

## And the repository you can read is often just the code

Mistral's `mistral-inference` is the code for running Mistral's models. Its licence file is the one
everybody recognises:

```
ana@desk:~/desk$ sources quote mistral-inference-licence "Apache License$|Version 2.0, January"
# mistralai/mistral-inference@9eaeb91c LICENSE
   1: Apache License
   2: Version 2.0, January 2004
```

That says what you may do with **the inference code**. Mistral releases its open models under
licences stated per model, on each model's own page, and its commercial models are not open at
all. The file above answers none of those questions.

**The rule that follows: find the licence of the weights you will actually run**, by name and
version, on the page those weights are published from. The repository badge, the company's
reputation for openness and a licence you read for the previous version are each a guess.
