---
title: Judging the pictures, and what an accepted one costs
version: 1
---

A grid of pictures does not decide anything by itself. Somebody looks at it, and the looking goes better with a list written before the first picture arrives, because a striking picture that misses the requirement is still a miss.

For the banner, the list is the requirement and the style guide:

1. Is the right third empty enough for a headline?
2. Is there any text, or anything that tries to be text?
3. Is there a face, or anything that could be read as a real person or a real brand?
4. Are the medium and palette the guide's?
5. Would a reader see a pile of books, quickly, at the size the newsletter shows it?

Each picture gets a yes or no per line, and only a picture with five yeses is a candidate. Writing the list first is what stops the judging from turning into taste.

## The cost of an accepted picture

Image generation is priced per picture. The sheet the course reads prices from (LiteLLM's, at the commit `lab.sh` pins) says this for Google's image model:

```
ana@lab:~/mm$ sheet show gemini/gemini-2.5-flash-image | grep -E "output_cost_per_image|deprecation|source"
deprecation_date                           2026-10-02
output_cost_per_image                      0.039
output_cost_per_image_token                3e-05
source                                     https://ai.google.dev/gemini-api/docs/pricing
ana@lab:~/mm$ python -c "print(round(0.039 * 4, 3), round(0.039 * 12, 3))"
0.156 0.468
```

**0.039 dollars a picture**, and a **deprecation date of 2 October 2026**, four days before the lab's calendar. Both are facts about one day of one provider, read from a third party's copy of Google's pricing page, and both will be different when you read this. Lesson 9 looks at what that date means for code that names the model.

The price that matters is not per picture but **per accepted picture**. If one picture in four passes the list, each banner costs four generations: 0.156 dollars. If the team generates two per variant, across five variants, and keeps one, it costs 0.468 dollars for that one banner, as the second line above computes. That is still cheap for a banner and it is not cheap as a feature that a customer presses again and again, which is the design sheet's warning about this whole course and the subject of lesson 13.
