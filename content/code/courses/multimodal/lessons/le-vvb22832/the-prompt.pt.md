---
title: O campo prompt, e por que aqui ele não faz nada
version: 1
---

O Whisper decodifica uma gravação um token por vez, e cada token é previsto a partir do som **e do texto que veio antes**. O campo `prompt` da API deixa você fornecer esse texto anterior. O modelo o trata como se tivesse acabado de ser dito, então as palavras e grafias dele ficam mais prováveis no que vem a seguir.

É a correção hospedada para o problema da aula 7: dê ao prompt o nome da loja, o nome do atendente, o formato do número de pedido e o título, e o modelo fica muito mais propenso a escrever *Marginalia*, *Caio* e *Dom Casmurro*. A documentação da OpenAI descreve três usos: grafia de palavras incomuns, manter o estilo do pedaço anterior de uma gravação longa (as últimas palavras dele, passadas como prompt do pedaço seguinte), e definir pontuação e maiúsculas pelo exemplo. Para o `whisper-1` ela diz que só os últimos 224 tokens do prompt são considerados.

```python
"""The prompt parameter: text the model is told came before the audio."""
from openai import OpenAI

client = OpenAI()
with open("media/call-1042.wav", "rb") as audio:
    result = client.audio.transcriptions.create(
        model="lab-whisper-base", file=audio, language="en",
        prompt="Marginalia support. Caio. Order M-1042: Dom Casmurro, by Machado de Assis.")
print(result.text[:150])
```

```
ana@lab:~/mm$ python hint.py
Good morning, you're through to Marginalia Support. My name is Kyo. How can it help Hi Kau, I'm calling about Order M1042. It's a copy of Dom Kazmuro 
ana@lab:~/mm$ tail -n 1 /var/log/labmm/requests.jsonl | python -c "import json, sys; r = json.loads(sys.stdin.read()); print(r[\"prompt\"])"
Marginalia support. Caio. Order M-1042: Dom Casmurro, by Machado de Assis.
```

**A transcrição não mudou**: continua *Kyo*, *Kau* e *Dom Kazmuro*, com os nomes certos parados no prompt. Isso não é evidência sobre o prompt. **O labmm aceita o campo, registra e não o passa ao modelo**, porque a exportação ONNX do Whisper que este laboratório roda não tem como recebê-lo; o segundo comando mostra que ele chegou. No endpoint real é aqui que os erros da aula 7 seriam atacados primeiro, e o léxico da aula 7 é a alternativa que funciona com ou sem prompt.

Dois cuidados da mesma documentação, que vale saber antes de depender dele:

- **Um prompt é uma dica, não uma restrição.** O modelo ainda pode escrever outra coisa, então a conferência pelo léxico depois da transcrição continua.
- **Um prompt pode empurrar para o lado errado.** Um prompt em inglês empurra o modelo para o inglês, e uma lista longa de nomes sem relação pode fazer o modelo escrevê-los onde não foram ditos. Mantenha-o curto e fiel à gravação.
