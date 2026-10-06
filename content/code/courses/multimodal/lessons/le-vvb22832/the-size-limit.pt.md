---
title: O limite de 25 MB, e gravações longas
version: 1
---

A OpenAI documenta um limite de **25 MB por arquivo enviado** para transcrição, e aceita uma lista de formatos: `flac`, `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `ogg`, `wav` e `webm`. O labmm aplica os dois. Meia hora da ligação do laboratório, feita juntando 32 cópias uma atrás da outra, mostra por que o limite importa na prática:

```python
"""An hour-long recording is too big to upload whole; cut it at silences and send the pieces."""
import subprocess
import sys

from openai import OpenAI, APIStatusError

LIMIT = 25 * 1024 * 1024
src = sys.argv[1]
size = int(subprocess.run(["stat", "-c", "%s", src], capture_output=True, text=True).stdout)
print(f"{src}: {size:,} bytes, the limit is {LIMIT:,}")
client = OpenAI()
try:
    with open(src, "rb") as audio:
        client.audio.transcriptions.create(model="lab-whisper-tiny", file=audio)
except APIStatusError as e:
    print(f"whole file: {e.status_code} {e.body['message'] if isinstance(e.body, dict) else e.body}")
```

```
ana@lab:~/mm$ for i in $(seq 32); do echo "file '$PWD/media/call-1042.wav'"; done > /tmp/list.txt && ffmpeg -nostdin -loglevel error -y -f concat -safe 0 -i /tmp/list.txt -c copy long.wav && ffprobe -v error -show_entries format=duration -of csv=p=0 long.wav
1772.272000
ana@lab:~/mm$ python long.py long.wav
long.wav: 56,712,782 bytes, the limit is 26,214,400
whole file: 413 Maximum content size limit (26214400) exceeded (56713055 bytes read)
ana@lab:~/mm$ ffmpeg -nostdin -loglevel error -y -i long.wav -ac 1 -ar 16000 -b:a 32k long.mp3 && stat -c "%s %n" long.mp3
7089633 long.mp3
```

**29,5 minutos de WAV a 16 kHz são 56,7 MB**, mais que o dobro do limite, e o upload é recusado com um 413 antes de qualquer áudio ser ouvido. O mesmo áudio em MP3 a 32 kbit/s tem 7,1 MB, abaixo do limite com folga. Então a primeira correção para um arquivo grande demais é a que a aula 6 mediu: **mande áudio comprimido, na taxa de amostragem que o modelo usa**. Fala a 16 kHz mono não perde nada de que um transcritor precise num MP3 ou Opus a 32 kbit/s.

A segunda correção cobre gravações longas demais mesmo comprimidas (uma reunião de três horas), e é melhor que um upload único grande de qualquer forma: **corte nos silêncios, mande os pedaços e junte os tempos de novo**.

```schooling-example
{
  "language": "python",
  "file": "pieces.py",
  "parts": [
    {
      "code": "\"\"\"Transcribe a long recording in pieces cut at silences, and put the times back together.\"\"\"\nimport subprocess\nimport sys\n\nfrom openai import OpenAI\n\nimport mmlab\n\n"
    },
    {
      "code": "src, LIMIT = sys.argv[1], 600.0                    # pieces of at most ten minutes\nsamples = mmlab.read_audio(src)\ncuts, start, last = [], 0.0, 0.0\nfor s, e in mmlab.speech_segments(samples):\n    if e - start > LIMIT and last > start:\n        cuts.append((start, (last + s) / 2))\n        start = (last + s) / 2\n    last = e\ncuts.append((start, len(samples) / mmlab.RATE))\n\n",
      "note": "**Planeje os cortes antes de mandar qualquer coisa**: pedaços de no máximo dez minutos, cada um terminando no meio de um silêncio que o detector de fala achou, como o `chunks.py` da aula 5 fez para 30 segundos."
    },
    {
      "code": "client = OpenAI()\nsegments = []\n",
      "note": "**Uma lista para os segmentos do arquivo inteiro.**"
    },
    {
      "code": "for i, (a, b) in enumerate(cuts):\n    piece = f\"/tmp/piece-{i}.mp3\"\n    subprocess.run([\"ffmpeg\", \"-nostdin\", \"-loglevel\", \"error\", \"-y\", \"-ss\", str(a), \"-to\", str(b), \"-i\", src,\n                    \"-ac\", \"1\", \"-ar\", \"16000\", \"-b:a\", \"32k\", piece], check=True)\n    with open(piece, \"rb\") as audio:\n        r = client.audio.transcriptions.create(model=\"lab-whisper-tiny\", file=audio, language=\"en\",\n                                               response_format=\"verbose_json\")\n",
      "note": "**Cada pedaço é cortado pelo ffmpeg e comprimido em MP3 a 32 kbit/s**, e é por isso que um pedaço de dez minutos pesa uns 2,4 MB em vez de 19, e é enviado sozinho como `verbose_json`, para voltar com os tempos dos segmentos."
    },
    {
      "code": "    segments += [(a + s.start, a + s.end, s.text) for s in r.segments]   # the piece's times, moved to the file's\n",
      "note": "**A linha fácil de esquecer.** Os segmentos de um pedaço são contados a partir do início do pedaço; somar o início do próprio pedaço os devolve ao relógio do arquivo."
    },
    {
      "code": "    size = subprocess.run([\"stat\", \"-c\", \"%s\", piece], capture_output=True, text=True).stdout.strip()\n    print(f\"piece {i}: {a:7.1f} to {b:7.1f} s, {int(size):,} bytes, {len(r.segments)} segments\")\nprint(f\"{len(segments)} segments; the last: {segments[-1][0]:.1f}-{segments[-1][1]:.1f} s {segments[-1][2]!r}\")",
      "note": "**O que foi enviado e o que voltou**, pedaço por pedaço, e o último segmento de todos como conferência de que os tempos chegam ao fim do arquivo."
    }
  ]
}
```

```
ana@lab:~/mm$ python pieces.py long.wav
piece 0:     0.0 to   595.5 s, 2,382,417 bytes, 120 segments
piece 1:   595.5 to  1192.7 s, 2,389,329 bytes, 122 segments
piece 2:  1192.7 to  1772.3 s, 2,319,057 bytes, 116 segments
358 segments; the last: 1769.1-1772.2 s 'Thank you for calling marginalia. Have a good day.'
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma gravação de 1.772 segundos desenhada como uma barra longa, cortada em silêncios em três pedaços: de 0 a 595,5 segundos, de 595,5 a 1192,7, e de 1192,7 a 1772,3. Cada pedaço é enviado sozinho e seus segmentos voltam contados a partir de zero. Uma seta mostra um segmento em 3,0 segundos no pedaço 2 sendo movido para 1195,7 segundos no arquivo, somando o início do pedaço.\"><defs><marker id=\"l10pcs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"30\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">long.wav, 56,7 MB: acima do limite de 25 MB</text><rect x=\"30.0\" y=\"34\" width=\"217.76268126163743\" height=\"30\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"140.88134063081873\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedaço 0</text><text x=\"30.0\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><rect x=\"251.76268126163743\" y=\"34\" width=\"218.39575692602833\" height=\"30\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"362.9605597246516\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedaço 1</text><text x=\"251.76268126163743\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">595.5</text><rect x=\"474.15843818766575\" y=\"34\" width=\"211.84156181233425\" height=\"30\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"582.0792190938329\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedaço 2</text><text x=\"474.15843818766575\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1192.7</text><text x=\"690.0\" y=\"78\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1772.3</text><rect x=\"474.15843818766575\" y=\"120\" width=\"200\" height=\"30\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"482.15843818766575\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pedaço 2, contado do 0</text><text x=\"466.15843818766575\" y=\"135\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">3.0 s</text><line x1=\"434.15843818766575\" y1=\"120\" x2=\"475.2756305365909\" y2=\"68\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l10pcs-ah-amber)\"></line><text x=\"30\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">O tempo de um segmento no arquivo = o início do pedaço + o tempo dele no pedaço: 1192,7 + 3,0 = 1195,7 s.</text></svg>", "caption": "Corte onde ninguém fala, mande cada pedaço sozinho, e devolva cada tempo ao relógio do arquivo."}
```

Três pedaços de uns dez minutos, cada um com cerca de 2,4 MB, 358 segmentos ao todo, e o último segmento termina em 1.772,2 segundos, a duração do arquivo. **A linha do deslocamento é a fácil de esquecer**, e esquecê-la produz legendas que começam todas nos primeiros dez minutos.

Pedaços também deixam o processo mais robusto: um pedido que falha custa um pedaço, não a gravação inteira, e os pedaços podem ser enviados ao mesmo tempo. O que eles perdem é o contexto atravessando um corte, que é o que o uso de "pedaço anterior" do campo `prompt` existe para recuperar, num endpoint que o respeite.
