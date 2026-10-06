---
title: Sound as numbers
version: 1
---

**A recording is a list of numbers, each one the air pressure at the microphone at one instant.** Three properties of that list decide almost everything about how a model treats it:

- the **sample rate**, how many numbers per second;
- the **bit depth** or encoding, how much room each number has;
- the **channels**, how many lists run side by side (one for mono, two for stereo).

The lab's support call exists in two forms, and the two differ in all of these that matter:

```
ana@lab:~/mm$ python -c "import soundfile as sf; [print(f, sf.info(f).samplerate, sf.info(f).channels, sf.info(f).subtype, round(sf.info(f).duration, 2)) for f in (\"media/call-1042.wav\", \"media/call-1042-phone.wav\")]"
media/call-1042.wav 16000 1 PCM_16 55.38
media/call-1042-phone.wav 8000 1 ULAW 55.38
ana@lab:~/mm$ python -c "print(16000 * 2 * 55.3835, 8000 * 1 * 55.3835)"
1772272.0 443068.0
ana@lab:~/mm$ stat -c "%s %n" media/call-1042.wav media/call-1042-phone.wav
1772316 media/call-1042.wav
443126 media/call-1042-phone.wav
```

The clean call is 16,000 samples a second of 16-bit numbers, 2 bytes each. Multiply out 55.3835 seconds and you get 1,772,272 bytes; the file is 1,772,316, and the 44 extra bytes are the WAV header saying how to read the rest. The telephone version is 8,000 samples a second in μ-law, an encoding that squeezes each sample into 1 byte by spending its precision on quiet sounds: a quarter of the size.

**What the sample rate costs is the high end of the sound.** A recording can only hold frequencies up to half its sample rate (the **Nyquist** limit), so 16 kHz audio holds up to 8 kHz and telephone audio up to 4 kHz. The phone version was also filtered to 300 to 3,400 Hz, the band telephone networks carry. Speech survives that: most of what makes words intelligible sits inside it, which is why phone calls work. Music does not survive it, and some consonants, *s* and *f* especially, lose much of what tells them apart.

**Speech models are trained at a fixed rate.** Whisper expects 16,000 samples a second, and so do Silero, pyannote and the speaker models in this lesson. Anything else is resampled first: `mmlab.read_audio` asks ffmpeg for 16 kHz mono whatever the file holds. Resampling up does not put back what was never recorded, so the phone call reaches Whisper at 16 kHz with nothing above 3,400 Hz in it. Lesson 7 measures what that costs.

**Stereo is a decision, not a detail.** Many call-centre systems record the agent on one channel and the customer on the other. That is the cheapest speaker separation there is, and it is lost the moment someone mixes the file to mono, which is what `-ac 1` does. If you control the recording, keep the channels apart.
