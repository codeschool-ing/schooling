---
title: Showing a reply while it is written
version: 1
---

Models answer in Markdown, and a page renders it. **A reply half written is Markdown half
written**, and the moments in between are what a person sees. `partial.py` prints the text a page
would have at three moments:

```python
"""What a page would have to render at each moment of a reply written in Markdown."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "The cents rule, as a short list."}]
sofar = ""
with model.messages.stream(model="scripted-1", max_tokens=300, messages=ASK) as stream:
    for n, text in enumerate(stream.text_stream, 1):
        sofar += text
        if n in (2, 5, 12):
            print(f"after {n:2} pieces: {sofar!r}")
print(f"at the end:      {sofar!r}")
```

```
ana@dev:~/shop$ python partial.py
after  2 pieces: '**Store'
after  5 pieces: '**Store cents, never'
after 12 pieces: '**Store cents, never floats.** Then:\n\n- add'
at the end:      '**Store cents, never floats.** Then:\n\n- add integers\n- round once, at the end\n- format at the edge'
```

**After two pieces the text is `**Store`**, an opening marker with no close. Rendered as it stands,
a page shows two asterisks; a page that waits for the close shows nothing yet; a page that guesses
shows bold that turns plain, or the reverse, as pieces arrive. The list after twelve pieces is
a list item with one word in it.

## Rendering that does not flicker

- **Render the text so far on every piece**, with a Markdown renderer that tolerates unclosed
  markers. Most do: an unclosed `**` comes out as two literal asterisks for a moment, and becomes
  bold when the close arrives.
- **Or render complete blocks and show the rest plain.** Everything up to the last blank line is a
  finished paragraph or list; only the last part is still changing.
- **Do not move what the reader is reading.** Scroll to follow new text only while the reader is
  at the bottom. Someone who scrolled up to reread a sentence should not be pulled away from it.

## What the rest of the page should do

- **Show that something is happening before the first word.** Time to first token is a tenth of a
  second in the lab and can be several seconds with a long prompt. A placeholder that says the
  reply is coming is better than nothing on the screen.
- **Offer Stop while it streams**, and mean it, as lesson 9 section 06 does.
- **Announce the reply once, when it is complete, to a screen reader.** A live region updated on
  every piece reads out fragments, one after another. Updating it with the finished reply, or by
  sentence, gives the reader something they can follow.
