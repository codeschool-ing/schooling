---
title: Language: detected, set, and set wrong
version: 1
---

Whisper was trained on many languages at once, and before transcribing it decides which one it is hearing. You can let it decide or tell it. The lab's Portuguese voicemail, three ways:

```python
"""The Portuguese voicemail, with the language left to Whisper, set right, and set wrong."""
import mmlab

samples = mmlab.read_audio("media/voicemail-pt.wav")
for language in ("", "pt", "en"):
    text, detected = mmlab.transcribe(mmlab.whisper("base", language=language), samples)
    print(f"asked {language or 'nothing':7} -> {detected}: {text}\n")
```

```
ana@lab:~/mm$ python language.py
asked nothing -> pt: Oi, aqui é o Rafael Piente da Marginalia, soligando sobre o pedido em 2002-1877, um exemplar de memórias postmas de brásculpas que chegou com a capa amassada. Vocês podem me ligar de volta no fim da tarde? Obrigado.

asked pt      -> pt: Oi, aqui é o Rafael Piente da Marginalia, soligando sobre o pedido em 2002-1877, um exemplar de memórias postmas de brásculpas que chegou com a capa amassada. Vocês podem me ligar de volta no fim da tarde? Obrigado.

asked en      -> en: Hey, here is Rafael Pienta from Marginalia, I'm calling on the episode in May 2007, an exemplary of memories of brass cubes that arrived with the mass cover. Can you send me a message back to you in the end of the afternoon? Thanks!
```

**Left alone, it detected Portuguese** and wrote Portuguese, with errors of the kind you know by now: *Piente* for *cliente*, *soligando* for *Estou ligando*, an order number turned into *2002-1877*, and the title *Memórias Póstumas de Brás Cubas* as *memórias postmas de brásculpas*.

**Told it was Portuguese**, it wrote exactly the same. Setting the language you already know is right saves the detection step and removes a way to be wrong. Detection on a short or noisy clip, or one that opens with an English word, can pick the wrong language, and the next case shows what that costs.

**Told it was English, it translated.** *Hey, here is Rafael Pienta from Marginalia, I'm calling on the episode in May 2007, an exemplary of memories of brass cubes...* Whisper was trained to transcribe and to translate into English, and told to produce English from Portuguese speech it did the second job, badly and without any sign that it had changed jobs. *Episode in May 2007* for *pedido M-2087* and *brass cubes* for *Brás Cubas* are what a model writes when it understood the sounds and not the words.

## Three rules for language

1. **Set the language when you know it.** A shop's phone line in Brazil knows; so does a channel tagged per country.
2. **When you do not know, detect once per recording and store the answer** beside the transcript. A transcript with no language recorded is one nobody can check.
3. **Mixed-language speech is the hard case.** The lab's call is English with Portuguese names in it, and Whisper heard *Dom Casmurro* as *Dom Kazmuro*: English rules for Portuguese sounds, the mirror image of lesson 6's voice reading *Machado* with an English *ch*. The fix for names is the next section; the fix for whole sentences in another language is detecting per segment rather than per file.
