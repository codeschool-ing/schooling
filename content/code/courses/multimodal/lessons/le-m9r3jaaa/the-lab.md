---
title: The lab this course runs in
version: 1
---

Every transcript in this course was recorded on one Linux machine built by `lab.sh`, which sits beside `course.json`. It is the same kind of lab as `agents-mcp` and `embeddings-vectors`, and it reuses their bookshop: the 60 books come from `embeddings-vectors`, and the price sheet reader comes from `ai-models`. Build it once:

```sh
sudo bash lab.sh up
```

It creates the user `ana`, a Python virtual environment in `/opt/multimodal` with every library the lessons import, pinned in the script, the models, the media, and labmm, the provider the API lessons talk to. Each lesson's `captures.sh` starts with `lab.sh reset`, which rebuilds `~/mm` from nothing.

```
ana@lab:~/mm$ curl -s http://127.0.0.1:8700/; echo
{"labmm": "a stand-in provider; see lab/labmm.py", "models": ["lab-flash-image", "lab-image-1", "lab-tts-1", "lab-vision-1", "lab-whisper-base", "lab-whisper-tiny"]}
ana@lab:~/mm$ ls media media/truth
media:
call-1042-noisy.wav
call-1042-phone.wav
call-1042.wav
cat_and_dog.jpg
cover-b39.png
invoice-0931-scan.jpg
invoice-0931.png
returns.mp4
truth
voicemail-pt.wav

media/truth:
call-1042.json
call-1042.txt
invoice-0931.json
invoice-0931.txt
returns.json
returns.txt
voicemail-pt.json
voicemail-pt.txt
ana@lab:~/mm$ du -sh /opt/multimodal/share /opt/multimodal/lib /opt/multimodal/media
1.1G	/opt/multimodal/share
933M	/opt/multimodal/lib
5.0M	/opt/multimodal/media
ana@lab:~/mm$ python -c "import mmlab; print([n for n in dir(mmlab) if callable(getattr(mmlab, n)) and not n.startswith(\"_\") and n[0].islower() and n not in (\"np\", \"os\", \"subprocess\", \"sherpa_onnx\")])"
['denoiser', 'detector', 'diarizer', 'piper', 'read_audio', 'speech_segments', 'transcribe', 'whisper']
```

`mmlab` is a module of the lab's own, eight short functions, and every program in the course imports models from it. It knows where each model's files are and loads them with the settings the lessons need. Lesson 6 explains the one setting that matters, which makes a voice say a sentence the same way twice.

## What is real and what is a stand-in

This course has an unusual mix, so it says so plainly.

**Real, and running on the machine:** Whisper (two sizes) for speech to text, three Piper voices for text to speech, pyannote and 3D-Speaker for telling speakers apart, Silero for finding speech, GTCRN for removing noise, MediaPipe's EfficientDet for finding objects, and Tesseract for reading text in images. When a transcript shows what one of them said, that is what it said.

**A stand-in:** no provider's API could be reached from the machine the course was recorded on, and an API key is a bill a course cannot hand out. So **labmm** answers instead, on `127.0.0.1:8700`. It speaks the wire format of OpenAI's and Google's APIs closely enough that their SDKs talk to it unmodified. Behind its audio routes it runs the real Whisper and Piper above. Behind its vision and image routes **there is no model**: what it says about a picture was written by the course, and the pictures it returns are cards that say *no model drew this*. Every lesson that shows one of those replies says so beside it.

**Made for the course:** every picture, recording and video in `~/mm/media` except one photograph. A program in the lab drew them and spoke them from a script, so `media/truth` holds what each one really says.

## What it costs your computer

```
ana@lab:~/mm$ cd /opt/multimodal/share && du -sh sherpa-onnx-whisper-* vits-piper-* *.onnx *.tflite all-MiniLM-L6-v2 | sort -h
524K	gtcrn_simple.onnx
632K	silero_vad.onnx
14M	efficientdet_lite0.tflite
38M	3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx
79M	vits-piper-en_GB-alan-medium
79M	vits-piper-en_US-lessac-medium
79M	vits-piper-pt_BR-faber-medium
88M	all-MiniLM-L6-v2
244M	sherpa-onnx-whisper-tiny
432M	sherpa-onnx-whisper-base
```

About 2 GB in all: 1.1 GB of models and shared files and 933 MB of libraries, which is the `du` line above. Whisper's two folders are large because each holds the model twice, at full precision and at int8; lesson 11 compares them. The build needs the network once, to fetch the libraries from PyPI and npm and the models from sherpa-onnx's GitHub releases, MediaPipe's bucket and Chroma's bucket. Every model is checked against a SHA-256 written in `lab.sh` before it is used.

| path | what it takes | |
|---|---|---|
| **a Linux machine where you have root**, Ubuntu 24.04 | Python 3.11, Node.js 22, about 2 GB of disk and 4 GB of memory | **recommended**, and the one every transcript was recorded on |
| a virtual machine running Ubuntu 24.04 | the same, plus the VM's own: give it 6 GB of memory and 20 GB of disk | for Windows and macOS |
| a cloud development environment that gives you root | the same packages | not tried by this course |
