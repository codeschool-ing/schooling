---
title: Os dois módulos que toda aula importa, e a mídia
version: 1
---

Dois arquivos vão para o `~/mm` antes que qualquer aula possa rodar. Um sabe onde estão os modelos; o outro faz toda imagem, gravação e vídeo com que o curso trabalha. Os dois estão impressos aqui inteiros: copie cada um num arquivo com esse nome no `~/mm`.

`mmlab.py`:

```python
"""mmlab: where the course's models are, and the few lines each one takes to load.

Every program in the lessons imports what it needs from here, so that a
listing shows what the program DOES with a model rather than the paths to its
files. Nothing in this module changes what a model says: it loads it with the
settings named below and hands it over.
"""
import os
import subprocess

import numpy as np
import sherpa_onnx

SHARE = os.environ.get("MM_SHARE", "/opt/multimodal/share")
RATE = 16000


def read_audio(path, rate=RATE):
    """Any file ffmpeg can open, as mono float samples at `rate` per second."""
    raw = subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-i", path, "-f", "f32le",
                          "-ac", "1", "-ar", str(rate), "-"], check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32)


def whisper(size="base", language="", task="transcribe", int8=True):
    """OpenAI's Whisper, exported to ONNX by sherpa-onnx: `tiny` or `base`, int8 unless asked otherwise."""
    d = os.path.join(SHARE, f"sherpa-onnx-whisper-{size}")
    q = ".int8" if int8 else ""
    return sherpa_onnx.OfflineRecognizer.from_whisper(
        encoder=f"{d}/{size}-encoder{q}.onnx", decoder=f"{d}/{size}-decoder{q}.onnx",
        tokens=f"{d}/{size}-tokens.txt", language=language, task=task, num_threads=2)


def transcribe(recognizer, samples, rate=RATE):
    """One stream, one decode: the text and the language Whisper decided it heard."""
    s = recognizer.create_stream()
    s.accept_waveform(rate, samples)
    recognizer.decode_stream(s)
    return s.result.text.strip(), s.result.lang


def piper(name, noise=False):
    """A Piper voice, such as en_US-lessac-medium. noise=False makes it say a text the same way twice."""
    d = os.path.join(SHARE, f"vits-piper-{name}")
    kw = {} if noise else {"noise_scale": 0.0, "noise_scale_w": 0.0}
    model = sherpa_onnx.OfflineTtsVitsModelConfig(
        model=f"{d}/{name}.onnx", tokens=f"{d}/tokens.txt", data_dir=f"{d}/espeak-ng-data", **kw)
    return sherpa_onnx.OfflineTts(sherpa_onnx.OfflineTtsConfig(
        model=sherpa_onnx.OfflineTtsModelConfig(vits=model, num_threads=2)))


def speech_segments(samples, rate=RATE, min_silence=0.25, min_speech=0.25):
    """Silero VAD over the whole recording: a list of (start, end) in seconds."""
    cfg = sherpa_onnx.VadModelConfig()
    cfg.silero_vad.model = os.path.join(SHARE, "silero_vad.onnx")
    cfg.silero_vad.min_silence_duration = min_silence
    cfg.silero_vad.min_speech_duration = min_speech
    cfg.sample_rate = rate
    vad = sherpa_onnx.VoiceActivityDetector(cfg, buffer_size_in_seconds=len(samples) / rate + 1)
    window = cfg.silero_vad.window_size
    out = []
    for i in range(0, len(samples), window):
        vad.accept_waveform(samples[i:i + window])
        while not vad.empty():
            out.append((vad.front.start / rate, (vad.front.start + len(vad.front.samples)) / rate))
            vad.pop()
    vad.flush()
    while not vad.empty():
        out.append((vad.front.start / rate, (vad.front.start + len(vad.front.samples)) / rate))
        vad.pop()
    return out


def diarizer(threshold=0.5, speakers=-1):
    """pyannote's segmentation 3.0 and 3D-Speaker's ERes2Net embeddings, clustered."""
    seg = sherpa_onnx.OfflineSpeakerSegmentationModelConfig(
        pyannote=sherpa_onnx.OfflineSpeakerSegmentationPyannoteModelConfig(
            model=os.path.join(SHARE, "sherpa-onnx-pyannote-segmentation-3-0", "model.onnx")))
    emb = sherpa_onnx.SpeakerEmbeddingExtractorConfig(
        model=os.path.join(SHARE, "3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx"))
    return sherpa_onnx.OfflineSpeakerDiarization(sherpa_onnx.OfflineSpeakerDiarizationConfig(
        segmentation=seg, embedding=emb,
        clustering=sherpa_onnx.FastClusteringConfig(num_clusters=speakers, threshold=threshold),
        min_duration_on=0.3, min_duration_off=0.5))


def denoiser():
    """GTCRN, a speech enhancement model of 48 thousand parameters."""
    return sherpa_onnx.OfflineSpeechDenoiser(sherpa_onnx.OfflineSpeechDenoiserConfig(
        model=sherpa_onnx.OfflineSpeechDenoiserModelConfig(
            gtcrn=sherpa_onnx.OfflineSpeechDenoiserGtcrnModelConfig(
                model=os.path.join(SHARE, "gtcrn_simple.onnx")))))


def detector(score=0.3):
    """MediaPipe's object detector with EfficientDet-Lite0, trained on the 80 classes of COCO."""
    from mediapipe.tasks.python import BaseOptions
    from mediapipe.tasks.python import vision
    return vision.ObjectDetector.create_from_options(vision.ObjectDetectorOptions(
        base_options=BaseOptions(model_asset_path=os.path.join(SHARE, "efficientdet_lite0.tflite")),
        score_threshold=score))
```

