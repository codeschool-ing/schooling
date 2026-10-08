---
title: A list of numbers
version: 1
---

An embedding model takes text in and gives a fixed number of numbers out. The model this course
runs most of the time is **all-MiniLM-L6-v2**, a small open model published by the
sentence-transformers project. It runs on your own computer and needs no account. Lesson 9 opens it up; for now it is a function called `embed` in
`minilm.py`, the file you saved in *Setting up*.

Here is the title of the refund article going through it:

```schooling-example
{
  "language": "python",
  "file": "first.py",
  "parts": [
    {
      "code": "from minilm import embed",
      "note": "`embed` comes from `minilm.py`, which runs all-MiniLM-L6-v2 on this machine."
    },
    {
      "code": "v = embed(\"When your refund arrives\")[0]",
      "note": "One text in, a list of vectors out, one per text. `[0]` takes the first and only one."
    },
    {
      "code": "print(v.shape, v.dtype)\nprint(v[:8].round(4))",
      "note": "The vector is a NumPy array. Print its shape, its number type and the first eight of its numbers, rounded."
    },
    {
      "code": "print(\"length:\", round(float((v * v).sum()) ** 0.5, 6))\nprint(\"bytes: \", v.nbytes)",
      "note": "Its length is the square root of the sum of its squares, and `nbytes` is what it occupies in memory."
    }
  ]
}
```

```
ana@lab:~/emb$ python first.py
(384,) float32
[-0.0865 -0.0142 -0.0045  0.0386  0.0407  0.0211  0.0703  0.0093]
length: 1.0
bytes:  1536
```

Three things in that output are worth reading slowly.

**The shape is `(384,)`.** Whatever text goes in, three words or three paragraphs, 384 numbers come
out. That number is a property of the model, called its **dimension**, and every vector this model
ever produces has it. Other models produce 256, 768, 1536 or 3072; lesson 2 says what a dimension
is and what it is not.

**The numbers mean nothing one at a time.** `-0.0865` is the first coordinate of this text's
vector, and there is no sense in which it measures anything you could name, such as *how much this
is about money*. Information is spread across all 384 coordinates at once. What carries meaning is
the **position of the whole vector** relative to other vectors from the same model.

**The length is 1.0.** The model divides every vector by its own length before handing it over, so
all of them sit on the surface of a sphere of radius 1. That choice is not universal: some models
return vectors of any length, and lesson 2 shows what changes when they do.

## What it costs to keep one

Each number is a `float32`, four bytes, so one vector takes 384 × 4 = **1,536 bytes**, the `bytes`
line above. The text it came from, *When your refund arrives*, is 24 bytes. So the vector is 64 times
bigger than the title it describes.

That ratio surprises people who expect an embedding to be a compressed version of the text. It is
not one. It is a description of the text's meaning in a form that is easy to compare, and nothing
in it is laid out to be read back as words. For a help centre of 40 articles the size is nothing. For forty
million documents with a 1536-dimension model it is about 246 GB before any index, and lesson 18 is
about exactly that bill.

## Same text, same vector

Run `first.py` twice and the numbers are identical, to the last digit. The model has no
randomness at inference time: the same text through the same model gives the same vector. That is
what makes it possible to compute a document's vector once, store it, and compare new questions
against it next year — **as long as the model has not changed**. A different model, or even a
different version of the same one, produces vectors that cannot be compared with the stored ones.
The section *What an embedding is not* comes back to that.
