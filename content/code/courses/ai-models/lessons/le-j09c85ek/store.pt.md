---
title: Trinta dias, a não ser que você diga o contrário
version: 1
---

Uma conversa guardada do lado da OpenAI é uma conversa **armazenada** do lado da OpenAI, e a
documentação da biblioteca diz por quanto tempo:

```
ana@desk:~/desk$ python lab/doc.py store
store: Whether to store the generated model response for later retrieval via API.
    Defaults to true when omitted. If set to true, response data will be stored for
    at least 30 days, subject to the
    [data retention exceptions](https://developers.openai.com/api/docs/guides/your-data#v1responses).
```

Armazenar é o padrão. Toda resposta que a ana cria sem dizer o contrário, com o e-mail junto, fica
guardada por pelo menos trinta dias e pode ser buscada de novo por quem tiver a chave e o id. Para a
Lantern Books essa é a pergunta da seção 07 da aula 2 com uma resposta nova: o e-mail vai para a
OpenAI, e fica. O `lab/forget.py` exercita as duas saídas:

```python
import json

from openai import OpenAI, NotFoundError, BadRequestError

client = OpenAI()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

kept = client.responses.create(model="standin-small", instructions=prompt, input=case["text"])
print("stored:   ", client.responses.retrieve(kept.id).output_text)
client.responses.delete(kept.id)
try:
    client.responses.retrieve(kept.id)
except NotFoundError as e:
    print("deleted:  ", e.status_code, e.body["message"])

once = client.responses.create(model="standin-small", instructions=prompt, input=case["text"], store=False)
try:
    client.responses.create(model="standin-small", previous_response_id=once.id, input="Thanks.")
except BadRequestError as e:
    print("store=False:", e.status_code, e.body["message"])
```

```
ana@desk:~/desk$ python lab/forget.py
stored:    other
deleted:   404 Response with id 'resp_lab_0006' not found.
store=False: 400 Previous response with id 'resp_lab_0010' not found.
```

**Apague depois de usar**, e a resposta some da API: o `retrieve` seguinte é um 404. **Ou nunca
armazene**: `store=False`, e não há nada para buscar nem de onde encadear, como a última linha
mostra. As duas não prometem a mesma coisa. Apagar remove o que a API devolve; o que o provedor
guarda para fins próprios é regido pela política de dados dele,
para a qual o link da docstring aponta e que esta máquina não conseguiu ler. Esse é o documento a ler
antes de o e-mail de clientes ir a qualquer lugar.

Para a classificação da ana a escolha é fácil: toda requisição é independente, então `store=False`
não custa nada. Para uma conversa que ela queira guardar, a alternativa é o hábito da Chat
Completions: guardar o histórico no próprio banco de dados e mandá-lo toda vez.
