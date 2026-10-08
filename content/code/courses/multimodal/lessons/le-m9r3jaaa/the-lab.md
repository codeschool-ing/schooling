---
title: Your own lab
version: 2
---

Every program in this course runs on one Linux computer, and the platform does not give you one: you build it here, once, and every later lesson uses it. It holds four things:

- **Python, with a dozen libraries**, for the short programs the lessons print whole;
- **a set of small open models** for speech and pictures: Whisper to listen, Piper to speak, and the models that find speech, tell voices apart, clean noise and find objects in a photograph;
- **ffmpeg and Tesseract**, the two command-line tools that cut, convert and read media;
- **Ollama**, a free program that runs language models on your own computer, with no account and no card, and **three models for it**. `llama3.2:3b` writes text, and it is the same model every AI course here uses, so you may have it already. `qwen2.5vl:3b` reads pictures, which `llama3.2:3b` cannot do; the lessons that send an image to a model use it, and say so. `all-minilm` turns text into vectors for lesson 12's search.

## Three ways to have the computer

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Ubuntu 24.04 on your computer, or in WSL on Windows | about 10 GB of disk, and about 4 GB of memory while the vision model answers | match as printed |
| **a virtual machine** | Ubuntu Server 24.04 LTS, apart from your own system | the same, plus the guest's own system and the memory you give it | match as printed, slower |
| **online** | a Linux machine you rent by the hour | nothing on your computer; a bill per hour | close, not exact |

**Installed is the recommended path**, and the models are the reason. They are the heaviest thing in the course by far and they run fastest on the bare computer. A virtual machine keeps a fixed share of the memory for itself and, on most hypervisors, cannot reach the graphics card at all. Everything the setup adds lives in `/opt/multimodal`, `~/mm` and Ollama's own folder, and comes off again by deleting them.

- **On Linux**, run the script below. It was run on Ubuntu 24.04; another distribution has the same programs under its own package names.
- **On Windows**, install WSL with Ubuntu 24.04 (`wsl --install -d Ubuntu-24.04` in a PowerShell opened as administrator, then a restart) and run everything in the Ubuntu window.
- **On macOS**, Ollama has its own app at ollama.com, and Homebrew has Python, ffmpeg, Tesseract and espeak-ng. That was not run for this course: the models give the same answers, and a version, a path or a timing in a transcript will differ from yours.

**A virtual machine** is the path for a computer you would rather not change. Use Ubuntu Server 24.04 LTS as the guest: VirtualBox on Windows and Linux, UTM on macOS. Give it four processor cores, 8 GB of memory and 30 GB of disk; the vision model takes 3.2 GB of that memory to itself while it is loaded.

**Online**, any cloud provider rents a Linux machine by the hour. Pick Ubuntu 24.04 with four cores and at least 8 GB of memory. A free allowance may cover part of the course, on terms the company sets and can change, so plan as if you will pay. It was not run for this course.

**With an API key of your own**, the lessons that call OpenAI's or Google's APIs work against the real services, at their prices: change the model names, and point the SDK back at the provider (the end of this section shows where). Nothing in the course needs one, and none was used to record it.

## The script

`setup.sh`, which does all of it:

