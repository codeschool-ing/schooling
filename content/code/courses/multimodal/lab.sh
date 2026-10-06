#!/usr/bin/env bash
# The machine every transcript in multimodal was recorded on.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana is a developer at Marginalia, the
# online bookshop of embeddings-vectors, rag and agents-mcp, and this course is
# her teaching the shop's software to read a scanned invoice, listen to a
# support call, watch its own "how to return a book" video and speak back.
#
#   /home/ana/mm            the working directory, rebuilt by `reset`
#     media/                the pictures, recordings and video (below)
#     media/truth/          what each of them really says, for measuring
#     data/books.jsonl      Marginalia's 60 books, from embeddings-vectors
#   /opt/multimodal         Python 3.11 in a virtual environment, with every
#                           library the lessons import, pinned in PYLIBS
#   /opt/multimodal/share   the models (MODELS below), the stand-in's rules
#                           (lab/scripted/*.json), the o200k_base encoding,
#                           all-MiniLM-L6-v2, and LiteLLM's price sheet
#   /opt/multimodal/media   the media as built, copied into ~/mm on reset
#   127.0.0.1:8700          labmm, the stand-in provider (lab/labmm.py)
#   /var/log/labmm          every request labmm received, one JSON line each
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real models,  OpenAI's Whisper (tiny and base) and three Piper voices,
#   run here      pyannote's speaker segmentation and 3D-Speaker's ERes2Net,
#                 Silero VAD and GTCRN, all as the ONNX files sherpa-onnx
#                 publishes; MediaPipe's EfficientDet-Lite0; Tesseract 5;
#                 all-MiniLM-L6-v2. What they say in a transcript is what
#                 they said on this machine.
#   real tools    ffmpeg and ffprobe, Pillow, jiwer, the openai and
#                 google-genai SDKs, LangChain and LlamaIndex.
#   real, dated   sheet: LiteLLM's model_prices_and_context_window.json at one
#                 pinned commit, read by ai-models' own lab/sheet.py. Every
#                 price in the course comes from it, and says so.
#   the lab's     labmm. Its audio routes run the real models above. Its
#                 vision and image models are not models: what they say
#                 about an image is a rule the course wrote in lab/scripted/,
#                 and the pictures they "generate" are cards saying so.
#   written       every recording, picture and video in ~/mm/media, built by
#                 lab/build_media.py from lab/media/*.json, EXCEPT
#                 cat_and_dog.jpg, a photograph from MediaPipe's examples.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: every provider's real API (OpenAI,
# Google, Hugging Face's Inference Providers) and the Hugging Face Hub itself.
# The lessons that show code against them say it was not run.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           rebuild ~/mm and restart labmm
#   sudo bash lab.sh down
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/mm
#
# Recorded on Ubuntu 24.04 with Python 3.11, Node.js 22 and ffmpeg 6.1,
# TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. labmm must not
# inherit it, or it holds it for as long as it lives.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
EMBLAB=$HERE/../embeddings-vectors/lab
AILAB=$HERE/../ai-models/lab
VENV=/opt/multimodal
SHARE=$VENV/share
MEDIA=$VENV/media
WORK=/home/ana/mm
LOGDIR=/var/log/labmm
# openai is held at 2.54.0, the last release llama-index-llms-openai accepts:
# it asks for openai<3, and one environment cannot hold two versions of it.
PYLIBS="sherpa-onnx==1.13.8 mediapipe==1.0.1 numpy==2.4.6 pillow==12.3.0 soundfile==0.14.0
  jiwer==4.0.0 openai==2.54.0 google-genai==2.28.0 tiktoken==0.14.0 onnxruntime==1.30.0
  tokenizers==0.23.2 langchain-core==1.6.6 langchain-openai==1.6.7 llama-index-core==0.14.25
  llama-index-llms-openai==0.8.2"
APT="ffmpeg tesseract-ocr tesseract-ocr-por libegl1 libgles2 fonts-dejavu-core"

