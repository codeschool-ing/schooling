"""build_media: every picture, recording and video the lessons work on.

NOTHING HERE WAS PHOTOGRAPHED OR RECORDED. The lab builds each file from a
specification in lab/media/*.json that the course wrote, with the same tools a
student has: Piper voices speak the words, Pillow draws the pages and slides,
ffmpeg mixes, cuts and encodes. What that buys is the one thing a real
recording never has: THE TRUTH IS KNOWN. Who spoke when, every word they said,
every character on the invoice. The lessons measure a model against it, and
the truth goes into ~/media/truth beside the files.

The one exception is cat_and_dog.jpg, a photograph from MediaPipe's own
examples, fetched by lab.sh and pinned by its SHA-256.

    python build_media.py SPECS OUT     SPECS is lab/media, OUT is ~/media

Piper is run with noise_scale and noise_scale_w at 0. At their defaults the
same sentence comes out as a different file each time (lesson 6 shows it), and
a lab whose recordings move cannot be quoted.
"""
import json
import os
import shutil
import subprocess
import sys

import numpy as np
import sherpa_onnx
import soundfile as sf
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SHARE = os.environ.get("MM_SHARE", "/opt/multimodal/share")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
FFMPEG = ["ffmpeg", "-nostdin", "-loglevel", "error", "-y"]


def voice(name):
    d = os.path.join(SHARE, "vits-piper-" + name)
    model = sherpa_onnx.OfflineTtsVitsModelConfig(
        model=f"{d}/{name}.onnx", tokens=f"{d}/tokens.txt", data_dir=f"{d}/espeak-ng-data",
        noise_scale=0.0, noise_scale_w=0.0)
    cfg = sherpa_onnx.OfflineTtsConfig(model=sherpa_onnx.OfflineTtsModelConfig(vits=model, num_threads=2))
    return sherpa_onnx.OfflineTts(cfg)


def speak(tts, text):
    a = tts.generate(text, sid=0, speed=1.0)
    return np.asarray(a.samples, dtype=np.float32), a.sample_rate


def to16k(src, dst, extra=()):
    subprocess.run(FFMPEG + ["-i", src, *extra, "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le",
                             "-map_metadata", "-1", "-fflags", "+bitexact", dst], check=True)


