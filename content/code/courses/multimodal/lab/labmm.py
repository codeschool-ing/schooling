"""labmm: the multimodal provider this course's lab talks to, on 127.0.0.1:8700.

IT IS A STAND-IN, AND EVERYTHING IT SAYS ABOUT ITSELF SAYS SO. No provider's
API was reachable from the machine the course was recorded on, and an API key
is a bill a course cannot hand out. What it copies is the WIRE of two APIs,
closely enough that the openai and google-genai SDKs talk to it unmodified:

    POST /v1/chat/completions                 OpenAI Chat Completions, with images
    POST /v1/responses                        OpenAI Responses, with images
    POST /v1/images/generations               OpenAI Images: generate
    POST /v1/images/edits                     OpenAI Images: edit with a mask
    POST /v1/audio/transcriptions             OpenAI Audio: speech to text
    POST /v1/audio/translations               OpenAI Audio: speech to English text
    POST /v1/audio/speech                     OpenAI Audio: text to speech
    POST /v1beta/models/<m>:generateContent   Google Gemini, with images in and out
    GET  /files/<name>                        the lab's media, for an image URL to point at

WHAT ANSWERS BEHIND EACH ONE IS NOT THE SAME, and the difference is the point:

    REAL MODELS, RUN HERE   lab-whisper-base and lab-whisper-tiny answer the
                            audio routes with Whisper run on this machine;
                            lab-tts-1 answers /v1/audio/speech with Piper.
                            What they return is what those models produced.
    WRITTEN BY THE COURSE   lab-vision-1 and lab-flash-image have no model in
                            them. A reply about an image is chosen from rules
                            in lab/scripted/*.json, matched on the image's
                            SHA-256 and phrases in the prompt, and every lesson
                            that shows one says so.
    DRAWN BY THE LAB        lab-image-1 and lab-flash-image do not generate
                            pictures. They return a card that says so, at the
                            size asked for, with the prompt written on it.

The rules that are the stand-in's own, and that the lessons quote:

    text tokens   o200k_base, plus 3 per message
    image tokens  lab-vision-1 counts them by the tile rule OpenAI published for
                  GPT-4o: detail "low" is 85; otherwise fit the image inside
                  2048 x 2048, shrink it until its short side is at most 768,
                  and charge 85 + 170 for every 512-pixel tile that covers it.
                  lab-flash-image counts by the rule Google published for
                  Gemini 2.0: 258 for an image with both sides at most 384,
                  otherwise 258 for every 768 x 768 tile.
    audio         25 MB at most per upload, in one of the formats OpenAI lists:
                  flac mp3 mp4 mpeg mpga m4a ogg wav webm.
    speech        4096 characters at most; speed from 0.25 to 4.0.
    transcription the recording is cut at silences by Silero VAD, each piece
                  is transcribed on its own, and the pieces are the segments
                  of verbose_json, srt and vtt. The `prompt` field is accepted
                  and logged and does NOT reach the model: the ONNX export
                  this lab runs has no way to take one.
"""
import base64
import cgi
import glob
import hashlib
import io
import itertools
import json
import math
import os
import re
import subprocess
import tempfile
import textwrap
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import numpy as np
import tiktoken
from PIL import Image, ImageDraw, ImageFont

import mmlab