Oito funções curtas, e todo programa do curso importa modelos delas. Cada uma sabe onde estão os arquivos do seu modelo e o carrega com as configurações de que as aulas precisam, para que um programa da aula 5 mostre o que *faz* com o modelo, e não quatro linhas de caminhos. **Uma configuração importa mais que as outras**: o `piper()` desliga a aleatoriedade da própria voz a menos que se peça, o que a faz dizer uma frase do mesmo jeito duas vezes. A aula 6 mostra o que acontece sem isso, e este módulo seria inútil para o curso sem isso, por causa do próximo arquivo.

`make_media.py`:

```python
"""make_media: every picture, recording and video the lessons work on, made from the specifications below.

Nothing here was photographed or recorded. Piper voices speak the words, Pillow
draws the pages and slides, ffmpeg mixes, cuts and encodes. What that buys is
the one thing a real recording never has: the truth is known. Who spoke when,
every word they said, every character on the invoice. It goes into media/truth.

    python make_media.py        writes media/ and media/truth/ in this directory

Piper runs with noise_scale and noise_scale_w at 0, so the same text always
makes the same file (lesson 6 shows why that matters).
"""
import json
import os
import shutil
import subprocess

import numpy as np
import soundfile as sf
from PIL import Image, ImageDraw, ImageFilter, ImageFont

import mmlab

CALL = {
    "about": "A support call to Marginalia about order M-1042, written for the course. Caio answers for the shop and Bia is the customer; neither exists. Each turn is spoken by one Piper voice and the gap after it is silence.",
    "voices": {"caio": "en_GB-alan-medium", "bia": "en_US-lessac-medium"},
    "turns": [
        {"who": "caio", "gap": 0.7, "text": "Good morning, you're through to Marginalia support. My name is Caio. How can I help?"},
        {"who": "bia", "gap": 0.5, "text": "Hi Caio. I'm calling about order M-1042. It's a copy of Dom Casmurro, by Machado de Assis, and it arrived on the twenty-fourth of September."},
        {"who": "caio", "gap": 0.9, "text": "Let me pull that up. Yes, I can see it here. One copy of Dom Casmurro, delivered on the twenty-fourth. What seems to be the problem?"},
        {"who": "bia", "gap": 0.6, "text": "The cover is torn, and about ten pages are folded at the corner. I'd like to send it back."},
        {"who": "caio", "gap": 0.8, "text": "I'm sorry to hear that. You're well within the thirty-day window, so you can return it free of charge. I'll email you a prepaid label."},
        {"who": "bia", "gap": 0.4, "text": "Great. Will I get the shipping back as well?"},
        {"who": "caio", "gap": 0.7, "text": "Yes. For a damaged book we refund the full thirty-four eighty, shipping included, as soon as the parcel reaches us."},
        {"who": "bia", "gap": 0.5, "text": "Perfect, thank you."},
        {"who": "caio", "gap": 0.0, "text": "Thank you for calling Marginalia. Have a good day."},
    ],
}
VOICEMAIL = {
    "about": "A voicemail in Brazilian Portuguese, written for the course. Rafael does not exist.",
    "voices": {"rafael": "pt_BR-faber-medium"},
    "turns": [
        {"who": "rafael", "gap": 0.0, "text": "Oi, aqui é o Rafael, cliente da Marginalia. Estou ligando sobre o pedido M-2087, um exemplar de Memórias Póstumas de Brás Cubas que chegou com a capa amassada. Vocês podem me ligar de volta no fim da tarde? Obrigado."},
    ],
}
VIDEO = {
    "about": "Marginalia's 'How to return a book' video, written for the course: six slides and a narration spoken by one Piper voice. Slide 3 and slide 6 show things the narration does not say, and a 0.4-second card between slides 4 and 5 is said by nobody at all. Both are on purpose, for lessons 4 and 14.",
    "voice": "en_US-lessac-medium",
    "size": [1280, 720],
    "fps": 25,
    "slides": [
        {"title": "Returning a book to Marginalia", "lines": ["Four steps and a free label"], "say": "Here is how to return a book you bought from Marginalia. It takes four steps, and the label is free."},
        {"title": "1. Open the order", "lines": ["Account  >  Orders  >  M-1042", "Find the order the book came in"], "say": "First, sign in and open the order the book came in. You will find it under Account, then Orders."},
        {"title": "2. Choose a reason", "lines": ["( ) Damaged in transit", "( ) Wrong book sent", "( ) Changed my mind"], "say": "Second, press Return this item and choose a reason from the list."},
        {"title": "3. Print the label", "lines": ["The prepaid label arrives by e-mail", "Tape it over the old address"], "say": "Third, print the prepaid label we send you by e-mail, and tape it over the old address."},
        {"flash": True, "seconds": 0.4, "title": "Code: RETURN30", "lines": ["Quote it if you call us"]},
        {"title": "4. Drop it off", "lines": ["Any post office", "Keep the receipt"], "say": "Fourth, drop the parcel at any post office, and keep the receipt until your refund arrives."},
        {"title": "Refunds", "lines": ["Within 30 days of delivery", "Damaged books: refunded in full", "The label is valid for 7 days"], "say": "Refunds go back to the card you paid with. A damaged book is refunded in full, shipping included."},
    ],
}
INVOICE = {
    "about": "A supplier's invoice to Marginalia, written for the course. Lantern & Quill Distributors does not exist and every address is a made-up one.",
    "supplier": ["Lantern & Quill Distributors", "Rua das Palmeiras 210, Campinas SP", "billing@lanternquill.example.com"],
    "to": ["Marginalia Books", "Av. Exemplo 1000, São Paulo SP"],
    "number": "INV-0931", "date": "2026-09-15", "due": "2026-10-15", "currency": "BRL",
    "lines": [
        {"title": "Dom Casmurro", "qty": 12, "unit": 1850},
        {"title": "The Posthumous Memoirs of Brás Cubas", "qty": 8, "unit": 2100},
        {"title": "Bleak House", "qty": 5, "unit": 3290},
        {"title": "The Secret Garden", "qty": 10, "unit": 1590},
    ],
    "shipping": 4500,
}

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
FFMPEG = ["ffmpeg", "-nostdin", "-loglevel", "error", "-y"]
OUT, TRUTH, WORK = "media", "media/truth", "media/.build"


def speak(tts, text):
    a = tts.generate(text, sid=0, speed=1.0)
    return np.asarray(a.samples, dtype=np.float32), a.sample_rate


def to16k(src, dst):
    subprocess.run(FFMPEG + ["-i", src, "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le",
                             "-map_metadata", "-1", "-fflags", "+bitexact", dst], check=True)


def save_truth(name, obj, text):
    with open(f"{TRUTH}/{name}.json", "w") as f:
        json.dump(obj, f, indent=1, ensure_ascii=False)
        f.write("\n")
    with open(f"{TRUTH}/{name}.txt", "w") as f:
        f.write(text + "\n")


def conversation(spec, name):
    """Turns spoken one after another, with the silence the spec asks for after each."""
    voices = {who: mmlab.piper(v) for who, v in spec["voices"].items()}
    pieces, turns, t, rate = [], [], 0.0, None
    for turn in spec["turns"]:
        a, rate = speak(voices[turn["who"]], turn["text"])
        turns.append({"who": turn["who"], "start": round(t, 3), "end": round(t + len(a) / rate, 3),
                      "text": turn["text"]})
        gap = np.zeros(int(round(turn["gap"] * rate)), dtype=np.float32)
        pieces += [a, gap]
        t += (len(a) + len(gap)) / rate
    raw = f"{WORK}/{name}-raw.wav"
    sf.write(raw, np.concatenate(pieces), rate, subtype="PCM_16")
    to16k(raw, f"{OUT}/{name}.wav")
    save_truth(name, {"about": spec["about"], "voices": spec["voices"], "turns": turns},
               " ".join(x["text"] for x in turns))


def degrade_call():
    """The same call over a bad line: a hum at 60 Hz, a hiss, and the telephone band."""
    clean = f"{OUT}/call-1042.wav"
    subprocess.run(FFMPEG + [
        "-i", clean,
        "-f", "lavfi", "-i", "anoisesrc=color=pink:seed=1042:amplitude=0.35:sample_rate=16000",
        "-f", "lavfi", "-i", "sine=frequency=60:sample_rate=16000",
        "-filter_complex", "[2]volume=0.12[hum];[0][1][hum]amix=inputs=3:duration=first:normalize=0[m]",
        "-map", "[m]", "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le",
        "-map_metadata", "-1", "-fflags", "+bitexact", f"{OUT}/call-1042-noisy.wav"], check=True)
    subprocess.run(FFMPEG + [
        "-i", clean, "-af", "highpass=f=300,lowpass=f=3400", "-ar", "8000", "-ac", "1", "-c:a", "pcm_mulaw",
        "-map_metadata", "-1", "-fflags", "+bitexact", f"{OUT}/call-1042-phone.wav"], check=True)


def slide(s, size):
    w, h = size
    if s.get("flash"):
        img = Image.new("RGB", size, (28, 28, 28))
        d = ImageDraw.Draw(img)
        d.text((w // 2, h // 2 - 30), s["title"], font=ImageFont.truetype(BOLD, 72), fill=(255, 214, 102), anchor="mm")
        d.text((w // 2, h // 2 + 50), s["lines"][0], font=ImageFont.truetype(FONT, 34), fill=(240, 240, 240), anchor="mm")
        return img
    img = Image.new("RGB", size, (250, 248, 242))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w, 14], fill=(47, 111, 78))
    d.text((80, 70), "Marginalia", font=ImageFont.truetype(BOLD, 28), fill=(47, 111, 78))
    d.text((80, 190), s["title"], font=ImageFont.truetype(BOLD, 60), fill=(30, 30, 30))
    for i, line in enumerate(s["lines"]):
        d.text((80, 320 + i * 70), line, font=ImageFont.truetype(FONT, 38), fill=(60, 60, 60))
    return img


def video(spec):
    """Slides held for as long as their narration lasts, encoded as one MP4."""
    tts = mmlab.piper(spec["voice"])
    frame = 1 / spec["fps"]
    audio, rate, listing, slides, t = [], 22050, [], [], 0.0
    for i, s in enumerate(spec["slides"], 1):
        png = os.path.abspath(f"{WORK}/slide-{i}.png")
        slide(s, tuple(spec["size"])).save(png)
        if s.get("flash"):
            a = np.zeros(int(round(s["seconds"] * rate)), dtype=np.float32)
        else:
            a, rate = speak(tts, s["say"])
            a = np.concatenate([np.zeros(int(0.4 * rate), np.float32), a, np.zeros(int(0.6 * rate), np.float32)])
        frames = int(np.ceil(len(a) / rate / frame))
        a = np.concatenate([a, np.zeros(int(round(frames * frame * rate)) - len(a), np.float32)])
        seconds = frames * frame
        audio.append(a)
        listing += [f"file '{png}'", f"duration {seconds:.2f}"]
        slides.append({"slide": i, "start": round(t, 2), "end": round(t + seconds, 2), "title": s["title"],
                       "shown": s["lines"], "said": s.get("say", "")})
        t += seconds
    listing.append(f"file '{png}'")
    with open(f"{WORK}/slides.txt", "w") as f:
        f.write("\n".join(listing) + "\n")
    sf.write(f"{WORK}/narration.wav", np.concatenate(audio), rate, subtype="PCM_16")
    subprocess.run(FFMPEG + [
        "-f", "concat", "-safe", "0", "-i", f"{WORK}/slides.txt", "-i", f"{WORK}/narration.wav",
        "-vf", f"fps={spec['fps']},format=yuv420p", "-c:v", "libx264", "-preset", "medium", "-crf", "23",
        "-threads", "1", "-x264-params", "threads=1",
        "-c:a", "aac", "-b:a", "96k", "-ar", "44100", "-shortest",
        "-map_metadata", "-1", "-fflags", "+bitexact", "-flags", "+bitexact", f"{OUT}/returns.mp4"], check=True)
    save_truth("returns", {"about": spec["about"], "slides": slides},
               " ".join(s["said"] for s in slides if s["said"]))


def money(cents):
    return f"{cents // 100:,}.{cents % 100:02d}"


def invoice(spec):
    """An A4 page at 150 dpi, and the same page as a cheap scanner would return it."""
    w, h = 1240, 1754
    img = Image.new("RGB", (w, h), "white")
    d = ImageDraw.Draw(img)
    big, f, b, m = (ImageFont.truetype(BOLD, 44), ImageFont.truetype(FONT, 24),
                    ImageFont.truetype(BOLD, 24), ImageFont.truetype(MONO, 24))
    lines = []

    def put(xy, text, font, anchor="la"):
        d.text(xy, text, font=font, fill=(20, 20, 20), anchor=anchor)
        lines.append((xy[1], d.textbbox(xy, text, font=font, anchor=anchor)[0], text))
    put((90, 90), spec["supplier"][0], big)
    for i, s in enumerate(spec["supplier"][1:]):
        put((90, 160 + i * 34), s, f)
    put((w - 90, 90), "INVOICE", big, "ra")
    put((w - 90, 160), "Number: " + spec["number"], f, "ra")
    put((w - 90, 194), "Date: " + spec["date"], f, "ra")
    put((w - 90, 228), "Due: " + spec["due"], f, "ra")
    put((90, 330), "Bill to", b)
    for i, s in enumerate(spec["to"]):
        put((90, 370 + i * 34), s, f)
    y = 500
    d.line([90, y, w - 90, y], fill=(20, 20, 20), width=2)
    put((90, y + 20), "Title", b)
    put((800, y + 20), "Qty", b, "ra")
    put((970, y + 20), "Unit", b, "ra")
    put((w - 90, y + 20), "Amount", b, "ra")
    y += 70
    subtotal = 0
    for line in spec["lines"]:
        amount = line["qty"] * line["unit"]
        subtotal += amount
        put((90, y), line["title"], f)
        put((800, y), str(line["qty"]), m, "ra")
        put((970, y), money(line["unit"]), m, "ra")
        put((w - 90, y), money(amount), m, "ra")
        y += 48
    d.line([90, y + 10, w - 90, y + 10], fill=(20, 20, 20), width=1)
    y += 40
    total = subtotal + spec["shipping"]
    for label, value, font in (("Subtotal", subtotal, f), ("Shipping", spec["shipping"], f),
                               ("Total " + spec["currency"], total, b)):
        put((970, y), label, font, "ra")
        put((w - 90, y), money(value), m, "ra")
        y += 44
    put((90, h - 150), "Payment by bank transfer within 30 days. Thank you for your business.", f)
    img.save(f"{OUT}/invoice-0931.png")

    # The scanner: turned 1.8 degrees, blurred, shrunk to 100 dpi, grainy, and saved as a poor JPEG.
    scan = img.convert("L").rotate(1.8, resample=Image.BICUBIC, expand=False, fillcolor=255)
    scan = scan.filter(ImageFilter.GaussianBlur(1.1)).resize((827, 1170), Image.BILINEAR)
    rng = np.random.default_rng(931)
    a = np.asarray(scan, dtype=np.float32) + rng.normal(0, 14, (1170, 827))
    a = np.clip(a * 0.92 + 12, 0, 255).astype(np.uint8)
    Image.fromarray(a, "L").save(f"{OUT}/invoice-0931-scan.jpg", quality=45)

    # The text as it is read: row by row, top to bottom, and left to right inside a row.
    rows = {}
    for y, x, text in lines:
        rows.setdefault(y, []).append((x, text))
    save_truth("invoice-0931",
               {"about": spec["about"], "number": spec["number"], "date": spec["date"], "due": spec["due"],
                "supplier": spec["supplier"][0], "currency": spec["currency"],
                "lines": [dict(x, amount=x["qty"] * x["unit"]) for x in spec["lines"]],
                "subtotal": subtotal, "shipping": spec["shipping"], "total": total},
               "\n".join(" ".join(t for _, t in sorted(rows[y])) for y in sorted(rows)))


def cover():
    """The cover Marginalia's own edition of Dom Casmurro would have, if it existed."""
    img = Image.new("RGB", (600, 900), (31, 45, 74))
    d = ImageDraw.Draw(img)
    d.ellipse([380, 90, 500, 210], fill=(238, 226, 190))
    d.rectangle([150, 380, 450, 760], fill=(18, 26, 44))
    d.rectangle([180, 410, 290, 560], fill=(214, 168, 76))
    d.rectangle([310, 410, 420, 560], fill=(214, 168, 76))
    d.line([150, 760, 450, 760], fill=(238, 226, 190), width=4)
    d.text((300, 270), "DOM CASMURRO", font=ImageFont.truetype(SERIF, 54), fill=(238, 226, 190), anchor="mm")
    d.text((300, 330), "Machado de Assis", font=ImageFont.truetype(FONT, 30), fill=(238, 226, 190), anchor="mm")
    d.text((300, 830), "Marginalia Classics", font=ImageFont.truetype(FONT, 22), fill=(170, 180, 200), anchor="mm")
    img.save(f"{OUT}/cover-b39.png")


if __name__ == "__main__":
    os.makedirs(TRUTH, exist_ok=True)
    os.makedirs(WORK, exist_ok=True)
    conversation(CALL, "call-1042")
    degrade_call()
    conversation(VOICEMAIL, "voicemail-pt")
    video(VIDEO)
    invoice(INVOICE)
    cover()
    shutil.copy(os.path.join(mmlab.SHARE, "cat_and_dog.jpg"), OUT)
    shutil.rmtree(WORK)
    for name in sorted(os.listdir(OUT)):
        if os.path.isfile(f"{OUT}/{name}"):
            print(f"{name:24} {os.path.getsize(f'{OUT}/{name}'):>9,} bytes")
```

