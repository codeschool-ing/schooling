---
title: O formato em que o áudio viaja
version: 1
---

Uma voz produz números; o que chega a quem ouve é um arquivo ou um fluxo em algum formato, e o formato decide o tamanho e onde ele toca. A rota de fala do labmm, que roda a mesma voz Piper atrás do formato da API da OpenAI, oferece os formatos que a da OpenAI oferece. A mesma frase em cada um:

```python
"""One sentence from labmm's speech route in every format it offers, and what each one weighs."""
from openai import OpenAI

client = OpenAI()
TEXT = "Your order has shipped. It should arrive on Thursday."
for fmt in ("wav", "flac", "mp3", "aac", "opus"):
    audio = client.audio.speech.create(model="lab-tts-1", voice="lessac", input=TEXT, response_format=fmt)
    print(f"{fmt:5} {len(audio.content):7,} bytes")
```

```
ana@lab:~/mm$ python formats.py
wav   121,900 bytes
flac   66,655 bytes
mp3    22,589 bytes
aac    23,368 bytes
opus   10,974 bytes
```

| formato | o que é | tamanho aqui | use para |
|---|---|---|---|
| WAV | as amostras cruas, sem compressão | 121.900 bytes | processamento posterior; nunca para entrega |
| FLAC | as mesmas amostras, comprimidas sem perda | 66.655 bytes | guardar uma cópia mestra |
| MP3 | com perda, a 64 kbit/s aqui | 22.589 bytes | tudo o que precisa tocar em qualquer lugar |
| AAC | com perda, a 64 kbit/s aqui | 23.368 bytes | aparelhos da Apple, arquivos de vídeo |
| Opus | com perda, feito para fala, a 32 kbit/s aqui | 10.974 bytes | a web, sistemas de telefonia, chat de voz |

**O Opus tem um décimo do tamanho do WAV** e é o formato desenhado para fala em redes: todo navegador atual o toca, e ele foi feito para funcionar nas taxas baixas que chamadas usam. Numa linha telefônica o áudio é convertido mais uma vez na borda da rede de telefonia, para 8.000 amostras por segundo, que é como soava a gravação de telefone da aula 5.

Os tamanhos importam duas vezes: uma para cada resposta mandada a quem ligou, e outra na conta, já que alguns provedores cobram fala sintetizada por caractere de entrada e outros por segundo de áudio produzido. A aula 13 faz essa conta com preços reais.
