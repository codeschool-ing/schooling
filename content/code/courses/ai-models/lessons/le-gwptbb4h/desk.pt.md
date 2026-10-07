---
title: A mesa da ana, montada na sua máquina
version: 1
---

Toda aula deste curso acompanha uma pessoa. A **ana** cuida do atendimento da Lantern Books, uma
pequena livraria online, e precisa escolher o modelo que vai classificar os e-mails da loja. O
projeto dela é uma pasta chamada `desk`, e as aulas são o que ela digita ali. Você monta a mesma
pasta na sua máquina agora, e todo programa que o curso mostra vai para dentro dela.

## Uma pasta e um Python só dela

```
ana@desk:~$ mkdir -p desk/cases desk/prompts && cd desk
ana@desk:~/desk$ python3 -m venv .venv && . .venv/bin/activate
ana@desk:~/desk$ pip install -q openai==3.24.0 anthropic==1.11.0 ollama==0.6.3 google-genai==2.28.0 mistralai==3.0.0 huggingface_hub==2.1.1
ana@desk:~/desk$ pip list | grep -iE '^(openai|anthropic|ollama|google-genai|mistralai|huggingface)'
anthropic                          1.11.0
google-genai                       2.28.0
huggingface_hub                    2.1.1
mistralai                          3.0.0
ollama                             0.6.3
openai                             3.24.0
```

O `.venv` é um **ambiente virtual**: um Python com as próprias bibliotecas, dentro do projeto, para
que nada instalado aqui toque o resto do seu computador. O curso `python` monta um na aula 18; a
versão curta é que `. .venv/bin/activate` passa a usá-lo, e você roda essa linha de novo em cada
terminal novo antes de trabalhar na mesa. No Windows, a linha é `.venv\Scripts\activate`.

O `-q` deixa o `pip` calado, então nenhuma saída é sucesso, e o `pip list` mostra o que chegou. As
seis bibliotecas são as oficiais de cada provedor que o curso alcança, nas versões em que todas as
transcrições foram feitas. Instale essas versões, não as mais novas: uma biblioteca mais nova quase
sempre funciona e de vez em quando imprime outra coisa, e aí a aula e a sua tela discordam sem
motivo aparente.

## Para onde vão as requisições: o `desk.env`

A maioria dos programas do curso cria o cliente sem argumentos, `OpenAI()` ou `Anthropic()`, e a
biblioteca então lê duas configurações do ambiente: o endereço para onde mandar e a chave que vai
junto. O `desk.env` aponta as duas bibliotecas para o Ollama, no seu próprio computador:

```sh
# Where the SDKs send their requests: Ollama, on this computer.
# The keys are placeholders; the libraries refuse to start without one, and Ollama ignores it.
export OPENAI_BASE_URL=http://127.0.0.1:11434/v1
export OPENAI_API_KEY=ollama
export ANTHROPIC_BASE_URL=http://127.0.0.1:11434
export ANTHROPIC_API_KEY=ollama
```

Salve-o como `~/desk/desk.env` e carregue-o com `. ./desk.env`, no mesmo terminal, depois da linha
do activate. **O Ollama responde no formato da OpenAI e no da Anthropic**, e é por isso que as
mesmas duas bibliotecas que um cliente pagante usa funcionam aqui sem mudança. Com uma chave paga
sua, é este arquivo que muda, para o endereço do provedor e a sua chave, e cada programa passa a dar
o nome do modelo do provedor no lugar de `llama3.2:3b`.

## Os dois prompts

O primeiro trabalho da ana é a classificação: cada e-mail recebe um de cinco rótulos, para chegar à
pessoa certa. O `prompts/triage.txt`:

```
You sort the e-mail of Lantern Books, an online bookshop.
Answer with exactly one label and nothing else:
order-status, refund, address-change, product-question, other.
```

O segundo é tirar o número do pedido de um e-mail, para a resposta poder consultá-lo. O
`prompts/extract.txt`:

```
Read the customer's e-mail and answer with JSON only, in this shape:
{"order": "LB-12345"}
Use null for "order" when the e-mail names no order.
```

## Os quarenta casos

Quarenta e-mails da caixa de entrada da loja, sem nomes nem endereços, cada um com o rótulo que uma
pessoa deu e o número de pedido que ele cita, ou `null`. A aula 5 é sobre por que eles são escritos
e como usá-los; toda aula antes dela pega um ou dois emprestados. Salve-os como
`cases/triage.jsonl`, um e-mail por linha:

