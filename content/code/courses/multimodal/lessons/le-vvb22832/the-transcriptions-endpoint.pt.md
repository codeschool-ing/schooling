---
title: O endpoint de transcrição
version: 1
---

A API de fala para texto da OpenAI é uma chamada: **envie um arquivo, diga um modelo, receba texto de volta**. O arquivo vai como upload de formulário multipart, não como JSON, e o SDK esconde isso:

```python
"""Send a recording to the transcriptions endpoint and print what comes back."""
import sys

from openai import OpenAI

path = sys.argv[1]
fmt = sys.argv[2] if len(sys.argv) > 2 else "json"
client = OpenAI()
with open(path, "rb") as audio:
    result = client.audio.transcriptions.create(model="lab-whisper-base", file=audio, response_format=fmt)
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
| `model` | `whisper-1`, `gpt-4o-transcribe`, `gpt-4o-mini-transcribe` na OpenAI; `lab-whisper-base` ou `lab-whisper-tiny` aqui |
| `file` | a gravação, num dos formatos aceitos (seção 06) |
| `language` | um código ISO 639-1 como `en` ou `pt`; a aula 7 mostrou por que defini-lo quando você sabe |
| `response_format` | o formato da resposta (seção 03) |
| `prompt` | um texto que o modelo trata como o que veio antes do áudio (seção 05) |
| `temperature` | 0 para as palavras mais prováveis; valores maiores deixam o decodificador pegar as menos prováveis |
