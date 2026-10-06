---
title: The parts of an image prompt
version: 1
---

A text prompt for a language model is an instruction. An image prompt is closer to a **description of a picture that already exists**, because that is what the model learned from: pictures and the captions people wrote for them. "Make me a banner that sells books" is an instruction, and there is no picture in the training data captioned like that. "A stack of second-hand books on a café table, watercolour illustration" describes something a caption could say.

It helps to write the description in named parts, because each part controls something different and can be changed on its own:

| part | what it controls | Marginalia's banner |
|---|---|---|
| **subject** | what is in the picture | a stack of second-hand books on a café table |
| **medium** | what it seems to be made with | watercolour illustration |
| **style** | the handling within the medium | loose brushwork, soft edges |
| **composition** | framing, where things are, empty space | wide banner, books on the left third, empty space on the right |
| **light** | time of day, direction, mood | late afternoon sun from the left |
| **palette** | the colours | warm ochre and deep green |

The composition line carries the banner's real requirement: **empty space on the right**, because the newsletter puts its headline there. That is the part most often left out, and the part that decides whether the picture can be used at all.

A few habits make these prompts work better, and none of them is a secret phrase.

**Concrete beats evaluative.** "Beautiful", "stunning" and "high quality" describe a judgement and not a picture. "Late afternoon sun from the left" describes light a model has seen thousands of times.

**Say what is there, not what is not.** "No people" puts the word *people* into the prompt. Some local models take a separate **negative prompt** for what to steer away from; where an API has none, describe the scene so that people would be out of place ("an empty café before opening").

**Length has a ceiling.** Many open models read the prompt through the CLIP text encoder, which takes 77 tokens and ignores the rest, so the end of a long prompt is not read at all. Newer models use larger text encoders and read much more. Either way, the parts that matter go first.

**Text inside the picture is its own request.** If the banner needs words on it, put them in quotes and keep them short ("a chalkboard sign that says \"Used books\""), or, better, leave the space empty and add the words in the newsletter, where they are real text that can be read aloud by a screen reader (lesson 14).