# Every model, where it comes from, and the SHA-256 it has to have. A .tar.bz2
# is unpacked into share/; anything else is kept as it is.
SHERPA=https://github.com/k2-fsa/sherpa-onnx/releases/download
MODELS="
$SHERPA/asr-models/sherpa-onnx-whisper-tiny.tar.bz2 c46116994e539aa165266d96b325252728429c12535eb9d8b6a2b10f129e66b1
$SHERPA/asr-models/sherpa-onnx-whisper-base.tar.bz2 911b2083efd7c0dca2ac3b358b75222660dc09fb716d64fbfc417ba6c99ff3de
$SHERPA/tts-models/vits-piper-en_US-lessac-medium.tar.bz2 9e3febfacf0abf4270172d2958bcec246032b7e88efc2720840cc80c93de334e
$SHERPA/tts-models/vits-piper-en_GB-alan-medium.tar.bz2 a48d4017da0f77668b27bed63fe6e04dd64c6397e1fadad4f460efb0ef7c9012
$SHERPA/tts-models/vits-piper-pt_BR-faber-medium.tar.bz2 7add3f923ad6bc25ca8a192805fd1a64d1b3893e4611c4a9719545a825039a83
$SHERPA/speaker-segmentation-models/sherpa-onnx-pyannote-segmentation-3-0.tar.bz2 24615ee884c897d9d2ba09bb4d30da6bb1b15e685065962db5b02e76e4996488
$SHERPA/speaker-recongition-models/3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx 1a331345f04805badbb495c775a6ddffcdd1a732567d5ec8b3d5749e3c7a5e4b
$SHERPA/asr-models/silero_vad.onnx 9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6
$SHERPA/speech-enhancement-models/gtcrn_simple.onnx e77603ac0c23dac3227dd2d7135b3a585cbee2679048aecfa886657d3ae1b534
https://storage.googleapis.com/mediapipe-models/object_detector/efficientdet_lite0/float32/latest/efficientdet_lite0.tflite 40338edf5ec70d43e318b0a716a84d4564cd1802759a7a07170c7e43796dbf58
https://storage.googleapis.com/mediapipe-tasks/object_detector/cat_and_dog.jpg cfa90c34bb93021165e48bd22cfc20dbbb0440ff638a54878939bf30d362e824
"
MINILM_URL=https://chroma-onnx-models.s3.amazonaws.com/all-MiniLM-L6-v2/onnx.tar.gz
MINILM_SHA256=913d7300ceae3b2dbc2c50d1de4baacab4be7b9380491c27fab7418616a16ec3
# A directory of files already downloaded, checked against the same hashes.
CACHE=${MM_CACHE:-}

ENVFILE=/etc/multimodal.env
write_env() {
  cat > "$ENVFILE" <<EOF
PATH=$VENV/bin:/usr/local/bin:/usr/bin:/bin
TZ=America/Sao_Paulo
LANG=C.UTF-8
LC_ALL=C.UTF-8
PYTHONDONTWRITEBYTECODE=1
MM_SHARE=$SHARE
TIKTOKEN_CACHE_DIR=$SHARE/tiktoken
MINILM_DIR=$SHARE/all-MiniLM-L6-v2
SHEET_CACHE=$SHARE/litellm-21881c57.json
OPENAI_BASE_URL=http://127.0.0.1:8700/v1
OPENAI_API_KEY=lab-openai-key-0001
GOOGLE_GEMINI_BASE_URL=http://127.0.0.1:8700
GEMINI_API_KEY=lab-google-key-0001
GLOG_minloglevel=2
EOF
}

need() {
  command -v python3.11 >/dev/null || { echo "python3.11 is required" >&2; exit 1; }
  command -v npm >/dev/null || { echo "npm is required (Node.js 22)" >&2; exit 1; }
  [ -f "$EMBLAB/minilm.py" ] || { echo "embeddings-vectors' lab is required beside this course" >&2; exit 1; }
  [ -f "$AILAB/sheet.py" ] || { echo "ai-models' lab is required beside this course" >&2; exit 1; }
  # shellcheck disable=SC2086
  dpkg -s $APT >/dev/null 2>&1 || { apt-get update -q && apt-get install -y -q $APT; }
}

build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  id labmm >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin labmm
  mkdir -p $LOGDIR && chown labmm:labmm $LOGDIR && chmod 0755 $LOGDIR
}

build_venv() {
  [ -x $VENV/bin/python ] || python3.11 -m venv $VENV
  # shellcheck disable=SC2086
  $VENV/bin/pip install -q $PYLIBS
  mkdir -p $SHARE
  install_lab
}

# The lab's own programs, importable by name: mmlab, labmm and the media
# builder; MiniLM's runner from embeddings-vectors; and `sheet`, ai-models'
# reader of LiteLLM's price sheet.
install_lab() {
  local site
  site=$($VENV/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')
  install -m 0644 "$HERE/lab/mmlab.py" "$HERE/lab/labmm.py" "$HERE/lab/build_media.py" "$EMBLAB/minilm.py" "$site/"
  install -m 0644 "$AILAB/sheet.py" "$site/sheet.py"
  printf '#!/bin/sh\nexec %s/bin/python -m sheet "$@"\n' $VENV > $VENV/bin/sheet
  chmod 0755 $VENV/bin/sheet
  rm -rf $SHARE/scripted && mkdir -p $SHARE/scripted
  install -m 0644 "$HERE"/lab/scripted/*.json $SHARE/scripted/
}

fetch() {  # fetch URL SHA256 DEST
  local name=${1##*/}
  if [ -n "$CACHE" ] && [ -f "$CACHE/$name" ]; then cp "$CACHE/$name" "$3"; else curl -sSfL -o "$3" "$1"; fi
  echo "$2  $3" | sha256sum -c --quiet
}