```json
{"id": "c01", "text": "Hi, I ordered two books on Monday (order LB-20417) and the tracking page still says 'preparing'. When will it ship?", "label": "order-status", "order": "LB-20417"}
{"id": "c02", "text": "The copy of 'The Salt Road' I received has twenty pages printed upside down. I'd like my money back, please. Order LB-20388.", "label": "refund", "order": "LB-20388"}
{"id": "c03", "text": "I moved last week. Can you send order LB-20452 to Rua das Flores 120, apt 31 instead of my old address?", "label": "address-change", "order": "LB-20452"}
{"id": "c04", "text": "Is the hardback edition of 'Nine Lighthouses' the same translation as the paperback?", "label": "product-question", "order": null}
{"id": "c05", "text": "Do you have a physical shop I can visit in Curitiba?", "label": "other", "order": null}
{"id": "c06", "text": "Order LB-20501 was marked delivered yesterday but nothing arrived. The doorman says no parcel came.", "label": "order-status", "order": "LB-20501"}
{"id": "c07", "text": "I cancelled LB-20399 within an hour of placing it and I was still charged. Please refund the charge.", "label": "refund", "order": "LB-20399"}
{"id": "c08", "text": "Please change the delivery address on LB-20460: the building number is 48, not 84.", "label": "address-change", "order": "LB-20460"}
{"id": "c09", "text": "Does the illustrated edition of 'Small Hours' come with the fold-out map?", "label": "product-question", "order": null}
{"id": "c10", "text": "Can I get an invoice with my company's tax number for order LB-20377?", "label": "other", "order": "LB-20377"}
{"id": "c11", "text": "It has been twelve days since I ordered (LB-20329). Is something wrong?", "label": "order-status", "order": "LB-20329"}
{"id": "c12", "text": "The book arrived soaked from the rain and the cover is ruined. I don't want a replacement, just the refund. LB-20415", "label": "refund", "order": "LB-20415"}
{"id": "c13", "text": "My order LB-20470 is going to my office but I'm on holiday from tomorrow. Could it go to my home address instead? Rua Aurora 9.", "label": "address-change", "order": "LB-20470"}
{"id": "c14", "text": "How many pages does 'The Quiet Engineer' have? The listing doesn't say.", "label": "product-question", "order": null}
{"id": "c15", "text": "I'd like to unsubscribe from your newsletter.", "label": "other", "order": null}
{"id": "c16", "text": "Hello, where is my parcel? LB-20488", "label": "order-status", "order": "LB-20488"}
{"id": "c17", "text": "I returned order LB-20301 three weeks ago and haven't seen the money. The return was accepted on the 2nd.", "label": "refund", "order": "LB-20301"}
{"id": "c18", "text": "I typed my postcode wrong on LB-20493. It should be 80010-000. Can you fix it before it ships?", "label": "address-change", "order": "LB-20493"}
{"id": "c19", "text": "Is 'Winter Orchard' suitable for a ten-year-old reader?", "label": "product-question", "order": null}
{"id": "c20", "text": "Your courier left a card saying they will try again tomorrow, but I won't be home. Order LB-20466. Can they leave it with a neighbour?", "label": "order-status", "order": "LB-20466"}
{"id": "c21", "text": "I was charged twice for LB-20440. One of the charges needs to go back to my card.", "label": "refund", "order": "LB-20440"}
{"id": "c22", "text": "Can I collect LB-20481 from the warehouse instead of having it delivered?", "label": "address-change", "order": "LB-20481"}
{"id": "c23", "text": "Will 'The Salt Road' be published in Portuguese?", "label": "product-question", "order": null}
{"id": "c24", "text": "I'm a teacher and would like to order thirty copies. Do you give discounts to schools?", "label": "other", "order": null}
{"id": "c25", "text": "The tracking number you sent for LB-20455 doesn't work on the courier's site.", "label": "order-status", "order": "LB-20455"}
{"id": "c26", "text": "I ordered the hardback but you sent the paperback (LB-20431). I'll keep it if you refund the difference.", "label": "refund", "order": "LB-20431"}
{"id": "c27", "text": "Please deliver LB-20497 to the reception desk of my building rather than to my door.", "label": "address-change", "order": "LB-20497"}
{"id": "c28", "text": "Are the e-book and the printed book sold together, or separately?", "label": "product-question", "order": null}
{"id": "c29", "text": "I forgot my password and the reset email never comes.", "label": "other", "order": null}
{"id": "c30", "text": "Order LB-20412 shows as shipped, but the courier says they have not received it from you.", "label": "order-status", "order": "LB-20412"}
{"id": "c31", "text": "The gift voucher I bought (LB-20366) was never sent to my friend, and her birthday has passed. I'd rather have the money back.", "label": "refund", "order": "LB-20366"}
{"id": "c32", "text": "Could you add the apartment number 1204 to LB-20478? I left it out.", "label": "address-change", "order": "LB-20478"}
{"id": "c33", "text": "Which edition of 'Nine Lighthouses' has the larger print?", "label": "product-question", "order": null}
{"id": "c34", "text": "I want to complain about the courier, who was rude to my mother.", "label": "other", "order": null}
{"id": "c35", "text": "Has LB-20490 left the warehouse yet? I need it by Friday.", "label": "order-status", "order": "LB-20490"}
{"id": "c36", "text": "The second volume in LB-20422 is missing. Please refund it, I found it elsewhere.", "label": "refund", "order": "LB-20422"}
{"id": "c37", "text": "I'm moving next month. Is it possible to change the address on my standing order for the quarterly box?", "label": "address-change", "order": null}
{"id": "c38", "text": "Do you ship to Portugal, and how long does it take?", "label": "product-question", "order": null}
{"id": "c39", "text": "Please delete my account and everything you hold about me.", "label": "other", "order": null}
{"id": "c40", "text": "The parcel for LB-20474 came back to you as undeliverable. What happens now?", "label": "order-status", "order": "LB-20474"}
```

## Verifique se tudo responde

O `check.py` manda o primeiro caso para o modelo, com o prompt de classificação, pela biblioteca da
OpenAI e pelo `desk.env`:

```python
import json

from openai import OpenAI

client = OpenAI()  # the address and the key come from desk.env
prompt = open("prompts/triage.txt").read()
case = json.loads(open("cases/triage.jsonl").readline())

r = client.chat.completions.create(model="llama3.2:3b", temperature=0, messages=[
    {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
print(case["id"], r.model, r.choices[0].message.content)
```

```
ana@desk:~/desk$ wc -l cases/triage.jsonl
40 cases/triage.jsonl
ana@desk:~/desk$ python check.py
c01 llama3.2:3b order-status
```

Uma linha de volta quer dizer que cada peça está no lugar: o servidor, o modelo, o ambiente virtual,
os dois arquivos e o endereço no `desk.env`. Se veio outra coisa, a próxima seção é onde ela está.
