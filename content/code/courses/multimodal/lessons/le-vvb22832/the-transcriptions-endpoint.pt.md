---
title: O endpoint de transcrição
version: 1
---

A API de fala para texto da OpenAI é uma chamada: **envie um arquivo, diga um modelo, receba texto de volta**. O arquivo vai como upload de formulário multipart, não como JSON, e o SDK esconde isso.

As chamadas desta aula vão para um servidor na sua própria máquina, e não para a OpenAI, pelo motivo que a aula 1 deu: sem chave, sem conta. Ele responde às duas rotas de fala da OpenAI com o Whisper que você já tem, base e tiny, cortado nos silêncios pelo detector de fala exatamente como nas aulas 5 e 7, e recebe o upload e dá a resposta nos formatos que a OpenAI documenta. Os modelos são reais; o servidor em volta deles é do curso.

`audio_server.py`:

```python
"""audio_server: OpenAI's two speech-to-text routes on localhost:8700, answered by the course's own Whisper.

    POST /v1/audio/transcriptions    the speech, written down in its own language
    POST /v1/audio/translations      the speech, written down in English

The models are real: Whisper tiny or base, the same int8 exports lesson 7
measured, after Silero has cut the recording at its silences. What is the
course's own is the server around them, which takes the upload the way OpenAI
documents it (a form with a file, a model and options) and answers in the same
five shapes. Each request is written to audio_server.log, one JSON line.
"""
import json
import tempfile
import time
from email.parser import BytesParser
from email.policy import HTTP
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import mmlab

MODELS = {"whisper-tiny": "tiny", "whisper-base": "base"}
TYPES = ["flac", "m4a", "mp3", "mp4", "mpeg", "mpga", "ogg", "wav", "webm"]   # the formats OpenAI accepts
LIMIT = 25 * 1024 * 1024                                                      # and its limit per upload
LOADED = {}


class Refused(Exception):
    def __init__(self, status, message):
        super().__init__(message)
        self.status, self.message = status, message


def stamp(t, sep):
    ms = round(t * 1000)
    return "%02d:%02d:%02d%s%03d" % (ms // 3600000, ms // 60000 % 60, ms // 1000 % 60, sep, ms % 1000)


def listen(task, fields, name, raw):
    if fields.get("model") not in MODELS:
        raise Refused(404, f"The model `{fields.get('model')}` does not exist; this server has " + ", ".join(MODELS))
    if name.rsplit(".", 1)[-1].lower() not in TYPES:
        raise Refused(400, f"Invalid file format. Supported formats: {TYPES}")
    with tempfile.NamedTemporaryFile(suffix="-" + name) as f:
        f.write(raw)
        f.flush()
        samples = mmlab.read_audio(f.name)
    language = fields.get("language", "") if task == "transcribe" else ""
    key = (fields["model"], language, task)
    if key not in LOADED:
        LOADED[key] = mmlab.whisper(MODELS[fields["model"]], language=language, task=task)
    segments, lang = [], ""
    for i, (start, end) in enumerate(mmlab.speech_segments(samples)):
        text, lang = mmlab.transcribe(LOADED[key], samples[int(start * mmlab.RATE):int(end * mmlab.RATE)])
        segments.append({"id": i, "start": round(start, 2), "end": round(end, 2), "text": text})
    # `prompt` is accepted and logged, and goes no further: this export of Whisper has no way to take one.
    text = " ".join(s["text"] for s in segments)
    seconds = round(len(samples) / mmlab.RATE, 2)
    shape = fields.get("response_format", "json")
    if shape == "json":
        body = json.dumps({"text": text})
    elif shape == "text":
        body = text + "\n"
    elif shape == "verbose_json":
        body = json.dumps({"task": task, "language": {"en": "english", "pt": "portuguese"}.get(lang, lang),
                           "duration": seconds, "text": text, "segments": segments})
    elif shape in ("srt", "vtt"):
        sep = "," if shape == "srt" else "."
        cues = [("" if shape == "vtt" else f"{i}\n") + f"{stamp(s['start'], sep)} --> {stamp(s['end'], sep)}\n{s['text']}\n"
                for i, s in enumerate(segments, 1)]
        body = ("WEBVTT\n\n" if shape == "vtt" else "") + "\n".join(cues)
    else:
        raise Refused(400, f"Invalid response_format: {shape}")
    return body, {"seconds_of_audio": seconds, "segments": len(segments), "prompt": fields.get("prompt")}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def answer(self, status, body, kind="application/json"):
        data = body.encode()
        self.send_response(status)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        self.answer(200, json.dumps({"server": "audio_server.py", "models": list(MODELS)}))

    def do_POST(self):
        started, size = time.time(), int(self.headers.get("Content-Length") or 0)
        record = {"path": self.path, "upload": size}
        try:
            if self.path not in ("/v1/audio/transcriptions", "/v1/audio/translations"):
                raise Refused(404, f"no route for POST {self.path}")
            if size > LIMIT:
                self.rfile.read(size)
                raise Refused(413, f"Maximum content size limit ({LIMIT}) exceeded ({size} bytes read)")
            head = f"Content-Type: {self.headers['Content-Type']}\r\n\r\n".encode()
            fields, name, raw = {}, "", b""
            for part in BytesParser(policy=HTTP).parsebytes(head + self.rfile.read(size)).iter_parts():
                if part.get_filename():
                    name, raw = part.get_filename(), part.get_payload(decode=True)
                else:
                    fields[part.get_param("name", header="content-disposition")] = part.get_content()
            record.update(model=fields.get("model"), file=name, bytes=len(raw))
            task = "translate" if self.path.endswith("translations") else "transcribe"
            body, more = listen(task, fields, name, raw)
            record.update(more, status=200)
            kind = "application/json" if fields.get("response_format", "json") in ("json", "verbose_json") else "text/plain"
            self.answer(200, body, kind)
        except Refused as e:
            record.update(status=e.status, error=e.message)
            self.answer(e.status, json.dumps({"error": {"message": e.message, "type": "invalid_request_error"}}))
        record["seconds"] = round(time.time() - started, 2)
        with open("audio_server.log", "a") as log:
            log.write(json.dumps(record) + "\n")


if __name__ == "__main__":
    print("audio_server: Whisper behind OpenAI's audio routes, on http://localhost:8700", flush=True)
    ThreadingHTTPServer(("127.0.0.1", 8700), Handler).serve_forever()
```

