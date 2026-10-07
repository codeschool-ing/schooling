---
title: What a banner costs, and what makes it cost more
version: 1
---

Image generation is priced per picture, by size and quality, and the per-picture prices in the sheet make the comparison simple. One more number decides the real cost: **how many pictures are thrown away for each one used**. Lesson 3 measured nothing there, because no generator runs in this course, so the program assumes one in four:

```python
"""What one accepted banner costs, from the sheet's per-image prices, when one in four is accepted."""
PRICES = {"gpt-image-1, low": 0.011, "gpt-image-1, medium": 0.042, "gpt-image-1, high": 0.167,
          "gemini-2.5-flash-image": 0.039, "gemini-3.1-flash-image": 0.045}
for name, each in PRICES.items():
    print(f"{name:24} ${each:.3f} each   ${each * 4:.3f} per accepted   ${each * 4 * 52:6.2f} for a year of weekly banners")
```

```
ana@lab:~/mm$ python price.py
gpt-image-1, low         $0.011 each   $0.044 per accepted   $  2.29 for a year of weekly banners
gpt-image-1, medium      $0.042 each   $0.168 per accepted   $  8.74 for a year of weekly banners
gpt-image-1, high        $0.167 each   $0.668 per accepted   $ 34.74 for a year of weekly banners
gemini-2.5-flash-image   $0.039 each   $0.156 per accepted   $  8.11 for a year of weekly banners
gemini-3.1-flash-image   $0.045 each   $0.180 per accepted   $  9.36 for a year of weekly banners
```

The first column is the sheet's price per picture; for `gpt-image-1` at 1024 by 1024 it is in a field the sheet calls `input_cost_per_image`, a naming quirk of LiteLLM's file. **Quality moves the price fifteenfold**, from 0.011 dollars at `low` to 0.167 at `high`. A year of weekly banners costs between 2.29 and 34.74 dollars at one accepted in four. For a newsletter that is small change either way, and the choice of quality should be made by looking at both, not by the bill.

**It stops being small change when a customer presses the button.** A "see your book in a different cover" feature on the shop's site has no person choosing one picture in four: every press is a call, and a curious customer presses a dozen times. That is the design sheet's warning about this course, a cost that rises with how much people use the thing, and lesson 13 builds the limits that keep it bounded.

## Errors worth handling

- **400, invalid request**: a size the model does not take, a mask that does not fit. Fix the request; retrying the same one will fail the same way.
- **400 for content**: the provider refused the prompt or the picture under its policy (lesson 3). Do not retry automatically; show the person a message and log the prompt.
- **429 and 5xx**: rate limit or a provider fault. Retry with a delay. The openai SDK retries these by itself, twice by default, and google-genai also retries.

A picture that came back is a draft until someone approves it, which is why `banner.json` has an `approved_by` field that starts empty.