**Nada na mídia do curso foi fotografado ou gravado.** Este programa escreve os roteiros e os layouts no topo e faz tudo a partir deles: as vozes do Piper falam a ligação de suporte e o recado, o ffmpeg estraga uma cópia da ligação com um zumbido e um chiado e espreme outra por uma linha telefônica, o Pillow desenha uma nota fiscal, uma capa de livro e seis slides, e o ffmpeg junta os slides e uma narração num vídeo. A única exceção é o `cat_and_dog.jpg`, uma fotografia dos próprios exemplos do MediaPipe, que o `setup.sh` baixou.

O que isso compra é o que uma gravação de verdade nunca tem: **a verdade é conhecida**. Cada palavra da ligação e quem a disse, quando cada slide está na tela, cada caractere da nota. O `make_media.py` escreve tudo isso em `media/truth`, e a maioria das aulas mede um modelo contra isso. Rode-o no `~/mm`:

```
ana@lab:~/mm$ python make_media.py
call-1042-noisy.wav      1,772,316 bytes
call-1042-phone.wav        443,126 bytes
call-1042.wav            1,772,316 bytes
cat_and_dog.jpg             69,041 bytes
cover-b39.png               19,605 bytes
invoice-0931-scan.jpg       95,891 bytes
invoice-0931.png            87,530 bytes
returns.mp4                495,585 bytes
voicemail-pt.wav           399,120 bytes
ana@lab:~/mm$ ls media/truth
call-1042.json
call-1042.txt
invoice-0931.json
invoice-0931.txt
returns.json
returns.txt
voicemail-pt.json
voicemail-pt.txt
ana@lab:~/mm$ python -c "import json; print(json.load(open(\"media/truth/call-1042.json\"))[\"turns\"][1])"
{'who': 'bia', 'start': 6.014, 'end': 14.475, 'text': "Hi Caio. I'm calling about order M-1042. It's a copy of Dom Casmurro, by Machado de Assis, and it arrived on the twenty-fourth of September."}
```

