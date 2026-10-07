---
title: Trinta dias, a não ser que você diga o contrário
version: 1
---

Uma conversa guardada do lado da OpenAI é uma conversa **armazenada** do lado da OpenAI, e a
documentação da biblioteca diz por quanto tempo:

```
ana@desk:~/desk$ python doc.py store
store: Whether to store the generated model response for later retrieval via API.
    Defaults to true when omitted. If set to true, response data will be stored for
    at least 30 days, subject to the
    [data retention exceptions](https://developers.openai.com/api/docs/guides/your-data#v1responses).
```

Armazenar é o padrão. Toda resposta que a ana cria sem dizer o contrário, com o e-mail junto, fica
guardada por pelo menos trinta dias e pode ser buscada de novo por quem tiver a chave e o id. Para a
Lantern Books essa é a pergunta da seção 07 da aula 2 com uma resposta nova: o e-mail vai para a
OpenAI, e fica. O `forget.py` exercita as duas saídas:

```python
import json

from openai import OpenAI, NotFoundError, BadRequestError

client = OpenAI()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

kept = client.responses.create(model="llama3.2:3b", instructions=prompt, input=case["text"])
print("stored:   ", client.responses.retrieve(kept.id).output_text)
client.responses.delete(kept.id)
try:
    client.responses.retrieve(kept.id)
except NotFoundError as e:
    print("deleted:  ", e.status_code, e.body["message"])

once = client.responses.create(model="llama3.2:3b", instructions=prompt, input=case["text"], store=False)
try:
    client.responses.create(model="llama3.2:3b", previous_response_id=once.id, input="Thanks.")
except BadRequestError as e:
    print("store=False:", e.status_code, e.body["message"])
```

```
ana@desk:~/desk$ python forget.py 2>&1 | tail -1
openai.NotFoundError: 404 page not found
ana@desk:~/desk$ python relay.py show --count 2
POST /v1/responses -> 200 llama3.2:3b
GET /v1/responses/resp_977775 -> 404 
```

Contra o Ollama o programa para no primeiro `retrieve`, e o relay mostra por quê: a resposta foi
criada, e o `GET` que a pede de volta é um 404. **O Ollama não guarda nada**, então não há o que
recuperar, apagar ou encadear, e um servidor local responde à pergunta desta seção do jeito mais
simples que existe. Na OpenAI, a docstring diz que os três passos do programa vão no sentido
contrário: a resposta é guardada e volta, **apagar depois de usar** a remove, e o `retrieve`
seguinte é um 404, e **nunca guardar**, `store=False`, não deixa nada para buscar nem para encadear.

As duas coisas não prometem o mesmo. Apagar remove o que a API devolve; o que o provedor guarda para
os próprios fins é regido pela política de dados dele, para onde o link da docstring aponta e que
esta máquina não conseguiu ler. Esse é o documento a ler antes de os e-mails de clientes irem para
qualquer lugar.

Para a classificação da ana a escolha é fácil: toda requisição é independente, então `store=False`
não custa nada. Para uma conversa que ela quer guardar, a alternativa é o hábito do Chat
Completions: guardar o histórico no próprio banco de dados e mandá-lo toda vez.