build_models() {
  local url sum name t
  t=$(mktemp -d)
  while read -r url sum; do
    [ -n "$url" ] || continue
    name=${url##*/}
    case $name in
      *.tar.bz2) [ -d "$SHARE/${name%.tar.bz2}" ] && continue
                 fetch "$url" "$sum" "$t/$name"; tar -xjf "$t/$name" -C $SHARE; rm -f "$t/$name" ;;
      *)         [ -f "$SHARE/$name" ] && continue
                 fetch "$url" "$sum" "$SHARE/$name" ;;
    esac
  done <<< "$MODELS"
  if [ ! -f $SHARE/all-MiniLM-L6-v2/model.onnx ]; then
    fetch $MINILM_URL $MINILM_SHA256 "$t/onnx.tar.gz"
    tar -xzf "$t/onnx.tar.gz" -C "$t" && rm -rf $SHARE/all-MiniLM-L6-v2 && mv "$t/onnx" $SHARE/all-MiniLM-L6-v2
  fi
  rm -rf "$t"
  # The test recordings that come inside the Whisper archives are not the
  # course's, and nothing here uses them.
  rm -rf $SHARE/sherpa-onnx-whisper-*/test_wavs
  chmod -R a+rX $SHARE
  SHEET_CACHE=$SHARE/litellm-21881c57.json $VENV/bin/python -m sheet count >/dev/null
  chmod a+r $SHARE/litellm-21881c57.json
}

# o200k_base, which labmm counts text tokens with, rebuilt from the npm package
# js-tiktoken exactly as agents-mcp's lab does it: the usual download was out of
# reach, and tiktoken refuses the result unless its SHA-256 is the one it ships.
build_tokenizer() {
  local node=$SHARE/node
  mkdir -p $node $SHARE/tiktoken
  ( cd $node && { [ -f package.json ] || npm init -y >/dev/null; } && npm install --silent js-tiktoken@1.0.21 )
  ( cd $node && node -e '
    const fs = require("fs"), crypto = require("crypto");
    const r = require("js-tiktoken/ranks/o200k_base"), rows = [];
    for (const line of r.bpe_ranks.split("\n").filter(Boolean)) {
      const [, offset, ...tokens] = line.split(" ");
      tokens.forEach((t, i) => rows.push([parseInt(offset, 10) + i, t]));
    }
    rows.sort((a, b) => a[0] - b[0]);
    const url = "https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken";
    const name = crypto.createHash("sha1").update(url).digest("hex");
    fs.writeFileSync(process.argv[1] + "/" + name, rows.map(([k, t]) => t + " " + k).join("\n") + "\n");' $SHARE/tiktoken )
  chmod -R a+rX $SHARE/tiktoken
  TIKTOKEN_CACHE_DIR=$SHARE/tiktoken $VENV/bin/python -c 'import tiktoken; tiktoken.get_encoding("o200k_base")'
}

build_media() {
  [ -f $MEDIA/returns.mp4 ] && return 0
  rm -rf $MEDIA
  MM_SHARE=$SHARE TZ=America/Sao_Paulo $VENV/bin/python -m build_media "$HERE/lab/media" $MEDIA
  chmod -R a+rX $MEDIA
}

# ~/mm as it stands before lesson 1: the media, the books, and nothing else.
build_work() {
  rm -rf $WORK
  install -d -o ana -g ana $WORK $WORK/data
  cp -r $MEDIA $WORK/media
  install -m 0644 "$EMBLAB/data/books.jsonl" $WORK/data/
  chown -R ana:ana $WORK
}

start_mm() {
  stop_mm
  : > $LOGDIR/requests.jsonl; chown labmm:labmm $LOGDIR/requests.jsonl; chmod 0644 $LOGDIR/requests.jsonl
  setsid runuser -u labmm -- env -i PATH=$VENV/bin:/usr/bin:/bin TZ=America/Sao_Paulo GLOG_minloglevel=2 \
    TIKTOKEN_CACHE_DIR=$SHARE/tiktoken MM_SHARE=$SHARE LABMM_LOG=$LOGDIR LABMM_FILES=$MEDIA \
    $VENV/bin/python -W ignore -m labmm > /run/labmm.out 2>&1 < /dev/null &
  echo $! > /run/labmm.pid
  for _ in $(seq 50); do
    curl -s -o /dev/null http://127.0.0.1:8700/ 2>/dev/null && return 0
    sleep 0.2
  done
  echo "labmm did not start; see /run/labmm.out" >&2; return 1
}

stop_mm() {
  if [ -f /run/labmm.pid ]; then
    kill "$(cat /run/labmm.pid)" 2>/dev/null || true
    rm -f /run/labmm.pid
    sleep 0.3
  fi
}

exec_as() {  # exec_as COMMAND: as ana, in ~/mm, with the lab's environment and nothing else
  # shellcheck disable=SC2046
  runuser -u ana -- env -i HOME=/home/ana USER=ana $(grep -v '^#' $ENVFILE | xargs) \
    bash -c "cd $WORK || exit 1; $*"
}

case ${1:-} in
  up)
    need; build_user; write_env; build_venv; build_tokenizer; build_models; build_media
    build_work; start_mm ;;
  reset)
    write_env; install_lab; build_media; build_work; start_mm ;;
  down)
    stop_mm ;;
  exec)
    shift; exec_as "$@" ;;
  *)
    echo "usage: sudo bash lab.sh up|reset|down|exec 'COMMAND'" >&2; exit 2 ;;
esac