ENC = tiktoken.get_encoding("o200k_base")
SHARE = os.environ.get("MM_SHARE", "/opt/multimodal/share")
LOG = os.environ.get("LABMM_LOG", "/var/log/labmm")
FILES = os.environ.get("LABMM_FILES", "/opt/multimodal/media")
KEYS = {"lab-openai-key-0001": "openai", "lab-google-key-0001": "google"}
CHAT = {"lab-vision-1"}
WHISPER = {"lab-whisper-base": "base", "lab-whisper-tiny": "tiny"}
VOICES = {"lessac": "en_US-lessac-medium", "alan": "en_GB-alan-medium", "faber": "pt_BR-faber-medium"}
IMAGE_SIZES = {"1024x1024", "1536x1024", "1024x1536", "auto"}
AUDIO_TYPES = {"flac", "mp3", "mp4", "mpeg", "mpga", "m4a", "ogg", "wav", "webm"}
UPLOAD_LIMIT = 25 * 1024 * 1024
SPEECH_FORMATS = {"mp3": ("mp3", ["-c:a", "libmp3lame", "-b:a", "64k"], "audio/mpeg"),
                  "opus": ("ogg", ["-c:a", "libopus", "-b:a", "32k"], "audio/ogg"),
                  "aac": ("adts", ["-c:a", "aac", "-b:a", "64k"], "audio/aac"),
                  "flac": ("flac", ["-c:a", "flac"], "audio/flac"),
                  "wav": ("wav", ["-c:a", "pcm_s16le"], "audio/wav"),
                  "pcm": ("s16le", ["-c:a", "pcm_s16le"], "audio/pcm")}
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

COUNTER = itertools.count(1)
LOCK = threading.Lock()
LOADED = {}


def model(kind, *args):
    """A model is loaded the first time it is asked for, and kept."""
    with LOCK:
        key = (kind,) + args
        if key not in LOADED:
            LOADED[key] = getattr(mmlab, kind)(*args)
        return LOADED[key]


def rules():
    out = []
    for path in sorted(glob.glob(os.path.join(SHARE, "scripted", "*.json"))):
        with open(path) as f:
            out += json.load(f)
    return out


def log(record):
    os.makedirs(LOG, exist_ok=True)
    with open(os.path.join(LOG, "requests.jsonl"), "a") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


class Refusal(Exception):
    def __init__(self, status, kind, message, param=None):
        super().__init__(message)
        self.status, self.kind, self.message, self.param = status, kind, message, param


# ---------------------------------------------------------------- images in

