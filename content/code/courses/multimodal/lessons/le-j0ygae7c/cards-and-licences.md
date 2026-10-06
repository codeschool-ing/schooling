---
title: Model cards, and the licence that lives somewhere else
version: 1
---

A **model card** is the document published with a model: what it was trained on, what it is for, its known limits, and its licence. It is the first thing to read before a model goes into a product, and the lab's own models show why reading it is not a formality. The three Piper voices carry their cards with them:

```
ana@lab:~/mm$ grep -H -E "Language|License|URL" /opt/multimodal/share/vits-piper-*/MODEL_CARD
/opt/multimodal/share/vits-piper-en_GB-alan-medium/MODEL_CARD:* Language: en_GB (English, Great Britain)
/opt/multimodal/share/vits-piper-en_GB-alan-medium/MODEL_CARD:* URL: https://github.com/MycroftAI/mimic3-voices/blob/master/voices/en_UK/apope_low
/opt/multimodal/share/vits-piper-en_GB-alan-medium/MODEL_CARD:* License: See URL
/opt/multimodal/share/vits-piper-en_US-lessac-medium/MODEL_CARD:* Language: en_US (English, United States)
/opt/multimodal/share/vits-piper-en_US-lessac-medium/MODEL_CARD:* URL: https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/
/opt/multimodal/share/vits-piper-en_US-lessac-medium/MODEL_CARD:* License: https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/license.html
/opt/multimodal/share/vits-piper-pt_BR-faber-medium/MODEL_CARD:* Language: pt_BR (Portuguese, Brazil)
/opt/multimodal/share/vits-piper-pt_BR-faber-medium/MODEL_CARD:* URL: https://github.com/OHF-Voice/voice-datasets
/opt/multimodal/share/vits-piper-pt_BR-faber-medium/MODEL_CARD:* License: CC0
ana@lab:~/mm$ head -3 /opt/multimodal/share/sherpa-onnx-pyannote-segmentation-3-0/LICENSE; sed -n "3,4p" /opt/multimodal/share/sherpa-onnx-pyannote-segmentation-3-0/README.md
MIT License

Copyright (c) 2022 CNRS
Models in this file are converted from
https://huggingface.co/pyannote/segmentation-3.0/tree/main
```

Three voices, three different situations:

- **faber** (Brazilian Portuguese) says **CC0**: dedicated to the public domain, usable for anything.
- **lessac** (American English) points to the **licence page of the dataset** it was trained on, a corpus released for the Blizzard Challenge 2013, a research evaluation. The voice's own repository being open does not settle what the data allows; that page does.
- **alan** (British English) says **See URL**, and the URL is a voice in a different project. The answer is one more hop away.

The speaker segmentation model is simpler: its folder holds an MIT licence, copyright CNRS 2022, and a README saying it was **converted from `pyannote/segmentation-3.0` on the Hub**. That conversion is the second thing to notice.

**A converted model inherits the original's terms.** Every model in this lab is a conversion: sherpa-onnx turned Whisper, pyannote and the speaker models into ONNX files, and Piper's voices were trained and exported by their own project. The terms that matter are the original's, so the chain is: the converted file → the original model's card → the dataset it was trained on. Each link can add a restriction, and a model that is open to download is not thereby open to sell.

A practical rule for a product: **keep a table of every model you ship**, with its source, its licence, the dataset licence where the card names one, and the date you read them. The lab's `lab.sh` header is a short version of that table, and it is what a reviewer asks for.
