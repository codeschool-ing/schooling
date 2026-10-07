---
title: O endpoint de tradução
version: 1
---

O Whisper foi treinado para transcrever fala em muitas línguas e para **traduzi-la para o inglês**, e a API expõe o segundo trabalho como endpoint próprio: `audio.translations`. Ele recebe uma gravação em qualquer língua que o Whisper conhece e devolve texto em inglês, num passo só.

```python
"""The Portuguese voicemail, transcribed as it was said and translated into English."""
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8700/v1")   # audio_server.py, on this machine
with open("media/voicemail-pt.wav", "rb") as audio:
    said = client.audio.transcriptions.create(model="whisper-base", file=audio)
with open("media/voicemail-pt.wav", "rb") as audio:
    english = client.audio.translations.create(model="whisper-base", file=audio)
print("transcribed:", said.text)
print("translated: ", english.text)
```

```
ana@lab:~/mm$ python translate.py
transcribed: Oi, aqui é o Rafael Piente da Maginalia, sou ligando sobre o pedido em 2002-1987, um exemplar de memórias postmas de brassculpas que chegou com a capa amassada. Vocês podem me ligar de volta no fim da tarde? Obrigado.
translated:  Hi, here is Rafael Pienta from Marginalia, I'm calling on the request in my 2017 an exemplary memory of brass cubes that arrived with the mass cover. You can come back in the end of the afternoon, thank you.
```

As duas linhas são do Whisper base, rodado pelo servidor do curso. A tradução leva os erros da transcrição para o inglês e acrescenta os seus: *pedido M-2087* virou *the request in my 2017*, e *Memórias Póstumas de Brás Cubas* virou *an exemplary memory of brass cubes*. O sentido do recado (um cliente, uma capa danificada, por favor ligue de volta à tarde) sobrevive; o número do pedido e o título, que são o que a loja precisa, não.

Três coisas a saber sobre ele:

- **Ele só traduz para o inglês.** Para qualquer outro destino, transcreva na língua original e traduza o texto com um modelo de linguagem, o que também deixa conferir a transcrição antes.
- **É o mesmo comportamento que a aula 7 encontrou por acidente**, quando o Whisper foi avisado de que uma gravação em português era inglês e a traduziu sem dizer. Aqui é pedido; lá foi um erro.
- **Traduza o texto, não o áudio, quando nomes e números importam.** Um processo em dois passos (transcrever em português, corrigir nomes com o léxico da loja como na aula 7, depois traduzir) mantém *Brás Cubas* como nome. O endpoint de um passo não dá a um modelo que ouviu mal um nome nenhuma chance de ser corrigido antes de traduzi-lo em outra coisa.
