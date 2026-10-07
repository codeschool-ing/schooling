---
title: Mojibake: text read in the wrong encoding
version: 1
---

**Mojibake is what text looks like after its bytes were decoded with the wrong encoding and the
result was saved.** The Japanese word means "character transformation", and it is the one text
defect in this course that destroys information if it is handled carelessly — and recovers it
completely if handled with care.

Quitanda Verde's 2023 migration read UTF-8 text as Latin-1. In UTF-8, `ã` is two bytes, `0xC3 0xA3`.
Read as Latin-1, where every byte is a character on its own, those two bytes become two characters:
`0xC3` is `Ã` and `0xA3` is `£`. The migration saved `SÃ£o Paulo`, in perfectly valid UTF-8, and
every system since has faithfully stored the damage.

```
ana@lab:~/clean$ python -c "from cities import city; bad = city[city.str.contains('Ã')]; print(bad.value_counts().to_string()); print(bad.iloc[0].encode('latin-1').decode('utf-8'))"
city
SÃ£o Paulo    9
sÃ£o paulo    1
São Paulo
```

The repair runs the mistake backwards: **encode the text as Latin-1 to get the original bytes back,
then decode those bytes as UTF-8**, as they should have been read in the first place. The last line
above is the result: `São Paulo`, exact.

The same migration touched names too:

```
ana@lab:~/clean$ python -c "from cities import customers as c; bad = c[c['name'].str.contains('Ã')]['name']; print(len(bad)); print(bad.head(3).to_string(index=False))"
43
              DÃ©bora Souza
             AndrÃ© Correia
PatrÃ­cia GuimarÃ£es Vieira
```

43 customers' names carry the damage: `DÃ©bora`, `AndrÃ©`, `GuimarÃ£es`. These are the column that
must never be rewritten by a guess, and here the repair is not a guess: the bytes are recovered, not
inferred.

## Repair only what is damaged

Running the repair on text that is not mojibake breaks it: `São` encoded as Latin-1 is a single byte
`0xE3`, which is not valid UTF-8, and the decode fails — or, with errors ignored, silently drops the
letter. So the repair is applied **only to values that show the signature**, as `fix_mojibake` does
with its test for `Ã`. That test is good enough for Portuguese text, where `Ã` almost never begins a
word in the middle of a line; for other languages the tool to reach for is the `ftfy` library, which
recognises the signatures of many encodings. It is not installed in this lab, and was not run.