```sh
#!/bin/sh
# The multimodal course's lab, on Ubuntu 24.04: run it once as yourself, not as root.
#   packages      ffmpeg, Tesseract with Portuguese, espeak-ng, fonts, and what MediaPipe draws with
#   /opt/multimodal          Python's libraries for the course, in a virtual environment
#   /opt/multimodal/share    the models, each checked against its SHA-256
#   Ollama        the local model server, and the three models the lessons ask
set -e

sudo apt-get update
sudo apt-get install -y python3-venv ffmpeg tesseract-ocr tesseract-ocr-por espeak-ng \
  libegl1 libgles2 fonts-dejavu-core curl zstd unzip

sudo install -d -o "$(id -u)" -g "$(id -g)" /opt/multimodal
python3 -m venv /opt/multimodal
/opt/multimodal/bin/pip install sherpa-onnx==1.13.8 mediapipe==1.0.1 numpy==2.4.6 pillow==12.3.0 \
  soundfile==0.14.0 jiwer==4.0.0 openai==2.54.0 google-genai==2.28.0 tiktoken==0.14.0 \
  langchain-core==1.6.6 langchain-openai==1.6.7 llama-index-core==0.14.25 \
  llama-index-llms-openai==0.8.2 llama-index-llms-openai-like==0.8.1 num2words==0.5.14

SHARE=/opt/multimodal/share
mkdir -p $SHARE
cd $SHARE
S=https://github.com/k2-fsa/sherpa-onnx/releases/download
while read -r url sum; do
  name=${url##*/}
  [ -e "${name%.tar.bz2}" ] && continue          # already here from an earlier run
  curl -fsSL --retry 3 -o "$name" "$url"
  echo "$sum  $name" | sha256sum -c || { rm -f "$name"; exit 1; }
  case $name in *.tar.bz2) tar -xjf "$name" && rm "$name" ;; esac
done <<EOF
$S/asr-models/sherpa-onnx-whisper-tiny.tar.bz2 c46116994e539aa165266d96b325252728429c12535eb9d8b6a2b10f129e66b1
$S/asr-models/sherpa-onnx-whisper-base.tar.bz2 911b2083efd7c0dca2ac3b358b75222660dc09fb716d64fbfc417ba6c99ff3de
$S/tts-models/vits-piper-en_US-lessac-medium.tar.bz2 9e3febfacf0abf4270172d2958bcec246032b7e88efc2720840cc80c93de334e
$S/tts-models/vits-piper-en_GB-alan-medium.tar.bz2 a48d4017da0f77668b27bed63fe6e04dd64c6397e1fadad4f460efb0ef7c9012
$S/tts-models/vits-piper-pt_BR-faber-medium.tar.bz2 7add3f923ad6bc25ca8a192805fd1a64d1b3893e4611c4a9719545a825039a83
$S/speaker-segmentation-models/sherpa-onnx-pyannote-segmentation-3-0.tar.bz2 24615ee884c897d9d2ba09bb4d30da6bb1b15e685065962db5b02e76e4996488
$S/speaker-recongition-models/3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx 1a331345f04805badbb495c775a6ddffcdd1a732567d5ec8b3d5749e3c7a5e4b
$S/asr-models/silero_vad.onnx 9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6
$S/speech-enhancement-models/gtcrn_simple.onnx e77603ac0c23dac3227dd2d7135b3a585cbee2679048aecfa886657d3ae1b534
https://storage.googleapis.com/mediapipe-models/object_detector/efficientdet_lite0/float32/latest/efficientdet_lite0.tflite 40338edf5ec70d43e318b0a716a84d4564cd1802759a7a07170c7e43796dbf58
https://storage.googleapis.com/mediapipe-tasks/object_detector/cat_and_dog.jpg cfa90c34bb93021165e48bd22cfc20dbbb0440ff638a54878939bf30d362e824
EOF
rm -rf sherpa-onnx-whisper-*/test_wavs          # sample recordings that came in the archives

command -v ollama >/dev/null || curl -fsSL https://ollama.com/install.sh | sh
if ! ollama list >/dev/null 2>&1; then          # no systemd (WSL, a container): start it by hand
  nohup ollama serve >"$HOME/ollama.log" 2>&1 &
  sleep 5
fi
ollama pull llama3.2:3b
ollama pull qwen2.5vl:3b
ollama pull all-minilm

mkdir -p "$HOME/mm"
grep -q "^# multimodal" "$HOME/.bashrc" || cat >>"$HOME/.bashrc" <<'EOF'
# multimodal: the course's Python, and the OpenAI SDK pointed at the local Ollama
. /opt/multimodal/bin/activate
export OPENAI_BASE_URL=http://localhost:11434/v1 OPENAI_API_KEY=ollama
export GLOG_minloglevel=2
EOF
echo "done: open a new terminal, then cd ~/mm"
```

Save it in your home folder and run it as yourself, not as root. It asks for your password once, for the two `sudo` lines:

```sh
sh setup.sh
```

On the machine this course was recorded on it took a little over three minutes, most of it downloads: the Python libraries, about 1 GB of models for speech and pictures, and 5.2 GB for the three Ollama models. On a slower connection that last part is the wait.

Three lines of it deserve a word. **Every model is checked against a SHA-256** before it is kept, and a download that does not match is deleted and stops the script, so a run that finishes has exactly the files every transcript was made with. **The Python libraries are pinned** to the versions the transcripts used: a newer release of any of them is allowed to print something different. And **the last lines add four lines to your `~/.bashrc`**: each new terminal starts inside the course's Python, with the OpenAI SDK pointed at Ollama on your own machine instead of at OpenAI. That is why programs in later lessons can say `OpenAI()` and reach a model with no key and no bill. To point them back at OpenAI, delete those lines and set `OPENAI_API_KEY` to a key of your own.

## Checking it

Open a new terminal, so that `~/.bashrc` is read, and go to the working folder:

```sh
cd ~/mm
```

The tools, and the models Ollama has:

```
ana@lab:~/mm$ python --version; ffmpeg -version | head -1; tesseract --version | head -1; ollama --version
Python 3.12.3
ffmpeg version 6.1.1-3ubuntu5 Copyright (c) 2000-2023 the FFmpeg developers
tesseract 5.3.4
ollama version is 0.40.0
ana@lab:~/mm$ ollama list
NAME                 ID              SIZE      MODIFIED               
all-minilm:latest    1b226e2802db    45 MB     Less than a second ago    
qwen2.5vl:3b         fb90415cde1e    3.2 GB    3 seconds ago             
llama3.2:3b          a80c4f17acd5    2.0 GB    25 seconds ago            
```

And the disk it took:

```
ana@lab:~/mm$ du -sh /opt/multimodal ~/.ollama/models
1.8G	/opt/multimodal
5.0G	/home/ana/.ollama/models
ana@lab:~/mm$ cd /opt/multimodal/share && du -sh sherpa-onnx-whisper-* vits-piper-* *.onnx *.tflite | sort -h
524K	gtcrn_simple.onnx
632K	silero_vad.onnx
14M	efficientdet_lite0.tflite
38M	3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx
79M	vits-piper-en_GB-alan-medium
79M	vits-piper-en_US-lessac-medium
79M	vits-piper-pt_BR-faber-medium
244M	sherpa-onnx-whisper-tiny
432M	sherpa-onnx-whisper-base
```

Under seven gigabytes so far: 1.8 for the libraries and the speech and picture models in `/opt/multimodal`, and 5.0 for Ollama's three. Plan for ten, because the vision model takes about three more the first time it reads a picture; the end of the next section shows it. Whisper's two folders are large because each holds the model twice, at full precision and at int8; lesson 11 compares them. The next section makes the media, and then lesson 2 starts.
