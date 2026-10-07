---
title: Showing a reply while it is written
version: 2
---

Models answer in Markdown, and a page renders it. **A reply half written is Markdown half
written**, and the moments in between are what a person sees. `partial.py` asks for a list with
bold words and prints the end of the text a page would have each time a bold opens or closes:

```python
"""What a page would have to render at each moment of a reply written in Markdown."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Why does a shop keep prices as whole cents? "
                                   "A short Markdown list, with the key word of each item in bold."}]
sofar = ""
was_open = False
with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
    for n, text in enumerate(stream.text_stream, 1):
        sofar += text
        is_open = sofar.count("**") % 2 == 1
        if is_open != was_open:
            print(f"after {n:3} pieces, bold {'opened' if is_open else 'closed'}: {sofar[-36:]!r}")
            was_open = is_open
print(f"at the end, {n} pieces and {len(sofar)} characters")
```

```
ana@dev:~/shop$ python partial.py
after  16 pieces, bold opened: ' keep prices as whole cents:\n\n*   **'
after  19 pieces, bold closed: 's as whole cents:\n\n*   **Rounding**:'
after  37 pieces, bold opened: 'lculations and reduce errors.\n*   **'
after  40 pieces, bold closed: 'uce errors.\n*   **Price stability**:'
after  59 pieces, bold opened: ' of small price fluctuations.\n*   **'
after  62 pieces, bold closed: ' fluctuations.\n*   **Cost control**:'
after  89 pieces, bold opened: 'the accuracy of calculations.\n*   **'
after  92 pieces, bold closed: 'lations.\n*   **Marketing strategy**:'
after 116 pieces, bold opened: 'ore appealing or competitive.\n*   **'
after 120 pieces, bold closed: 'r competitive.\n*   **Practicality**:'
at the end, 172 pieces and 884 characters
```

**Five bold words, and for three or four pieces each one is open**: after 16 pieces the text ends
in `**`, an opening marker with no close, and `**Rounding**` is only complete at piece 19. Rendered
as it stands, a page shows two asterisks; a page that waits for the close shows nothing yet; a page
that guesses shows bold that turns plain, or the reverse, as pieces arrive. Five times in one short
answer, each for about a third of a second at this speed, which is long enough to be seen.

## Rendering that does not flicker

- **Render the text so far on every piece**, with a Markdown renderer that tolerates unclosed
  markers. Most do: an unclosed `**` comes out as two literal asterisks for a moment, and becomes
  bold when the close arrives.
- **Or render complete blocks and show the rest plain.** Everything up to the last blank line is a
  finished paragraph or list; only the last part is still changing.
- **Do not move what the reader is reading.** Scroll to follow new text only while the reader is
  at the bottom. Someone who scrolled up to reread a sentence should not be pulled away from it.

## What the rest of the page should do

- **Show that something is happening before the first word.** Time to first token was three tenths
  of a second in section 01, and is several seconds with a long prompt or a model still loading. A placeholder that says the
  reply is coming is better than nothing on the screen.
- **Offer Stop while it streams**, and mean it, as lesson 9 section 06 does.
- **Announce the reply once, when it is complete, to a screen reader.** A live region updated on
  every piece reads out fragments, one after another. Updating it with the finished reply, or by
  sentence, gives the reader something they can follow.
