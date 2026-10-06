---
title: Cinco formatos para uma transcrição
version: 1
---

O mesmo áudio pode voltar em cinco formatos, e escolher o certo poupa escrever um conversor.

**`text`**: só as palavras. Aqui, o recado em português, com o idioma deixado para o modelo:

```
ana@lab:~/mm$ python transcribe.py media/voicemail-pt.wav text
Oi, aqui é o Rafael Piente da Maginalia, sou ligando sobre o pedido em 2002-1987, um exemplar de memórias postmas de brassculpas que chegou com a capa amassada. Vocês podem me ligar de volta no fim da tarde? Obrigado.
```

**`verbose_json`**: as palavras, o idioma detectado, a duração e os **segmentos**, cada um com início e fim em segundos:

```python
"""verbose_json: the text, the language, the length, and every segment with its times."""
from openai import OpenAI

client = OpenAI()
with open("media/call-1042.wav", "rb") as audio:
    result = client.audio.transcriptions.create(model="lab-whisper-base", file=audio,
                                                response_format="verbose_json")
print(f"language {result.language}, {result.duration} s, {len(result.segments)} segments")
for s in result.segments[:4]:
    print(f"  {s.start:6.2f} {s.end:6.2f}  {s.text}")
```

```
ana@lab:~/mm$ python verbose.py
language english, 55.38 s, 11 segments
    0.26   4.36  Good morning, you're through to Marginalia Support. My name is Kyo.
    4.58   5.32  How can it help
    6.05  14.31  Hi Kau, I'm calling about Order M1042. It's a copy of Dom Kazmuro by Machado Desiss and it arrived on 24 September.
   15.01  16.39  Let me pull that up.
```

**`srt`** e **`vtt`**: os mesmos segmentos como arquivos de legenda, prontos para pôr ao lado de um vídeo:

```
ana@lab:~/mm$ python transcribe.py media/call-1042.wav srt | head -8
1
00:00:00,260 --> 00:00:04,360
Good morning, you're through to Marginalia Support. My name is Kyo.

2
00:00:04,580 --> 00:00:05,320
How can it help
```

```
ana@lab:~/mm$ python transcribe.py media/call-1042.wav vtt | head -8
WEBVTT

00:00:00.260 --> 00:00:04.360
Good morning, you're through to Marginalia Support. My name is Kyo.

00:00:04.580 --> 00:00:05.320
How can it help
```

Os dois formatos de legenda carregam a mesma informação e diferem numa pontuação que importa ao software que os lê. O **SRT** numera cada trecho e escreve os milissegundos depois de uma vírgula (`00:00:04,360`). O **WebVTT** começa com a linha `WEBVTT`, escreve os milissegundos depois de um ponto (`00:00:04.360`), não precisa de números e é o formato que os navegadores leem num elemento `<track>`. A aula 14 monta legendas a partir deles, e acha os problemas que ainda têm: um segmento de oito segundos é longo demais para ler como uma legenda, e um trecho de três palavras (*How can it help*) separado da frase é difícil de acompanhar.

| formato | use para |
|---|---|
| `json` (o padrão) | o texto, num programa |
| `text` | o texto, num script de shell ou arquivo |
| `verbose_json` | tudo o que precisa de tempos ou do idioma detectado |
| `srt`, `vtt` | legendas; `vtt` para a web |

A documentação da OpenAI não lista `srt`, `vtt` nem `verbose_json` para os modelos `gpt-4o-transcribe` mais novos, e vale conferir isso antes de trocar um processo de legendas para eles.