def load_image(url):
    """An image_url as the APIs take it: a data: URL, or http(s) to fetch."""
    if url.startswith("data:"):
        head, _, data = url.partition(",")
        raw = base64.b64decode(data)
    elif url.startswith(("http://127.0.0.1:8700/files/", "http://localhost:8700/files/")):
        raw = open(os.path.join(FILES, os.path.basename(url)), "rb").read()
    else:
        raise Refusal(400, "invalid_request_error",
                      f"labmm reaches no network: it cannot download {url}", "image_url")
    try:
        w, h = Image.open(io.BytesIO(raw)).size
    except Exception:
        raise Refusal(400, "invalid_request_error", "the image could not be decoded", "image_url")
    return {"sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw), "width": w, "height": h}


def gpt4o_tokens(w, h, detail):
    if detail == "low":
        return 85, 0
    if max(w, h) > 2048:
        s = 2048 / max(w, h)
        w, h = int(w * s), int(h * s)
    if min(w, h) > 768:
        s = 768 / min(w, h)
        w, h = int(w * s), int(h * s)
    tiles = math.ceil(w / 512) * math.ceil(h / 512)
    return 85 + 170 * tiles, tiles


def gemini_tokens(w, h):
    if w <= 384 and h <= 384:
        return 258
    return 258 * math.ceil(w / 768) * math.ceil(h / 768)


def text_tokens(text):
    return len(ENC.encode(text))


def scripted(texts, images, schema):
    """The course's reply for this prompt and these images, or a sentence saying there is none."""
    prompt = "\n".join(texts)
    shas = [i["sha256"] for i in images]
    for r in rules():
        w = r["when"]
        if not all(p.lower() in prompt.lower() for p in w.get("prompt", [])):
            continue
        want = w.get("images")
        if want is not None and [s[:12] for s in shas] != want:
            continue
        if bool(w.get("schema")) != bool(schema):
            continue
        return r["reply"], r["id"]
    return ("labmm has no reply written for this request. Its image replies are rules the course "
            "wrote, in lab/scripted/."), None


# ---------------------------------------------------------------- images out

def card(size, lines, base=None):
    """The picture a stand-in returns: what was asked, written on a card that says what it is."""
    w, h = size
    img = base.convert("RGB").resize(size) if base else Image.new("RGB", size, (58, 63, 71))
    d = ImageDraw.Draw(img)
    d.rectangle([24, 24, w - 24, 24 + 64 + 34 * len(lines)], fill=(30, 33, 38))
    d.text((48, 44), "labmm stand-in: no model drew this", font=ImageFont.truetype(BOLD, 28), fill=(255, 214, 102))
    for i, line in enumerate(lines):
        d.text((48, 96 + i * 34), line, font=ImageFont.truetype(FONT, 24), fill=(235, 235, 235))
    return img


def encode(img, fmt):
    buf = io.BytesIO()
    img.save(buf, format={"jpeg": "JPEG", "webp": "WEBP"}.get(fmt, "PNG"))
    return buf.getvalue()


# ---------------------------------------------------------------- the server

class Handler(BaseHTTPRequestHandler):
    server_version = "labmm/1.0"
    sys_version = ""
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def send(self, status, data, ctype, headers=None):
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("x-request-id", "req_lab_%04d" % self.n)
        for k, v in (headers or {}).items():
            self.send_header(k, str(v))
        self.end_headers()
        self.wfile.write(data)

    def send_json(self, status, obj):
        self.send(status, json.dumps(obj, ensure_ascii=False).encode(), "application/json")

    def json_body(self):
        n = int(self.headers.get("Content-Length") or 0)
        try:
            return json.loads(self.rfile.read(n) or b"{}")
        except json.JSONDecodeError as e:
            raise Refusal(400, "invalid_request_error", f"the body is not JSON: {e}")

    def form_body(self):
        n = int(self.headers.get("Content-Length") or 0)
        if n > UPLOAD_LIMIT + 1024 * 1024:
            self.rfile.read(n)
            raise Refusal(413, "invalid_request_error",
                          f"Maximum content size limit ({UPLOAD_LIMIT}) exceeded ({n} bytes read)")
        fs = cgi.FieldStorage(fp=self.rfile, headers=self.headers,
                              environ={"REQUEST_METHOD": "POST", "CONTENT_LENGTH": str(n),
                                       "CONTENT_TYPE": self.headers.get("Content-Type", "")})
        fields, files = {}, {}
        for k in fs.keys():
            items = fs[k] if isinstance(fs[k], list) else [fs[k]]
            for it in items:
                if it.filename:
                    files.setdefault(k, []).append((it.filename, it.value))
                else:
                    fields.setdefault(k, []).append(it.value)
        return {k: v[0] if len(v) == 1 else v for k, v in fields.items()}, files

    def gate(self, provider):
        if provider == "openai":
            key = (self.headers.get("Authorization") or "").removeprefix("Bearer ").strip()
        else:
            key = self.headers.get("x-goog-api-key")
        if KEYS.get(key) != provider:
            raise Refusal(401, "invalid_request_error",
                          "Incorrect API key provided" if provider == "openai" else "API key not valid")

    def refuse(self, e, provider):
        if provider == "google":
            obj = {"error": {"code": e.status, "message": e.message,
                             "status": {400: "INVALID_ARGUMENT", 401: "UNAUTHENTICATED",
                                        404: "NOT_FOUND"}.get(e.status, "INTERNAL")}}
        else:
            obj = {"error": {"message": e.message, "type": e.kind, "param": e.param, "code": None}}
        self.send_json(e.status, obj)

    def do_GET(self):
        self.n = next(COUNTER)
        if self.path.startswith("/files/"):
            p = os.path.join(FILES, os.path.basename(self.path))
            if not os.path.isfile(p):
                return self.send_json(404, {"error": {"message": "no such file"}})
            ctype = {"png": "image/png", "jpg": "image/jpeg", "wav": "audio/wav",
                     "mp4": "video/mp4"}.get(p.rsplit(".", 1)[-1], "application/octet-stream")
            return self.send(200, open(p, "rb").read(), ctype)
        self.send_json(200, {"labmm": "a stand-in provider; see lab/labmm.py",
                             "models": sorted(CHAT | set(WHISPER) | {"lab-tts-1", "lab-image-1", "lab-flash-image"})})

    def do_POST(self):
        self.n = next(COUNTER)
        path = self.path.split("?")[0]
        provider = "google" if path.startswith("/v1beta") else "openai"
        record = {"n": self.n, "path": path}
        started = time.time()
        try:
            self.gate(provider)
            if path == "/v1/chat/completions":
                self.chat(self.json_body(), record)
            elif path == "/v1/responses":
                self.respond(self.json_body(), record)
            elif path == "/v1/images/generations":
                self.generate(self.json_body(), record)
            elif path == "/v1/images/edits":
                self.edit(*self.form_body(), record)
            elif path in ("/v1/audio/transcriptions", "/v1/audio/translations"):
                self.listen(path.endswith("translations"), *self.form_body(), record)
            elif path == "/v1/audio/speech":
                self.speak(self.json_body(), record)
            elif path.startswith("/v1beta/models/"):
                self.gemini(path, self.json_body(), record)
            else:
                raise Refusal(404, "invalid_request_error", f"Invalid URL (POST {path})")
            record["status"] = 200
        except Refusal as e:
            record["status"], record["error"] = e.status, e.message
            self.refuse(e, provider)
        except Exception as e:  # a fault of labmm's own: said, logged, and answered as a 500
            record["status"], record["error"] = 500, repr(e)
            self.refuse(Refusal(500, "server_error", f"labmm failed: {e!r}"), provider)
        record["seconds"] = round(time.time() - started, 2)
        log(record)

    # -- OpenAI: images in, text out
    def read_parts(self, messages, record):
        texts, images, n_text = [], [], 0
        for m in messages:
            n_text += 3
            content = m.get("content")
            if isinstance(content, str):
                content = [{"type": "text", "text": content}]
            for part in content or []:
                t = part.get("type")
                if t in ("text", "input_text"):
                    texts.append(part["text"])
                    n_text += text_tokens(part["text"])
                elif t in ("image_url", "input_image"):
                    spec = part.get("image_url")
                    url = spec["url"] if isinstance(spec, dict) else spec
                    detail = (spec.get("detail") if isinstance(spec, dict) else part.get("detail")) or "auto"
                    img = load_image(url)
                    img["detail"] = detail
                    img["tokens"], img["tiles"] = gpt4o_tokens(img["width"], img["height"], detail)
                    images.append(img)
        record["images"] = [{k: v for k, v in i.items() if k != "sha256"} | {"sha256": i["sha256"][:12]}
                            for i in images]
        return texts, images, n_text + sum(i["tokens"] for i in images)

    def chat(self, req, record):
        model_name = req.get("model")
        if model_name not in CHAT:
            raise Refusal(404, "invalid_request_error", f"The model `{model_name}` does not exist", "model")
        record["model"] = model_name
        texts, images, n_in = self.read_parts(req.get("messages", []), record)
        schema = (req.get("response_format") or {}).get("type") == "json_schema"
        reply, rule = scripted(texts, images, schema)
        n_out = text_tokens(reply)
        record.update(rule=rule, usage={"prompt_tokens": n_in, "completion_tokens": n_out})
        self.send_json(200, {
            "id": "chatcmpl-lab%04d" % self.n, "object": "chat.completion", "created": int(time.time()),
            "model": model_name,
            "choices": [{"index": 0, "finish_reason": "stop",
                         "message": {"role": "assistant", "content": reply, "refusal": None}}],
            "usage": {"prompt_tokens": n_in, "completion_tokens": n_out, "total_tokens": n_in + n_out}})

    def respond(self, req, record):
        model_name = req.get("model")
        if model_name not in CHAT:
            raise Refusal(404, "invalid_request_error", f"The model `{model_name}` does not exist", "model")
        record["model"] = model_name
        items = req.get("input")
        if isinstance(items, str):
            items = [{"role": "user", "content": items}]
        if req.get("instructions"):
            items = [{"role": "system", "content": req["instructions"]}] + items
        texts, images, n_in = self.read_parts(items, record)
        schema = ((req.get("text") or {}).get("format") or {}).get("type") == "json_schema"
        reply, rule = scripted(texts, images, schema)
        n_out = text_tokens(reply)
        record.update(rule=rule, usage={"input_tokens": n_in, "output_tokens": n_out})
        self.send_json(200, {
            "id": "resp_lab%04d" % self.n, "object": "response", "created_at": int(time.time()),
            "status": "completed", "model": model_name,
            "output": [{"type": "message", "id": "msg_lab%04d" % self.n, "status": "completed",
                        "role": "assistant",
                        "content": [{"type": "output_text", "text": reply, "annotations": []}]}],
            "usage": {"input_tokens": n_in, "output_tokens": n_out, "total_tokens": n_in + n_out,
                      "input_tokens_details": {"cached_tokens": 0},
                      "output_tokens_details": {"reasoning_tokens": 0}}})

    # -- OpenAI: text in, images out
    def generate(self, req, record):
        if req.get("model") != "lab-image-1":
            raise Refusal(404, "invalid_request_error", f"The model `{req.get('model')}` does not exist", "model")
        prompt = req.get("prompt") or ""
        if not prompt.strip():
            raise Refusal(400, "invalid_request_error", "prompt is required", "prompt")
        size = req.get("size") or "auto"
        if size not in IMAGE_SIZES:
            raise Refusal(400, "invalid_request_error",
                          f"Invalid value: '{size}'. Supported values are: 'auto', '1024x1024', "
                          "'1024x1536', '1536x1024'.", "size")
        w, h = (1024, 1024) if size == "auto" else map(int, size.split("x"))
        n = int(req.get("n") or 1)
        fmt = req.get("output_format") or "png"
        lines = textwrap.wrap(prompt, 60)[:8] + [f"size {w}x{h}, quality {req.get('quality') or 'auto'}"]
        data = []
        for k in range(n):
            raw = encode(card((w, h), lines + [f"image {k + 1} of {n}"]), fmt)
            data.append({"b64_json": base64.b64encode(raw).decode()})
        record.update(model=req["model"], prompt=prompt, size=f"{w}x{h}", images=n,
                      bytes=[len(base64.b64decode(d["b64_json"])) for d in data])
        self.send_json(200, {"created": int(time.time()), "data": data, "output_format": fmt,
                             "size": f"{w}x{h}", "quality": req.get("quality") or "auto"})

    def edit(self, fields, files, record):
        if fields.get("model") != "lab-image-1":
            raise Refusal(404, "invalid_request_error", f"The model `{fields.get('model')}` does not exist", "model")
        images = files.get("image") or files.get("image[]")
        if not images:
            raise Refusal(400, "invalid_request_error", "image is required", "image")
        base = Image.open(io.BytesIO(images[0][1])).convert("RGBA")
        if "mask" in files:
            mask = Image.open(io.BytesIO(files["mask"][0][1]))
            if mask.size != base.size:
                raise Refusal(400, "invalid_request_error",
                              f"The mask must be the same size as the image: the image is "
                              f"{base.size[0]}x{base.size[1]} and the mask {mask.size[0]}x{mask.size[1]}.", "mask")
            if mask.mode != "RGBA":
                raise Refusal(400, "invalid_request_error", "The mask must have an alpha channel.", "mask")
            hole = mask.getchannel("A").point(lambda a: 255 if a == 0 else 0)
            grey = Image.new("RGBA", base.size, (128, 128, 128, 255))
            base = Image.composite(grey, base, hole)
            record["masked_pixels"] = int(np.count_nonzero(np.asarray(hole)))
        lines = textwrap.wrap(fields.get("prompt", ""), 50)[:6] + ["the grey area is what an edit would repaint"]
        raw = encode(card(base.size, lines, base), "png")
        record.update(model=fields["model"], prompt=fields.get("prompt"), size="%dx%d" % base.size)
        self.send_json(200, {"created": int(time.time()), "data": [{"b64_json": base64.b64encode(raw).decode()}]})

    # -- OpenAI: audio
    def listen(self, translate, fields, files, record):
        name = fields.get("model")
        if name not in WHISPER:
            raise Refusal(404, "invalid_request_error", f"The model `{name}` does not exist", "model")
        if "file" not in files:
            raise Refusal(400, "invalid_request_error", "file is required", "file")
        filename, raw = files["file"][0]
        ext = filename.rsplit(".", 1)[-1].lower()
        if ext not in AUDIO_TYPES:
            raise Refusal(400, "invalid_request_error",
                          f"Invalid file format. Supported formats: {sorted(AUDIO_TYPES)}", "file")
        if len(raw) > UPLOAD_LIMIT:
            raise Refusal(413, "invalid_request_error",
                          f"Maximum content size limit ({UPLOAD_LIMIT}) exceeded ({len(raw)} bytes read)")
        with tempfile.NamedTemporaryFile(suffix="." + ext) as f:
            f.write(raw)
            f.flush()
            samples = mmlab.read_audio(f.name)
        language = "" if translate else fields.get("language", "")
        rec = model("whisper", WHISPER[name], language, "translate" if translate else "transcribe")
        segments, lang = [], ""
        for k, (s, e) in enumerate(mmlab.speech_segments(samples)):
            text, lang = mmlab.transcribe(rec, samples[int(s * mmlab.RATE):int(e * mmlab.RATE)])
            segments.append({"id": k, "start": round(s, 2), "end": round(e, 2), "text": text})
        text = " ".join(x["text"] for x in segments)
        duration = round(len(samples) / mmlab.RATE, 2)
        fmt = fields.get("response_format", "json")
        record.update(model=name, file=filename, bytes=len(raw), duration=duration, response_format=fmt,
                      language=fields.get("language"), prompt=fields.get("prompt"), segments=len(segments))
        if fmt == "json":
            return self.send_json(200, {"text": text})
        if fmt == "text":
            return self.send(200, (text + "\n").encode(), "text/plain; charset=utf-8")
        if fmt == "verbose_json":
            return self.send_json(200, {"task": "translate" if translate else "transcribe",
                                        "language": {"en": "english", "pt": "portuguese"}.get(lang, lang),
                                        "duration": duration, "text": text, "segments": segments})
        if fmt in ("srt", "vtt"):
            def ts(t, sep):
                ms = int(round(t * 1000))
                return "%02d:%02d:%02d%s%03d" % (ms // 3600000, ms // 60000 % 60, ms // 1000 % 60, sep, ms % 1000)
            out = ["WEBVTT", ""] if fmt == "vtt" else []
            for k, x in enumerate(segments, 1):
                sep = "." if fmt == "vtt" else ","
                out += ([] if fmt == "vtt" else [str(k)]) + [f"{ts(x['start'], sep)} --> {ts(x['end'], sep)}", x["text"], ""]
            return self.send(200, "\n".join(out).encode(), "text/plain; charset=utf-8")
        raise Refusal(400, "invalid_request_error", f"Invalid response_format: {fmt}", "response_format")

    def speak(self, req, record):
        if req.get("model") != "lab-tts-1":
            raise Refusal(404, "invalid_request_error", f"The model `{req.get('model')}` does not exist", "model")
        text = req.get("input") or ""
        if not text.strip():
            raise Refusal(400, "invalid_request_error", "input is required", "input")
        if len(text) > 4096:
            raise Refusal(400, "invalid_request_error",
                          f"[{{'type': 'string_too_long', 'loc': ('body', 'input'), 'msg': 'String should have "
                          f"at most 4096 characters'}}] ({len(text)} given)", "input")
        voice = req.get("voice")
        if voice not in VOICES:
            raise Refusal(400, "invalid_request_error",
                          f"Invalid voice '{voice}'. labmm has: {', '.join(sorted(VOICES))}", "voice")
        speed = float(req.get("speed") or 1.0)
        if not 0.25 <= speed <= 4.0:
            raise Refusal(400, "invalid_request_error", "speed must be between 0.25 and 4.0", "speed")
        fmt = req.get("response_format") or "mp3"
        if fmt not in SPEECH_FORMATS:
            raise Refusal(400, "invalid_request_error", f"Invalid response_format: {fmt}", "response_format")
        tts = model("piper", VOICES[voice])
        a = tts.generate(text, sid=0, speed=speed)
        samples = (np.clip(np.asarray(a.samples), -1, 1) * 32767).astype("<i2").tobytes()
        container, codec, ctype = SPEECH_FORMATS[fmt]
        out = subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-f", "s16le", "-ar", str(a.sample_rate),
                              "-ac", "1", "-i", "-", *codec, "-map_metadata", "-1", "-fflags", "+bitexact",
                              "-f", container, "-"], input=samples, capture_output=True, check=True).stdout
        record.update(model=req["model"], voice=voice, characters=len(text), speed=speed,
                      response_format=fmt, seconds_of_audio=round(len(a.samples) / a.sample_rate, 2),
                      bytes=len(out))
        self.send(200, out, ctype)

    # -- Google
    def gemini(self, path, req, record):
        m = re.match(r"/v1beta/models/([^:]+):generateContent$", path)
        if not m:
            raise Refusal(404, "not_found", f"Not found: {path}")
        name = m.group(1)
        if name != "lab-flash-image":
            raise Refusal(404, "not_found", f"models/{name} is not found")
        texts, images, n_in = [], [], 0
        for c in req.get("contents") or []:
            for p in c.get("parts", []):
                if "text" in p:
                    texts.append(p["text"])
                    n_in += text_tokens(p["text"])
                blob = p.get("inlineData") or p.get("inline_data")
                if blob:
                    img = load_image("data:%s;base64,%s" % (blob.get("mimeType") or blob.get("mime_type"), blob["data"]))
                    img["tokens"] = gemini_tokens(img["width"], img["height"])
                    images.append(img)
                    n_in += img["tokens"]
        cfg = req.get("generationConfig") or req.get("generation_config") or {}
        modalities = [x.upper() for x in cfg.get("responseModalities") or cfg.get("response_modalities") or ["TEXT"]]
        reply, rule = scripted(texts, images, False)
        parts = [{"text": reply}]
        out_images = 0
        if "IMAGE" in modalities:
            base = Image.open(io.BytesIO(base64.b64decode(
                ((req["contents"][-1]["parts"][0].get("inlineData") or req["contents"][-1]["parts"][0].get("inline_data") or {}).get("data") or "")))) \
                if images else None
            img = card((1024, 1024), textwrap.wrap(" ".join(texts), 60)[:8], base)
            parts.append({"inlineData": {"mimeType": "image/png",
                                         "data": base64.b64encode(encode(img, "png")).decode()}})
            out_images = 1
        n_out = text_tokens(reply) + 1290 * out_images
        record.update(model=name, rule=rule, images=[{"width": i["width"], "height": i["height"],
                                                       "tokens": i["tokens"]} for i in images],
                      usage={"promptTokenCount": n_in, "candidatesTokenCount": n_out})
        self.send_json(200, {"candidates": [{"content": {"role": "model", "parts": parts},
                                             "finishReason": "STOP", "index": 0}],
                             "usageMetadata": {"promptTokenCount": n_in, "candidatesTokenCount": n_out,
                                               "totalTokenCount": n_in + n_out},
                             "modelVersion": name, "responseId": "resp_lab_%04d" % self.n})


def main():
    host, port = "127.0.0.1", int(os.environ.get("LABMM_PORT", "8700"))
    srv = ThreadingHTTPServer((host, port), Handler)
    srv.daemon_threads = True
    print(f"labmm listening on http://{host}:{port}", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
