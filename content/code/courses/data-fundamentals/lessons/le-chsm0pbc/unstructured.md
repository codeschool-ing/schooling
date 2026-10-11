---
title: Unstructured data, and the structured data around it
version: 1
---

**Unstructured data has no field names at all: the meaning is in the content, and a person or a
program has to interpret the content to get it out.** Text written by people, photographs, audio and
video are the usual cases. At Roda Livre that is the support inbox, the photos customers attach of a
damaged bicycle, and the recordings of calls to the help line.

The name misleads in one way worth correcting early. An email is not structure-free. It arrives with
a sender, a time, a subject, a list of attachments with their sizes, all of which are fields with names.
**What is unstructured is the body**, the part a person wrote. The same goes for a photograph, whose
file carries the time it was taken and the camera's settings beside millions of pixels that say "a
bent wheel" to a person and nothing to a query.

So unstructured data is nearly always kept in two parts:

- the object itself, stored as it came, byte for byte: the email body, the `.jpg`, the `.m4a`;
- the metadata about it, as ordinary structured rows: which customer, when, how many attachments,
  where the object is stored.

The metadata is what gets queried. "How many complaints arrived on Monday, and from how many customers"
needs only the metadata. "Which station do the complaints name" needs the body, and that is where the
work is.

## Pulling a station out of the text

Marta wants complaints counted per station. The station is somewhere in the words, if it is anywhere.
The simplest program that tries is a pattern made of the twelve station names, searched for in each
email. Save this as `emails.py`:

```python
# shapes/emails.py
import re

STATIONS = {
    'ST01': 'Praça Tiradentes', 'ST02': 'Rua XV', 'ST03': 'Jardim Botânico',
    'ST04': 'Passeio Público', 'ST05': 'Rodoferroviária', 'ST06': 'Largo da Ordem',
    'ST07': 'Shopping Estação', 'ST08': 'Parque Barigui', 'ST09': 'UFPR Politécnico',
    'ST10': 'Batel', 'ST11': 'Mercado Municipal', 'ST12': 'Ópera de Arame',
}
EMAILS = [  # id, received, customer, attachments, body
    ('M01', '2025-09-15 08:12', 'C0042', ['dock.jpg'],
     'The dock at Rua XV would not release my bike, I was late for work.'),
    ('M02', '2025-09-15 09:40', 'C0107', [],
     'Charged twice for one ride from Largo da Ordem to Jardim Botânico.'),
    ('M03', '2025-09-15 11:05', 'C0042', ['tyre.jpg', 'frame.jpg'],
     'Flat tyre on a bike at the Botanical Garden station, photos attached.'),
    ('M04', '2025-09-15 13:30', 'C0311', [],
     'No bikes at all at Rua 15 again this morning!!'),
    ('M05', '2025-09-15 17:52', 'C0019', [],
     'I live in Batel and the app keeps asking for my location.'),
    ('M06', '2025-09-15 19:20', 'C0256', ['call.m4a'],
     'Left a voice message about the station near the Opera de Arame.'),
]
NAMES = {name: code for code, name in STATIONS.items()}
PATTERN = re.compile('|'.join(re.escape(name) for name in NAMES))

print(f'{"id":4}{"received":18}{"customer":10}{"files":7}stations')
for mid, received, customer, files, body in EMAILS:
    found = ' '.join(NAMES[name] for name in PATTERN.findall(body))
    print(f'{mid:4}{received:18}{customer:10}{len(files):<7}{found or "-"}')
```

The six emails are pasted into the program as the support inbox might export them, each with its
metadata first and its body last. Run it:

```
ana@lab:~/roda/shapes$ python emails.py
id  received          customer  files  stations
M01 2025-09-15 08:12  C0042     1      ST02
M02 2025-09-15 09:40  C0107     0      ST06 ST03
M03 2025-09-15 11:05  C0042     2      -
M04 2025-09-15 13:30  C0311     0      -
M05 2025-09-15 17:52  C0019     0      ST10
M06 2025-09-15 19:20  C0256     1      -
```

The metadata columns came out perfectly, because they were never in doubt. The last column is the
interesting one. Read it against the six bodies above:

- M01 and M02 are right. The names were written exactly as the station list spells them;
- M03, M04 and M06 found nothing, and each one does name a station. The customer wrote "the
  Botanical Garden", which is Jardim Botânico said in English. "Rua 15" is how many people in Curitiba
  write Rua XV. "Opera de Arame" lost its accent, and the pattern compares characters, not intentions;
- M05 found the wrong thing. Batel is a station, and it is also a neighbourhood, and the customer
  lives there. The complaint is about the app asking for a location, not about a station.

Two right out of six, three missed and one wrong, on six emails written to be easy. **A pattern finds
the spellings you thought of, and the spellings you did not think of are the ones customers use.**
Adding `Rua 15` and the English name to the pattern fixes two of the three misses, and next week
somebody writes "Rodoviária".

## What better extraction looks like, and what it still needs

Better tools exist, and you should recognise their names: a language model asked to name the station
in a message, optical character recognition for text inside an image, speech-to-text for a recording,
an image classifier that says "flat tyre". Each one turns unstructured content into a structured
field, and each one is wrong some of the time, in ways a pattern is not. None of them is taught here.

Two habits hold whichever tool does the extraction. **Keep the original object.** The extracted
`ST03` is a derived value, made by one version of one program, and when a better extractor arrives the
originals are what it runs on. And **store the extracted field with where it came from**: which program
made it, and when. A station column that mixes values typed by staff with values guessed by a pattern
is a column nobody can trust, because nobody can tell which is which.
