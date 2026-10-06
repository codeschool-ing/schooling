---
title: Choosing an open model for a job
version: 1
---

Every model in this lab was chosen by the same handful of questions, and they are the ones to ask of any open model on the Hub.

```
ana@lab:~/mm$ cd /opt/multimodal/share && for f in silero_vad.onnx gtcrn_simple.onnx efficientdet_lite0.tflite 3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx sherpa-onnx-pyannote-segmentation-3-0/model.onnx vits-piper-en_US-lessac-medium/en_US-lessac-medium.onnx sherpa-onnx-whisper-tiny/tiny-encoder.int8.onnx; do printf "%10s  %s\n" $(stat -c %s $f) $f; done
    643854  silero_vad.onnx
    535638  gtcrn_simple.onnx
  13836895  efficientdet_lite0.tflite
  39593761  3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx
   5992913  sherpa-onnx-pyannote-segmentation-3-0/model.onnx
  63149198  vits-piper-en_US-lessac-medium/en_US-lessac-medium.onnx
  12937772  sherpa-onnx-whisper-tiny/tiny-encoder.int8.onnx
```

**How big is it, and where will it run?** The lab's models range from Silero's 644 kilobytes to the lessac voice's 63 megabytes and Whisper base's 160. Every one of them runs on four ordinary processor cores with no graphics card, which is why they were chosen: a voice on a phone menu or a detector in a returns form has to run on whatever machine the shop has. A vision-language model of several billion parameters is a different class of machine entirely.

**Does it do the job on my data?** The answer is a measurement, never a leaderboard. Lesson 5 found that the cleanest-sounding denoiser was not the one that helped Whisper; lesson 7 found that a larger model bought nothing on bad audio. A leaderboard is someone else's test set.

**What does the licence allow?** Section 03's chain: the model, its card, its dataset. A CC0 voice and a research-only voice look the same in a folder.

**Can I run it the way I need to?** An ONNX export, a model on the Hub that transformers supports, or only a hosted endpoint: section 04's table. A model that exists only as weights in an unusual format is a conversion project before it is a component.

**Who keeps it working?** A model maintained by an active project gets fixes and conversions; one published once and left alone will still be the same file in five years, which is either reassuring or a warning, depending on what changes around it.

None of these questions is answered by the model's popularity. A model with millions of downloads can still be wrong for a Brazilian Portuguese phone line, and a small, specialised one can be exactly right.
