---
title: What a photo says besides its picture
version: 1
---

A photo from a phone carries more than pixels. Its **EXIF** metadata records the camera, the moment it was taken and, often, **where**, as GPS coordinates precise enough to find a house. A customer who photographs a damaged book at home and uploads it to the returns form has, unless something removed it, sent the shop their address in the file.

The lab's photograph has no metadata, so the program writes some into a copy, the way a phone would, and then removes it:

```python
"""What a phone photo says about where it was taken, and the same photo with that removed."""
from PIL import Image

# A phone writes EXIF tags like these into every photo; here they are added by hand, to a copy.
exif = Image.Exif()
exif[0x010F] = "ExamplePhone"                            # Make
exif[0x0132] = "2026:10:05 18:42:07"                     # DateTime
exif.get_ifd(0x8825).update({1: "S", 2: (23.0, 33.0, 27.0), 3: "W", 4: (46.0, 37.0, 39.0)})   # GPS
Image.open("media/cat_and_dog.jpg").save("phone.jpg", exif=exif)


def tell(path):
    tags = Image.open(path).getexif()
    gps = tags.get_ifd(0x8825)
    print(f"{path:10} {len(tags)} tags; make={tags.get(0x010F)}; gps={dict(gps) or None}")


tell("phone.jpg")
img = Image.open("phone.jpg")
clean = Image.frombytes(img.mode, img.size, img.tobytes())   # the pixels and nothing else
clean.save("clean.jpg", quality=90)
tell("clean.jpg")
```

```
ana@lab:~/mm$ python strip.py
phone.jpg  3 tags; make=ExamplePhone; gps={1: 'S', 2: (23.0, 33.0, 27.0), 3: 'W', 4: (46.0, 37.0, 39.0)}
clean.jpg  0 tags; make=None; gps=None
```

The copy carries three tags: a camera make, a date and time, and a GPS block (23° 33′ 27″ south, 46° 37′ 39″ west, the centre of São Paulo). The clean copy carries none: it was made from the pixels alone, so nothing that was not a pixel could follow.

**Strip before anything else sees the file**: before it is stored, before it is sent to a vision API, before it is shown to staff. A third-party API receiving a photo with GPS in it has received the customer's location, which the privacy policy has to account for, and the shop gains nothing from it. Many upload services strip metadata by default, and "many" is not a guarantee; a program that does it itself, and a test that checks a stored file has no GPS tag, is.

Two more things a picture can carry, and a pipeline should decide about on purpose:

- **Faces and other people.** A photo of a parcel on a doorstep may include a neighbour. A detector (lesson 2) can find faces so that a pipeline blurs them before storing the picture.
- **Documents in the background.** A screenshot of an order page may show a card number or an address in another tab. OCR can find text that looks like a card number or a CPF before the picture goes anywhere.

Under the LGPD these are personal data, and some are sensitive. The cheapest compliance is not collecting them at all.