def conversation(spec, out, truth, name):
    """Turns spoken one after another, with the silence the spec asks for after each."""
    voices = {who: voice(v) for who, v in spec["voices"].items()}
    pieces, turns, t, rate = [], [], 0.0, None
    for turn in spec["turns"]:
        a, rate = speak(voices[turn["who"]], turn["text"])
        turns.append({"who": turn["who"], "start": round(t, 3), "end": round(t + len(a) / rate, 3),
                      "text": turn["text"]})
        gap = np.zeros(int(round(turn["gap"] * rate)), dtype=np.float32)
        pieces += [a, gap]
        t += (len(a) + len(gap)) / rate
    raw = os.path.join(out, f".{name}-raw.wav")
    sf.write(raw, np.concatenate(pieces), rate, subtype="PCM_16")
    to16k(raw, os.path.join(out, f"{name}.wav"))
    os.remove(raw)
    with open(os.path.join(truth, f"{name}.json"), "w") as f:
        json.dump({"about": spec["about"], "voices": spec["voices"], "turns": turns}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    with open(os.path.join(truth, f"{name}.txt"), "w") as f:
        f.write(" ".join(x["text"] for x in turns) + "\n")


def degrade_call(out):
    """The same call over a bad line: a hum at 60 Hz, a hiss, and the telephone band."""
    clean = os.path.join(out, "call-1042.wav")
    subprocess.run(FFMPEG + [
        "-i", clean,
        "-f", "lavfi", "-i", "anoisesrc=color=pink:seed=1042:amplitude=0.06:sample_rate=16000",
        "-f", "lavfi", "-i", "sine=frequency=60:sample_rate=16000",
        "-filter_complex",
        "[2]volume=0.05[hum];[0][1][hum]amix=inputs=3:duration=first:normalize=0[m]",
        "-map", "[m]", "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le",
        "-map_metadata", "-1", "-fflags", "+bitexact", os.path.join(out, "call-1042-noisy.wav")], check=True)
    subprocess.run(FFMPEG + [
        "-i", clean, "-af", "highpass=f=300,lowpass=f=3400", "-ar", "8000", "-ac", "1", "-c:a", "pcm_mulaw",
        "-map_metadata", "-1", "-fflags", "+bitexact", os.path.join(out, "call-1042-phone.wav")], check=True)


# ---------------------------------------------------------------- pictures

def slide(s, size):
    w, h = size
    img = Image.new("RGB", size, (250, 248, 242))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w, 14], fill=(47, 111, 78))
    d.text((80, 70), "Marginalia", font=ImageFont.truetype(BOLD, 28), fill=(47, 111, 78))
    if s.get("flash"):
        img = Image.new("RGB", size, (28, 28, 28))
        d = ImageDraw.Draw(img)
        d.text((w // 2, h // 2 - 30), s["title"], font=ImageFont.truetype(BOLD, 72), fill=(255, 214, 102), anchor="mm")
        d.text((w // 2, h // 2 + 50), s["lines"][0], font=ImageFont.truetype(FONT, 34), fill=(240, 240, 240), anchor="mm")
        return img
    d.text((80, 190), s["title"], font=ImageFont.truetype(BOLD, 60), fill=(30, 30, 30))
    f = ImageFont.truetype(FONT, 38)
    for i, line in enumerate(s["lines"]):
        d.text((80, 320 + i * 70), line, font=f, fill=(60, 60, 60))
    return img


def video(spec, out, truth, work):
    tts = voice(spec["voice"])
    fps, size = spec["fps"], tuple(spec["size"])
    frame = 1 / fps
    audio, rate, listing, slides, t = [], None, [], [], 0.0
    for i, s in enumerate(spec["slides"], 1):
        png = os.path.join(work, f"slide-{i}.png")
        slide(s, size).save(png)
        if s.get("flash"):
            a = np.zeros(int(round(s["seconds"] * 22050)), dtype=np.float32)
            rate = rate or 22050
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
    with open(os.path.join(work, "slides.txt"), "w") as f:
        f.write("\n".join(listing) + "\n")
    wav = os.path.join(work, "narration.wav")
    sf.write(wav, np.concatenate(audio), rate, subtype="PCM_16")
    subprocess.run(FFMPEG + [
        "-f", "concat", "-safe", "0", "-i", os.path.join(work, "slides.txt"), "-i", wav,
        "-vf", f"fps={fps},format=yuv420p", "-c:v", "libx264", "-preset", "medium", "-crf", "23",
        "-threads", "1", "-x264-params", "threads=1",
        "-c:a", "aac", "-b:a", "96k", "-ar", "44100", "-shortest",
        "-map_metadata", "-1", "-fflags", "+bitexact", "-flags", "+bitexact",
        os.path.join(out, "returns.mp4")], check=True)
    with open(os.path.join(truth, "returns.json"), "w") as f:
        json.dump({"about": spec["about"], "slides": slides}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    with open(os.path.join(truth, "returns.txt"), "w") as f:
        f.write(" ".join(s["said"] for s in slides if s["said"]) + "\n")


def money(cents):
    return f"{cents // 100:,}.{cents % 100:02d}"


def invoice(spec, out, truth):
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
    img.save(os.path.join(out, "invoice-0931.png"))

    scan = img.convert("L").rotate(1.8, resample=Image.BICUBIC, expand=False, fillcolor=255)
    scan = scan.filter(ImageFilter.GaussianBlur(1.1)).resize((827, 1170), Image.BILINEAR)
    rng = np.random.default_rng(931)
    a = np.asarray(scan, dtype=np.float32) + rng.normal(0, 14, (1170, 827))
    a = np.clip(a * 0.92 + 12, 0, 255).astype(np.uint8)
    Image.fromarray(a, "L").save(os.path.join(out, "invoice-0931-scan.jpg"), quality=45)

    with open(os.path.join(truth, "invoice-0931.json"), "w") as fh:
        json.dump({"about": spec["about"], "number": spec["number"], "date": spec["date"], "due": spec["due"],
                   "supplier": spec["supplier"][0], "currency": spec["currency"],
                   "lines": [dict(x, amount=x["qty"] * x["unit"]) for x in spec["lines"]],
                   "subtotal": subtotal, "shipping": spec["shipping"], "total": total}, fh, indent=1,
                  ensure_ascii=False)
        fh.write("\n")
    # The text as it is read: row by row, top to bottom, and left to right
    # inside a row. Two pieces of text share a row when they sit at one height.
    rows = {}
    for y, x, text in lines:
        rows.setdefault(y, []).append((x, text))
    with open(os.path.join(truth, "invoice-0931.txt"), "w") as fh:
        fh.write("\n".join(" ".join(t for _, t in sorted(rows[y])) for y in sorted(rows)) + "\n")


def cover(out):
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
    img.save(os.path.join(out, "cover-b39.png"))


def main():
    specs, out = sys.argv[1], sys.argv[2]
    truth = os.path.join(out, "truth")
    work = os.path.join(out, ".build")
    os.makedirs(truth, exist_ok=True)
    os.makedirs(work, exist_ok=True)
    load = lambda n: json.load(open(os.path.join(specs, n)))
    conversation(load("call-1042.json"), out, truth, "call-1042")
    degrade_call(out)
    conversation(load("voicemail-pt.json"), out, truth, "voicemail-pt")
    video(load("returns-video.json"), out, truth, work)
    invoice(load("invoice-0931.json"), out, truth)
    cover(out)
    shutil.copy(os.path.join(SHARE, "cat_and_dog.jpg"), out)
    shutil.rmtree(work)


if __name__ == "__main__":
    main()
