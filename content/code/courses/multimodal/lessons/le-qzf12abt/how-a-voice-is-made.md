---
title: How text becomes a voice
version: 1
---

**A text-to-speech system turns characters into sound in stages**, and the first stage is the one that goes wrong. The stages have been the same for decades; what modern models changed is how the last ones are done.

1. **Text normalisation** turns what is written into what is said: digits into words, abbreviations into what they stand for, symbols into names.
2. **Phonemisation** turns words into **phonemes**, the sounds of a language, so that *though* and *tough* are not read alike.
3. **The acoustic model** turns phonemes into a description of sound over time: pitch, duration, timbre.
4. **The vocoder** turns that description into a waveform, the numbers a speaker plays.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Four boxes in a row, joined by arrows. Text: M-1042. Normalised words: M one thousand forty-two. Phonemes, as espeak-ng writes them: ɛm wʌn θaʊzənd foːɹɾi tuː. Waveform: 22,050 numbers a second. Under the last two boxes, a bracket says that Piper&#x27;s VITS model does both steps in one network.\"><defs><marker id=\"l06stg-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">text</text><text x=\"30\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">M-1042</text><line x1=\"172\" y1=\"58\" x2=\"193\" y2=\"58\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l06stg-ah-phosphor)\"></line><rect x=\"195\" y=\"30\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"205\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">words</text><text x=\"205\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one thousand forty-two</text><line x1=\"347\" y1=\"58\" x2=\"368\" y2=\"58\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l06stg-ah-phosphor)\"></line><rect x=\"370\" y=\"30\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">phonemes</text><text x=\"380\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ɛm wʌn θaʊzənd</text><line x1=\"522\" y1=\"58\" x2=\"543\" y2=\"58\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l06stg-ah-phosphor)\"></line><rect x=\"545\" y=\"30\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"555\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">waveform</text><text x=\"555\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22,050 a second</text><text x=\"199\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the step that goes wrong</text><path d=\"M 370 120 L 370 132 L 695 132 L 695 120\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"532\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Piper's VITS model: one network</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">espeak-ng does the first two steps by rule; the model learns the last two.</text></svg>", "caption": "A voice is only as right as the words it was handed, and the handing over is done by rules a person can read."}
```

The lab's voices are **Piper** voices, which are VITS models: one neural network that does stages 3 and 4 together, from phonemes straight to a waveform. Stages 1 and 2 are done before the network by **espeak-ng**, an open-source speech program whose rules for many languages Piper borrows (each voice carries its own copy of espeak-ng's data). Because those rules are a program, you can ask them directly what they will hand the voice:

```
ana@lab:~/mm$ espeak-ng -q --ipa -v en-us "Your order M-1042 arrived on 24/09/2026."
jʊɹ ˈɔːɹdɚɹ ˈɛm  wˈʌn θˈaʊzənd fˈoːɹɾi tˈuː ɚɹˈaɪvd ˌɔn twˈɛnti fˈoːɹ slˈæʃ zˈiəɹoʊ nˈaɪn slˈæʃ tˈuː θˈaʊzənd twˈɛnti sˈɪks
ana@lab:~/mm$ espeak-ng -q --ipa -v en-us "Your refund of R\$ 34,80 is on its way."
jʊɹ ɹˈiːfʌnd ʌv ˈɑːɹ dˈɑːlɚ θˈɜːɾi fˈoːɹ ˈeɪɾi ɪz ˌɔn ɪts wˈeɪ
ana@lab:~/mm$ espeak-ng -q --ipa -v en-us "Dom Casmurro, by Machado de Assis."
dˈɑːm kæzmˈɜːɹoʊ
baɪ mætʃˈɑːdoʊ də ɐsˈɪs
ana@lab:~/mm$ espeak-ng -q --ipa -v pt-br "Dom Casmurro, de Machado de Assis."
dˈoŋ kˌazmˈuxʊ
dʒy mˌaʃˈadʊ dʒj asˈis
```

The output is in the International Phonetic Alphabet, and you do not need to read it fluently to see three problems.

**The order number became a quantity**: *ˈɛm wˈʌn θˈaʊzənd fˈoːɹɾi tˈuː*, "M one thousand forty-two". Nobody reads an order number like that, and a customer writing it down would write 1000 and 42, as Whisper did with the support call in lesson 1.

**The date was read character by character**: "twenty four slash zero nine slash two thousand twenty six". The money became "R dollar thirty four eighty", because `$` is *dollar* and the comma is a pause.

**The Brazilian name was read with English rules** in the English voice: *mætʃˈɑːdoʊ* for Machado, with the *ch* of *match*. The Portuguese voice's rules give *mˌaʃˈadʊ*, with the *sh* sound Brazilian Portuguese uses. Neither is a bug in espeak-ng: each read the text by its language's rules, which is exactly what it was asked to do.

**None of these is the voice's fault**, and none would be fixed by a better voice. A better neural network pronounces the wrong words more beautifully. The fix is stage 1, done by you, before the voice sees the text: section 04.