Os mesmos nove arquivos, byte a byte, em toda máquina que o rode com as bibliotecas que o `setup.sh` fixou: as vozes não têm mais aleatoriedade, o ruído do escaneado vem de um gerador com semente, e o ffmpeg é instruído a deixar de fora tudo o que muda entre execuções, como a hora em que um arquivo foi feito. É por isso que as transcrições deste curso podem citar a saída de um modelo e esperar que a sua bata. Se um tamanho acima for diferente na sua máquina, a próxima seção diz onde olhar.

## A primeira imagem do modelo de visão

Uma última conferência, e o primeiro uso de verdade do modelo que lê imagens. O `ollama run` recebe uma pergunta e o caminho de uma imagem na mesma linha:

```
ana@lab:~/mm$ ollama run qwen2.5vl:3b "What text is on this book cover? ./media/cover-b39.png" 2>/dev/null
The text on the book cover is:

DOM CASMURRO
Machado de Assis
Marginalia Classics

ana@lab:~/mm$ ollama ps
NAME            ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
qwen2.5vl:3b    fb90415cde1e    3.2 GB    39%/61% CPU/GPU    4096       llamacpp    4 minutes from now    
ana@lab:~/mm$ ollama list; du -sh ~/.ollama/models
NAME                                                                         ID              SIZE      MODIFIED           
qwen2.5vl:3b                                                                 79d497978752    3.2 GB    45 seconds ago        
qwen2.5vl:3b                                                                 875648b722f9    3.2 GB    45 seconds ago        
llamacpp:79d4979787523c92629bc043c0584a5132d6758e40b429586203a6b1094cb6f8    79d497978752    3.2 GB    45 seconds ago        
all-minilm:latest                                                            1b226e2802db    45 MB     About a minute ago    
llama3.2:3b                                                                  a80c4f17acd5    2.0 GB    About a minute ago    
7.9G	/home/ana/.ollama/models
```

As três linhas de texto, exatamente como foram desenhadas. O `ollama ps` mostra o modelo ainda carregado, usando 3,2 GB de memória, e ele continua carregado por cinco minutos depois da última resposta, para que a próxima pergunta não espere por ele de novo. A última listagem é a surpresa: **na primeira vez que o Ollama 0.40 roda o `qwen2.5vl:3b`, ele o converte para o motor com que o roda, e guarda o resultado**, mais duas linhas na lista e mais três gigabytes no disco. Isso acontece uma vez. Se o seu Ollama for mais novo, a lista pode ser diferente; a resposta não deveria.
