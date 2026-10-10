---
title: Release 1.1
version: 1
---

DRAFT: the prose of this section is written with the rest of lesson 9. The fences below are the
1.1 edits, as pairs: the lines to find, then the lines to put in their place.

```python
VERSION = "1.0"
```

```python
VERSION = "1.1"
```

```python
def discount(student, member, tickets):
    """The percentage off an order. Discounts do not add up; the largest one applies."""
    if student:
        return 50
    off = 0
    if member:
        off += 10
    if tickets >= 5:
        off += 15
    return off
```

```python
def discount(student, member, tickets):
    """The percentage off an order. Discounts do not add up; the largest one applies."""
    return max(10 if member else 0, 15 if tickets >= 5 else 0)
```

```python
    if not 1 <= quantity < 6:
```

```python
    if not 1 <= quantity <= 6:
```
