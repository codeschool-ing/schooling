---
title: What is inside a video file
version: 1
---

**A video file is a container holding several streams**, and most of what a program does with video starts by pulling one of them out. ffprobe lists them:

```
ana@lab:~/mm$ ffprobe -v error -show_entries stream=codec_type,codec_name,width,height,r_frame_rate,nb_frames,sample_rate -show_entries format=duration,size -of compact=nk=0 media/returns.mp4
stream|codec_name=h264|codec_type=video|width=1280|height=720|r_frame_rate=25/1|nb_frames=815
stream|codec_name=aac|codec_type=audio|sample_rate=44100|r_frame_rate=0/0|nb_frames=1405
format|duration=32.600000|size=495585
```

Two streams. The **video stream** is H.264, 1280 by 720 pixels, 25 frames a second: 815 frames in 32.6 seconds. The **audio stream** is AAC at 44,100 samples a second. The **container**, MP4, holds them together, keeps them in time and adds nothing a model reads. Other files can hold more streams: subtitles, a second audio track in another language, chapters.

Three facts about the video stream decide how a program should treat it.

**Most frames are not pictures.** H.264 stores a full picture only now and then, as a **keyframe**, and between keyframes it stores the differences from the frame before. That is how 815 frames of 1280 by 720 fit in under half a megabyte. A program that asks for frame 300 makes the decoder start from the last keyframe and apply every difference up to it, which is why seeking is slower than it looks.

**Consecutive frames are almost the same.** At 25 frames a second, a slide that stays up for five seconds is 125 copies of one picture. Sending all of them to a model would be paying 125 times to be told the same thing.

**The two streams share a clock.** Every frame and every piece of sound has a timestamp, and that clock is what joins what was shown to what was said. The rest of this lesson keeps every time in seconds from the start of the file, because that is the one number both streams agree on.

So understanding a video means three decisions: **which frames to look at, how to read them, and how to put them back together with the sound.** Each section that follows makes one of them.