Inicie-o num segundo terminal, no `~/mm`, e deixe-o rodando. As aulas 12 a 14 também o usam.

```sh
python audio_server.py
```

Com uma chave sua, os programas abaixo chegam ao `whisper-1` da OpenAI trocando a linha do `base_url` e o nome do modelo; o resto fica como está.

`transcribe.py`:

```python
"""Send a recording to the transcriptions endpoint and print what comes back."""
import sys

from openai import OpenAI

path = sys.argv[1]
fmt = sys.argv[2] if len(sys.argv) > 2 else "json"
client = OpenAI(base_url="http://localhost:8700/v1")   # audio_server.py, on this machine
with open(path, "rb") as audio:
    result = client.audio.transcriptions.create(model="whisper-base", file=audio, response_format=fmt)
print(result.text if fmt == "json" else result)
```

```
ana@lab:~/mm$ python transcribe.py media/call-1042.wav | cut -c1-160
Good morning, you're through to Marginalia Support. My name is Kyo. How can it help Hi Kau, I'm calling about Order M1042. It's a copy of Dom Kazmuro by Machado
ana@lab:~/mm$ tail -n 1 /var/log/labmm/requests.jsonl | python -c "import json, sys; r = json.loads(sys.stdin.read()); print({k: r[k] for k in (\"model\", \"file\", \"bytes\", \"duration\", \"segments\", \"seconds\")})"
{'model': 'lab-whisper-base', 'file': 'call-1042.wav', 'bytes': 1772316, 'duration': 55.38, 'segments': 11, 'seconds': 12.96}
```

**Esta transcrição é real, e não é da OpenAI.** O labmm responde à rota com o `lab-whisper-base`, que é o Whisper base rodando na máquina do laboratório, depois de cortar a gravação nos silêncios: o mesmo modelo e os mesmos erros da aula 7 (*Kyo*, *Kau*, *M1042*, *Dom Kazmuro*). O `whisper-1` da OpenAI é um Whisper maior e cometeria menos erros, e outros. O que é igual é a chamada: o SDK, o upload e os campos.

O registro do labmm diz o que ele recebeu: o nome do arquivo, **1.772.316 bytes**, 55,38 segundos de áudio, cortados em 11 segmentos, e quanto tempo tudo levou nesta máquina. Uma API hospedada informa menos, e um programa em produção deveria registrar as mesmas coisas por conta própria: arquivo, tamanho, duração e modelo são o que explica uma conta e um pedido lento um mês depois.

Os campos que valem configurar:

| campo | o que faz |
|---|---|
| `model` | `whisper-1`, `gpt-4o-transcribe`, `gpt-4o-mini-transcribe` na OpenAI; `whisper-base` ou `whisper-tiny` no servidor do curso |
| `file` | a gravação, num dos formatos aceitos (seção 06) |
| `language` | um código ISO 639-1 como `en` ou `pt`; a aula 7 mostrou por que defini-lo quando você sabe |
| `response_format` | o formato da resposta (seção 03) |
| `prompt` | um texto que o modelo trata como o que veio antes do áudio (seção 05) |
| `temperature` | 0 para as palavras mais prováveis; valores maiores deixam o decodificador pegar as menos prováveis |
